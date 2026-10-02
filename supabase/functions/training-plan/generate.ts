import Anthropic from "@anthropic-ai/sdk";
import type { z } from "zod";

import { SYSTEM_PROMPT } from "./prompt.ts";

export const MODEL = "claude-opus-5-5";

/** The one SDK call this module makes; swapped for a fake in tests. */
export type CreateMessage = (
  params: Anthropic.Beta.Messages.MessageCreateParamsNonStreaming,
) => Promise<Anthropic.Beta.Messages.BetaMessage>;

export function anthropicCreateMessage(apiKey: string): CreateMessage {
  // Stay inside the edge function's 150 s wall clock; one retry at most.
  const client = new Anthropic({ apiKey, timeout: 110_000, maxRetries: 1 });
  return (params) => client.beta.messages.create(params);
}

export class GenerationError extends Error {
  constructor(
    message: string,
    readonly kind: "refusal" | "truncated" | "invalid" | "rules",
    readonly details: string[] = [],
  ) {
    super(message);
  }
}

/**
 * Ask Claude for JSON matching [jsonSchema], parse it with [schema], and check
 * it with [check]. If the rules are broken and there is time left before
 * [deadlineMs], send the violations back once and ask for a corrected version.
 */
export async function generate<T>(opts: {
  create: CreateMessage;
  userText: string;
  jsonSchema: Record<string, unknown>;
  schema: z.ZodType<T>;
  check: (value: T) => string[];
  deadlineMs: number;
  now?: () => number;
}): Promise<T> {
  const now = opts.now ?? Date.now;
  const messages: Anthropic.Beta.Messages.BetaMessageParam[] = [
    { role: "user", content: opts.userText },
  ];
  let lastErrors: string[] = [];

  for (let attempt = 0; attempt < 2; attempt++) {
    const started = now();
    const response = await opts.create({
      model: MODEL,
      max_tokens: 16000,
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      system: SYSTEM_PROMPT,
      output_config: {
        effort: "medium",
        format: { type: "json_schema", schema: opts.jsonSchema },
      },
      messages,
    });
    console.log(
      JSON.stringify({
        event: "claude_call",
        attempt,
        model: response.model,
        stop_reason: response.stop_reason,
        input_tokens: response.usage.input_tokens,
        output_tokens: response.usage.output_tokens,
        ms: now() - started,
      }),
    );

    if (response.stop_reason === "refusal") {
      throw new GenerationError("model declined the request", "refusal");
    }
    if (response.stop_reason === "max_tokens") {
      throw new GenerationError("plan was cut off", "truncated");
    }
    const text = response.content
      .filter((b): b is Anthropic.Beta.Messages.BetaTextBlock => b.type === "text")
      .map((b) => b.text)
      .join("");

    let parsed: T;
    try {
      parsed = opts.schema.parse(JSON.parse(text));
    } catch (e) {
      throw new GenerationError("plan did not match the expected format", "invalid", [String(e)]);
    }

    lastErrors = opts.check(parsed);
    if (lastErrors.length === 0) return parsed;

    // Retry only if a second call can finish before the deadline.
    const elapsed = now() - started;
    if (attempt === 0 && now() + elapsed * 1.2 < opts.deadlineMs) {
      messages.push(
        { role: "assistant", content: response.content },
        {
          role: "user",
          content: `This plan breaks these rules:\n- ${lastErrors.join("\n- ")}\n\nReturn the complete corrected JSON, fixing every point and keeping everything else.`,
        },
      );
      continue;
    }
    break;
  }
  throw new GenerationError("plan broke the safety rules", "rules", lastErrors);
}
