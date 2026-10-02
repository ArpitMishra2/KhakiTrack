import Anthropic from "@anthropic-ai/sdk";
import type { z } from "zod";

import { SYSTEM_PROMPT } from "./prompt.ts";

// ---------------------------------------------------------------------------
// Providers. The plan logic only needs "give me JSON matching this schema",
// so each provider is one function. Groq is used in development; Claude is
// kept so switching back is a configuration change (see index.ts).
// ---------------------------------------------------------------------------

export interface JsonRequest {
  system: string;
  messages: Array<{ role: "user" | "assistant"; content: string }>;
  schemaName: string;
  jsonSchema: Record<string, unknown>;
}

export interface JsonReply {
  text: string;
  stop: "end" | "truncated" | "refusal";
  model: string;
  inputTokens: number;
  outputTokens: number;
}

export type JsonModel = (req: JsonRequest) => Promise<JsonReply>;

export const GROQ_MODEL = "openai/gpt-oss-120b";
export const CLAUDE_MODEL = "claude-opus-5-5";

/** Groq, OpenAI-compatible chat completions with strict JSON schema output. */
export function groqModel(
  apiKey: string,
  fetchFn: typeof fetch = fetch,
  sleep: (ms: number) => Promise<void> = (ms) => new Promise((r) => setTimeout(r, ms)),
): JsonModel {
  const call = (req: JsonRequest) =>
    fetchFn("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: GROQ_MODEL,
        messages: [{ role: "system", content: req.system }, ...req.messages],
        response_format: {
          type: "json_schema",
          json_schema: { name: req.schemaName, strict: true, schema: req.jsonSchema },
        },
        reasoning_effort: "medium",
        max_completion_tokens: 16000,
      }),
      signal: AbortSignal.timeout(110_000),
    });
  return async (req) => {
    let res = await call(req);
    // Free tier: tokens-per-minute limit shared by all users. Wait once if
    // Groq says it will be free again soon, otherwise report "busy".
    if (res.status === 429) {
      const wait = Number(res.headers.get("retry-after") ?? "60");
      if (wait <= 30) {
        await sleep(wait * 1000 + 500);
        res = await call(req);
      }
      if (res.status === 429) throw new GenerationError("groq rate limit", "busy");
    }
    if (!res.ok) {
      throw new GenerationError(`groq ${res.status}: ${(await res.text()).slice(0, 300)}`, "provider");
    }
    const data = await res.json();
    const choice = data.choices?.[0];
    return {
      text: choice?.message?.content ?? "",
      stop: choice?.finish_reason === "length"
        ? "truncated"
        : choice?.message?.refusal
        ? "refusal"
        : "end",
      model: data.model ?? GROQ_MODEL,
      inputTokens: data.usage?.prompt_tokens ?? 0,
      outputTokens: data.usage?.completion_tokens ?? 0,
    };
  };
}

/** The one Anthropic SDK call this module makes; swapped for a fake in tests. */
export type CreateMessage = (
  params: Anthropic.Beta.Messages.MessageCreateParamsNonStreaming,
) => Promise<Anthropic.Beta.Messages.BetaMessage>;

/** Claude with structured JSON output and server-side fallbacks. */
export function claudeModel(create: CreateMessage): JsonModel {
  return async (req) => {
    const response = await create({
      model: CLAUDE_MODEL,
      max_tokens: 16000,
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      system: req.system,
      output_config: {
        effort: "medium",
        format: { type: "json_schema", schema: req.jsonSchema },
      },
      messages: req.messages,
    });
    return {
      text: response.content
        .filter((b): b is Anthropic.Beta.Messages.BetaTextBlock => b.type === "text")
        .map((b) => b.text)
        .join(""),
      stop: response.stop_reason === "refusal"
        ? "refusal"
        : response.stop_reason === "max_tokens"
        ? "truncated"
        : "end",
      model: response.model,
      inputTokens: response.usage.input_tokens,
      outputTokens: response.usage.output_tokens,
    };
  };
}

export function anthropicCreateMessage(apiKey: string): CreateMessage {
  // Stay inside the edge function's 150 s wall clock; one retry at most.
  const client = new Anthropic({ apiKey, timeout: 110_000, maxRetries: 1 });
  return (params) => client.beta.messages.create(params);
}

export class GenerationError extends Error {
  constructor(
    message: string,
    readonly kind: "refusal" | "truncated" | "invalid" | "rules" | "provider" | "busy",
    readonly details: string[] = [],
  ) {
    super(message);
  }
}

/**
 * Ask the model for JSON matching [jsonSchema], parse it with [schema], and
 * check it with [check]. If the rules are broken and there is time left
 * before [deadlineMs], send the violations back once for a corrected version.
 * Returns the value and the model that produced it.
 */
export async function generate<T>(opts: {
  model: JsonModel;
  userText: string;
  schemaName: string;
  jsonSchema: Record<string, unknown>;
  schema: z.ZodType<T>;
  check: (value: T) => string[];
  deadlineMs: number;
  now?: () => number;
}): Promise<{ value: T; model: string }> {
  const now = opts.now ?? Date.now;
  const messages: JsonRequest["messages"] = [{ role: "user", content: opts.userText }];
  let lastErrors: string[] = [];

  for (let attempt = 0; attempt < 2; attempt++) {
    const started = now();
    const reply = await opts.model({
      system: SYSTEM_PROMPT,
      messages,
      schemaName: opts.schemaName,
      jsonSchema: opts.jsonSchema,
    });
    console.log(JSON.stringify({
      event: "model_call",
      attempt,
      model: reply.model,
      stop: reply.stop,
      input_tokens: reply.inputTokens,
      output_tokens: reply.outputTokens,
      ms: now() - started,
    }));

    if (reply.stop === "refusal") throw new GenerationError("model declined the request", "refusal");
    if (reply.stop === "truncated") throw new GenerationError("plan was cut off", "truncated");

    let parsed: T;
    try {
      parsed = opts.schema.parse(JSON.parse(reply.text));
    } catch (e) {
      throw new GenerationError("plan did not match the expected format", "invalid", [String(e)]);
    }

    lastErrors = opts.check(parsed);
    if (lastErrors.length === 0) return { value: parsed, model: reply.model };

    // Retry only if a second call can finish before the deadline.
    const elapsed = now() - started;
    if (attempt === 0 && now() + elapsed * 1.2 < opts.deadlineMs) {
      messages.push(
        { role: "assistant", content: reply.text },
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
