import { assert, assertEquals, assertRejects } from "@std/assert";
import type Anthropic from "@anthropic-ai/sdk";

import {
  claudeModel,
  type CreateMessage,
  generate,
  GenerationError,
  groqModel,
  type JsonModel,
  type JsonReply,
} from "./generate.ts";
import { outlineRequest, SYSTEM_PROMPT } from "./prompt.ts";
import { PlanOutline, planOutlineJsonSchema } from "./types.ts";
import { validateOutline } from "./validate.ts";
import { beginnerAnswers, fitAnswers, goodOutline } from "./validate_test.ts";

const reply = (text: string, stop: JsonReply["stop"] = "end"): JsonReply => ({
  text,
  stop,
  model: "test-model",
  inputTokens: 1,
  outputTokens: 1,
});

function fake(replies: JsonReply[]) {
  const calls: Parameters<JsonModel>[0][] = [];
  const model: JsonModel = (req) => {
    calls.push(structuredClone(req));
    return Promise.resolve(replies[calls.length - 1]);
  };
  return { model, calls };
}

const opts = (model: JsonModel, deadlineMs = Date.now() + 140_000) => ({
  model,
  userText: "plan please",
  schemaName: "training_plan",
  jsonSchema: planOutlineJsonSchema,
  schema: PlanOutline,
  check: (o: PlanOutline) => validateOutline(o, fitAnswers, 4),
  deadlineMs,
});

Deno.test("returns a valid plan and the model that wrote it", async () => {
  const { model, calls } = fake([reply(JSON.stringify(goodOutline()))]);
  const { value, model: name } = await generate(opts(model));
  assertEquals(value.weeks.length, 4);
  assertEquals(name, "test-model");
  assertEquals(calls.length, 1);
  assertEquals(calls[0].system, SYSTEM_PROMPT);
  assertEquals(calls[0].schemaName, "training_plan");
});

Deno.test("a rule violation is sent back once and the fix is accepted", async () => {
  const bad = goodOutline();
  bad.weeks[0].weekly_km = 60;
  const { model, calls } = fake([reply(JSON.stringify(bad)), reply(JSON.stringify(goodOutline()))]);
  const { value } = await generate(opts(model));
  assertEquals(value.weeks[0].weekly_km, 15);
  const retry = calls[1].messages;
  assertEquals(retry.length, 3);
  assertEquals(retry[1].role, "assistant");
  assert(retry[2].content.includes("week 1 weekly_km"));
});

Deno.test("no retry when the deadline is too close", async () => {
  const bad = goodOutline();
  bad.weeks[0].weekly_km = 60;
  const { model, calls } = fake([reply(JSON.stringify(bad))]);
  const err = await assertRejects(() => generate(opts(model, Date.now())), GenerationError);
  assertEquals(err.kind, "rules");
  assertEquals(calls.length, 1);
});

Deno.test("refusal, truncation and bad JSON fail cleanly", async () => {
  for (const [r, kind] of [
    [reply("", "refusal"), "refusal"],
    [reply("{", "truncated"), "truncated"],
    [reply("not json"), "invalid"],
    [reply(JSON.stringify({ ...goodOutline(), readiness: "maybe" })), "invalid"],
  ] as const) {
    const { model } = fake([r]);
    const err = await assertRejects(() => generate(opts(model)), GenerationError);
    assertEquals(err.kind, kind);
  }
});

Deno.test("groq: strict JSON schema request, and replies mapped", async () => {
  let sent: { url: string; init: RequestInit } | null = null;
  const respond = (body: unknown, status = 200) => {
    const fetchFn = ((url: string, init: RequestInit) => {
      sent = { url, init };
      return Promise.resolve(new Response(JSON.stringify(body), { status }));
    }) as unknown as typeof fetch;
    return groqModel("gsk_test", fetchFn);
  };

  const ok = await respond({
    model: "openai/gpt-oss-120b",
    choices: [{ message: { content: '{"a":1}' }, finish_reason: "stop" }],
    usage: { prompt_tokens: 10, completion_tokens: 20 },
  })({ system: "S", messages: [{ role: "user", content: "U" }], schemaName: "x", jsonSchema: { type: "object" } });
  assertEquals(ok, { text: '{"a":1}', stop: "end", model: "openai/gpt-oss-120b", inputTokens: 10, outputTokens: 20 });
  assertEquals(sent!.url, "https://api.groq.com/openai/v1/chat/completions");
  assertEquals((sent!.init.headers as Record<string, string>).Authorization, "Bearer gsk_test");
  const body = JSON.parse(sent!.init.body as string);
  assertEquals(body.model, "openai/gpt-oss-120b");
  assertEquals(body.messages[0], { role: "system", content: "S" });
  assertEquals(body.response_format.type, "json_schema");
  assertEquals(body.response_format.json_schema.strict, true);
  assertEquals(body.response_format.json_schema.name, "x");

  const cut = await respond({ choices: [{ message: { content: "{" }, finish_reason: "length" }] })(
    { system: "S", messages: [], schemaName: "x", jsonSchema: {} },
  );
  assertEquals(cut.stop, "truncated");

  const err = await assertRejects(
    () => respond({ error: "bad" }, 401)({ system: "S", messages: [], schemaName: "x", jsonSchema: {} }),
    GenerationError,
  );
  assertEquals(err.kind, "provider");
});

Deno.test("groq: waits out a short rate limit, reports busy on a long one", async () => {
  const ok = { choices: [{ message: { content: "{}" }, finish_reason: "stop" }] };
  const seq = (...rs: Response[]) => {
    let i = 0;
    return (() => Promise.resolve(rs[i++])) as unknown as typeof fetch;
  };
  const limited = (after: string) =>
    new Response("{}", { status: 429, headers: { "retry-after": after } });
  const waits: number[] = [];
  const sleep = (ms: number) => (waits.push(ms), Promise.resolve());
  const req = { system: "S", messages: [], schemaName: "x", jsonSchema: {} };

  const r = await groqModel("k", seq(limited("12"), new Response(JSON.stringify(ok))), sleep)(req);
  assertEquals(r.stop, "end");
  assertEquals(waits, [12500]);

  const err = await assertRejects(() => groqModel("k", seq(limited("90")), sleep)(req), GenerationError);
  assertEquals(err.kind, "busy");
  assertEquals(waits.length, 1); // did not wait 90 s
});

Deno.test("claude: structured output request with fallbacks", async () => {
  let params: Anthropic.Beta.Messages.MessageCreateParamsNonStreaming | null = null;
  const create: CreateMessage = (p) => {
    params = p;
    return Promise.resolve({
      model: "claude-opus-5-5",
      content: [{ type: "text", text: "{}", citations: null }],
      stop_reason: "max_tokens",
      usage: { input_tokens: 3, output_tokens: 4 },
    } as unknown as Anthropic.Beta.Messages.BetaMessage);
  };
  const r = await claudeModel(create)({ system: "S", messages: [{ role: "user", content: "U" }], schemaName: "x", jsonSchema: { type: "object" } });
  assertEquals(r.stop, "truncated");
  assertEquals(params!.model, "claude-opus-5-5");
  assertEquals(params!.fallbacks, "default");
  assertEquals(params!.output_config?.format?.type, "json_schema");
});

Deno.test("prompt states the target, limits, and keeps safety serious", () => {
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
  assert(SYSTEM_PROMPT.includes("funny"));
  assert(SYSTEM_PROMPT.includes("Never joke about the candidate's body"));
  assert(SYSTEM_PROMPT.includes("Safety notes, pain and medical advice are always plain and serious"));
});
