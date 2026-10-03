// training-plan: builds a personal PET running plan with Claude.
//
// POST { action: "create", answers }   -> new plan: outline + weeks 1-2
// POST { action: "next_week", plan_id } -> next week, adapted to the logs
//
// Runs as the signed-in user (their JWT), so row-level security applies to
// every read and write. The model is Groq (GROQ_API_KEY) in development,
// or Claude (ANTHROPIC_API_KEY); both are Supabase secrets.

import { createClient, type SupabaseClient } from "@supabase/supabase-js";

import {
  anthropicCreateMessage,
  claudeModel,
  groqModel,
  type JsonModel,
  generate,
  GenerationError,
} from "./generate.ts";
import { type Candidate, nextWeekRequest, outlineRequest, type WeekHistory } from "./prompt.ts";
import {
  Answers,
  PlanOutline,
  planOutlineJsonSchema,
  WeekDetail,
  weekDetailJsonSchema,
} from "./types.ts";
import { ageOn, pickRunStandard } from "./run_standard.ts";
import { validateOutline, validateWeek } from "./validate.ts";

const WALL_CLOCK_MS = 140_000;
const MAX_PLANS_PER_DAY = 3;
const MAX_WEEKS_PER_DAY = 4;

type Json = Record<string, unknown>;
const reply = (status: number, body: Json) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
const fail = (status: number, error: string, extra: Json = {}) =>
  reply(status, { error, ...extra });

export async function handle(
  req: Request,
  deps: { db: SupabaseClient; userId: string; model: JsonModel; today: string },
): Promise<Response> {
  const started = Date.now();
  let body: Json;
  try {
    body = await req.json();
  } catch {
    return fail(400, "bad_json");
  }

  try {
    if (body.action === "create") return await createPlan(body, deps, started);
    if (body.action === "next_week") return await nextWeek(body, deps, started);
    return fail(400, "unknown_action");
  } catch (e) {
    if (e instanceof GenerationError) {
      console.error(JSON.stringify({ event: "generation_failed", kind: e.kind, details: e.details }));
      if (e.kind === "busy") return fail(503, "ai_busy");
      return fail(502, "generation_failed", { kind: e.kind });
    }
    throw e;
  }
}

async function loadCandidate(db: SupabaseClient, userId: string, today: string) {
  const { data: profile, error } = await db
    .from("profiles")
    .select("gender, date_of_birth, category, exam_id, locale")
    .eq("id", userId)
    .single();
  if (error) throw error;
  if (!profile?.gender || !profile.date_of_birth || !profile.exam_id) return null;

  const [{ data: exam }, { data: runs }] = await Promise.all([
    db.from("exams").select("name_en").eq("id", profile.exam_id).single(),
    db.from("standards")
      .select("category, event, value, age_min, age_max")
      .eq("exam_id", profile.exam_id)
      .eq("gender", profile.gender)
      .eq("verified", true)
      .like("event", "run_%"),
  ]);
  const age = ageOn(profile.date_of_birth, today);
  const run = pickRunStandard(runs ?? [], profile.category, age);
  if (!exam || !run) return null;

  const candidate: Candidate = {
    examName: exam.name_en,
    gender: profile.gender,
    age,
    runDistanceM: run.metres,
    targetSeconds: run.seconds,
    language: profile.locale === "en" ? "en" : "hi",
  };
  return { candidate, examId: profile.exam_id as string };
}

/**
 * Takes one of the user's AI slots for the day, or returns null when they are
 * used up. The count lives in a ledger users cannot edit (ai_usage), unlike
 * the plan rows they own and could delete or back-date.
 */
export async function claimSlot(db: SupabaseClient, kind: "plan" | "week", max: number) {
  const { data, error } = await db.rpc("claim_ai_slot", { p_kind: kind, p_max: max });
  if (error) throw error;
  return (data as string | null) ?? null;
}

/** Marks a slot as used for good; best effort, the slot is counted anyway. */
export async function finishSlot(db: SupabaseClient, id: string) {
  await db.rpc("finish_ai_slot", { p_id: id });
}

/** Gives a slot back when generation failed, so a failure costs the user nothing. */
export async function releaseSlot(db: SupabaseClient, id: string) {
  try {
    await db.rpc("release_ai_slot", { p_id: id });
  } catch {
    // The slot frees itself after ten minutes anyway.
  }
}

async function createPlan(
  body: Json,
  { db, userId, model, today }: Parameters<typeof handle>[1],
  started: number,
) {
  const parsed = Answers.safeParse(body.answers);
  if (!parsed.success) return fail(400, "invalid_answers", { issues: parsed.error.issues.length });
  const answers = parsed.data;

  const loaded = await loadCandidate(db, userId, today);
  if (!loaded) return fail(409, "profile_incomplete");
  const { candidate, examId } = loaded;

  const slot = await claimSlot(db, "plan", MAX_PLANS_PER_DAY);
  if (!slot) return fail(429, "rate_limited");
  try {
    const response = await buildPlan(db, userId, model, today, started, answers, candidate, examId);
    await finishSlot(db, slot);
    return response;
  } catch (e) {
    await releaseSlot(db, slot);
    throw e;
  }
}

async function buildPlan(
  db: SupabaseClient,
  userId: string,
  model: JsonModel,
  today: string,
  started: number,
  answers: Answers,
  candidate: Candidate,
  examId: string,
) {
  const weeksTotal = answers.weeks_to_pet;
  const { value: outline, model: modelName } = await generate({
    model,
    schemaName: "training_plan",
    userText: outlineRequest(candidate, answers, weeksTotal),
    jsonSchema: planOutlineJsonSchema,
    schema: PlanOutline,
    check: (o) => validateOutline(o, answers, weeksTotal),
    deadlineMs: started + WALL_CLOCK_MS,
  });

  const { data: assessment, error: aErr } = await db.from("training_assessments")
    .insert({ user_id: userId, exam_id: examId, answers })
    .select("id").single();
  if (aErr) throw aErr;

  const { error: archiveErr } = await db.from("training_plans")
    .update({ status: "archived" })
    .eq("user_id", userId).eq("status", "active");
  if (archiveErr) throw archiveErr;

  const { first_weeks, ...outlineOnly } = outline;
  const { data: plan, error: pErr } = await db.from("training_plans").insert({
    user_id: userId,
    exam_id: examId,
    assessment_id: assessment.id,
    language: candidate.language,
    run_distance_m: candidate.runDistanceM,
    target_seconds: candidate.targetSeconds,
    start_date: today,
    weeks_total: weeksTotal,
    outline: outlineOnly,
    model: modelName,
  }).select("id").single();
  if (pErr) throw pErr;

  const { error: wErr } = await db.from("plan_weeks").insert(
    first_weeks.map((w) => ({
      plan_id: plan.id,
      user_id: userId,
      week_number: w.week,
      sessions: { sessions: w.sessions, coach_note: w.coach_note },
      model: modelName,
    })),
  );
  if (wErr) throw wErr;

  if (answers.can_complete_distance && answers.current_time_seconds) {
    await db.from("time_trials").insert({
      user_id: userId,
      exam_id: examId,
      distance_m: candidate.runDistanceM,
      duration_seconds: answers.current_time_seconds,
      recorded_on: today,
      source: "assessment",
    });
  }
  return reply(200, { plan_id: plan.id });
}

async function nextWeek(
  body: Json,
  { db, userId, model, today }: Parameters<typeof handle>[1],
  started: number,
) {
  const planId = Number(body.plan_id);
  if (!Number.isInteger(planId)) return fail(400, "invalid_plan_id");

  const { data: plan } = await db.from("training_plans")
    .select("id, exam_id, assessment_id, status, start_date, weeks_total, outline")
    .eq("id", planId).eq("user_id", userId).maybeSingle();
  if (!plan || plan.status !== "active") return fail(404, "not_found");

  const { data: weeks } = await db.from("plan_weeks")
    .select("week_number, sessions").eq("plan_id", planId).order("week_number");
  const n = (weeks?.at(-1)?.week_number ?? 0) + 1;
  if (n > plan.weeks_total) return fail(409, "plan_complete");

  // Unlock the next week from two days before it starts, so it can adapt to
  // what was actually logged rather than being generated far ahead.
  const unlock = new Date(plan.start_date);
  unlock.setDate(unlock.getDate() + (n - 1) * 7 - 2);
  if (new Date(today) < unlock) {
    return fail(409, "too_early", { unlocks_on: unlock.toISOString().slice(0, 10) });
  }

  const loaded = await loadCandidate(db, userId, today);
  if (!loaded) return fail(409, "profile_incomplete");

  const slot = await claimSlot(db, "week", MAX_WEEKS_PER_DAY);
  if (!slot) return fail(429, "rate_limited");
  try {
    const response = await buildWeek(db, userId, model, today, started, plan, planId, n, weeks ?? [], loaded);
    await finishSlot(db, slot);
    return response;
  } catch (e) {
    await releaseSlot(db, slot);
    throw e;
  }
}

async function buildWeek(
  db: SupabaseClient,
  userId: string,
  model: JsonModel,
  today: string,
  started: number,
  plan: { exam_id: string; assessment_id: number; weeks_total: number; outline: unknown },
  planId: number,
  n: number,
  weeks: Array<{ week_number: number; sessions: { sessions: WeekDetail["sessions"] } }>,
  loaded: { candidate: Candidate; examId: string },
) {
  const [{ data: assessment }, { data: logs }, { data: trial }] = await Promise.all([
    db.from("training_assessments").select("answers").eq("id", plan.assessment_id).single(),
    db.from("session_logs")
      .select("week_number, session_index, status, distance_km, duration_seconds, effort, pain, note")
      .eq("plan_id", planId),
    db.from("time_trials").select("distance_m, duration_seconds, recorded_on")
      .eq("user_id", userId).eq("exam_id", plan.exam_id)
      .order("recorded_on", { ascending: false }).limit(1).maybeSingle(),
  ]);
  const answers = Answers.parse(assessment!.answers);
  const outline = PlanOutline.omit({ first_weeks: true }).parse(plan.outline);
  const outlineWeek = outline.weeks.find((w) => w.week === n)!;

  const history: WeekHistory[] = weeks.map((w) => ({
    week: w.week_number,
    sessions: w.sessions.sessions,
    logs: (logs ?? []).filter((l) => l.week_number === w.week_number),
  }));

  const { value: detail, model: modelName } = await generate({
    model,
    schemaName: "training_week",
    userText: nextWeekRequest(
      loaded.candidate,
      answers,
      { ...outline, first_weeks: [] },
      n,
      history,
      trial ?? null,
    ),
    jsonSchema: weekDetailJsonSchema,
    schema: WeekDetail,
    check: (d) => [
      ...(d.week === n ? [] : [`week must be ${n}`]),
      ...validateWeek(d, outlineWeek, answers),
    ],
    deadlineMs: started + WALL_CLOCK_MS,
  });

  const { error } = await db.from("plan_weeks").insert({
    plan_id: planId,
    user_id: userId,
    week_number: n,
    sessions: { sessions: detail.sessions, coach_note: detail.coach_note },
    model: modelName,
  });
  if (error) throw error;
  return reply(200, { plan_id: planId, week_number: n });
}

/** Today's date in India, YYYY-MM-DD. */
export const indiaToday = () =>
  new Date(Date.now() + 5.5 * 3_600_000).toISOString().slice(0, 10);

if (import.meta.main) {
  Deno.serve(async (req) => {
    if (req.method !== "POST") return fail(405, "method_not_allowed");
    const auth = req.headers.get("Authorization");
    if (!auth) return fail(401, "unauthorized");

    const db = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: auth } } },
    );
    const { data: { user } } = await db.auth.getUser(auth.replace(/^Bearer /, ""));
    if (!user) return fail(401, "unauthorized");

    // Groq while in development; Claude if only its key is set.
    const groqKey = Deno.env.get("GROQ_API_KEY");
    const claudeKey = Deno.env.get("ANTHROPIC_API_KEY");
    const model = groqKey
      ? groqModel(groqKey)
      : claudeKey
      ? claudeModel(anthropicCreateMessage(claudeKey))
      : null;
    if (!model) return fail(503, "ai_not_configured");

    return handle(req, {
      db,
      userId: user.id,
      model,
      today: indiaToday(),
    });
  });
}
