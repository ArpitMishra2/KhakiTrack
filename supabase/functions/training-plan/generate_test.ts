import { assert, assertEquals, assertRejects } from "@std/assert";
import type Anthropic from "@anthropic-ai/sdk";

import { type CreateMessage, generate, GenerationError, MODEL } from "./generate.ts";
import { outlineRequest } from "./prompt.ts";
import { PlanOutline, planOutlineJsonSchema } from "./types.ts";
import { validateOutline } from "./validate.ts";
import { beginnerAnswers, fitAnswers, goodOutline } from "./validate_test.ts";

function message(
  text: string,
  stop: Anthropic.Beta.Messages.BetaStopReason = "end_turn",
): Anthropic.Beta.Messages.BetaMessage {
  return {
    id: "msg",
    type: "message",
    role: "assistant",
    model: MODEL,
    content: [{ type: "text", text, citations: null }],
    stop_reason: stop,
    usage: { input_tokens: 1, output_tokens: 1 },
  } as unknown as Anthropic.Beta.Messages.BetaMessage;
}

function fake(replies: Anthropic.Beta.Messages.BetaMessage[]) {
  const calls: Anthropic.Beta.Messages.MessageCreateParamsNonStreaming[] = [];
  const create: CreateMessage = (params) => {
    calls.push(structuredClone(params));
    return Promise.resolve(replies[calls.length - 1]);
  };
  return { create, calls };
}

const opts = (create: CreateMessage, deadlineMs = Date.now() + 140_000) => ({
  create,
  userText: "plan please",
  jsonSchema: planOutlineJsonSchema,
  schema: PlanOutline,
  check: (o: PlanOutline) => validateOutline(o, fitAnswers, 4),
  deadlineMs,
});

Deno.test("returns a valid plan from one call, with the right request", async () => {
  const { create, calls } = fake([message(JSON.stringify(goodOutline()))]);
  const plan = await generate(opts(create));
  assertEquals(plan.weeks.length, 4);
  assertEquals(calls.length, 1);
  const p = calls[0];
  assertEquals(p.model, "claude-opus-5-5");
  assertEquals(p.fallbacks, "default");
  assertEquals(p.betas, ["server-side-fallback-2026-07-01"]);
  assertEquals(p.output_config?.format?.type, "json_schema");
  assertEquals(p.output_config?.effort, "medium");
});

Deno.test("a rule violation is sent back once and the fix is accepted", async () => {
  const bad = goodOutline();
  bad.weeks[0].weekly_km = 60;
  const { create, calls } = fake([
    message(JSON.stringify(bad)),
    message(JSON.stringify(goodOutline())),
  ]);
  const plan = await generate(opts(create));
  assertEquals(plan.weeks[0].weekly_km, 15);
  assertEquals(calls.length, 2);
  const retry = calls[1].messages;
  assertEquals(retry.length, 3);
  assertEquals(retry[1].role, "assistant");
  assert(String(retry[2].content).includes("week 1 weekly_km"));
});

Deno.test("no retry when the deadline is too close", async () => {
  const bad = goodOutline();
  bad.weeks[0].weekly_km = 60;
  const { create, calls } = fake([message(JSON.stringify(bad))]);
  const err = await assertRejects(() => generate(opts(create, Date.now())), GenerationError);
  assertEquals(err.kind, "rules");
  assertEquals(calls.length, 1);
});

Deno.test("refusal, truncation and bad JSON fail cleanly", async () => {
  for (const [reply, kind] of [
    [message("", "refusal"), "refusal"],
    [message("{", "max_tokens"), "truncated"],
    [message("not json"), "invalid"],
    [message(JSON.stringify({ ...goodOutline(), readiness: "maybe" })), "invalid"],
  ] as const) {
    const { create } = fake([reply]);
    const err = await assertRejects(() => generate(opts(create)), GenerationError);
    assertEquals(err.kind, kind);
  }
});

Deno.test("prompt states the official target and the candidate's limits", () => {
  const text = outlineRequest(
    { examName: "UP Police Constable", gender: "male", age: 21, runDistanceM: 4800, targetSeconds: 1500, language: "hi" },
    beginnerAnswers,
    12,
  );
  assert(text.includes("run 4.8 km within 25 min 0 s"));
  assert(text.includes("Cannot yet run the full 4.8 km"));
  assert(text.includes("exactly 12 weeks"));
  assert(text.includes("0 hard sessions in weeks 1-2"));
  assert(text.includes("Hindi (Devanagari)"));
  assert(text.includes("at most 5 different days"));
});
