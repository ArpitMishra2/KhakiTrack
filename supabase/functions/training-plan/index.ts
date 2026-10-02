// training-plan: builds a personal PET running plan with Claude.
//
// POST { action: "create", answers }   -> new plan: outline + weeks 1-2
// POST { action: "next_week", plan_id } -> next week, adapted to the logs
//
// Runs as the signed-in user (their JWT), so row-level security applies to
// every read and write. ANTHROPIC_API_KEY is a Supabase secret.

import { createClient, type SupabaseClient } from "@supabase/supabase-js";

import {
  anthropicCreateMessage,
  type CreateMessage,
  generate,
  GenerationError,
  MODEL,
} from "./generate.ts";
import { type Candidate, nextWeekRequest, outlineRequest, type WeekHistory } from "./prompt.ts";
import {
  Answers,
  PlanOutline,
  planOutlineJsonSchema,
  WeekDetail,
  weekDetailJsonSchema,
} from "./types.ts";
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
  deps: { db: SupabaseClient; userId: string; create: CreateMessage; today: string },
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
      .select("category, event, value")
      .eq("exam_id", profile.exam_id)
      .eq("gender", profile.gender)
      .eq("verified", true)
      .like("event", "run_%"),
  ]);
  // Same order as the app: the candidate's ST row if any, then the
  // all-category row, then the exam's default category.
  const order = [profile.category === "st" ? "st" : "", "all", "general", "general_obc_sc"];
  const run = order.map((c) => runs?.find((r) => r.category === c)).find(Boolean);
  if (!exam || !run) return null;

  const dob = new Date(profile.date_of_birth);
  const t = new Date(today);
  const age = t.getFullYear() - dob.getFullYear() -
    (t < new Date(t.getFullYear(), dob.getMonth(), dob.getDate()) ? 1 : 0);

  const candidate: Candidate = {
    examName: exam.name_en,
    gender: profile.gender,
    age,
    runDistanceM: Number(run.event.slice(4, -1)),
    targetSeconds: Number(run.value),
    language: profile.locale === "en" ? "en" : "hi",
  };
  return { candidate, examId: profile.exam_id as string };
}

async function countSince(db: SupabaseClient, table: string, userId: string, since: Date) {
  const { count } = await db.from(table)
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId)
    .gte("created_at", since.toISOString());
  return count ?? 0;
}

async function createPlan(
  body: Json,
  { db, userId, create, today }: Parameters<typeof handle>[1],
  started: number,
) {
  const parsed = Answers.safeParse(body.answers);
  if (!parsed.success) return fail(400, "invalid_answers", { issues: parsed.error.issues.length });
  const answers = parsed.data;

  const loaded = await loadCandidate(db, userId, today);
  if (!loaded) return fail(409, "profile_incomplete");
  const { candidate, examId } = loaded;

  const dayAgo = new Date(Date.now() - 86_400_000);
  if (await countSince(db, "training_plans", userId, dayAgo) >= MAX_PLANS_PER_DAY) {
    return fail(429, "rate_limited");
  }

  const weeksTotal = answers.weeks_to_pet;
  const outline = await generate({
    create,
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
    model: MODEL,
  }).select("id").single();
  if (pErr) throw pErr;

  const { error: wErr } = await db.from("plan_weeks").insert(
    first_weeks.map((w) => ({
      plan_id: plan.id,
      user_id: userId,
      week_number: w.week,
      sessions: { sessions: w.sessions, coach_note: w.coach_note },
      model: MODEL,
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
  { db, userId, create, today }: Parameters<typeof handle>[1],
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

  const dayAgo = new Date(Date.now() - 86_400_000);
  if (await countSince(db, "plan_weeks", userId, dayAgo) >= MAX_WEEKS_PER_DAY) {
    return fail(429, "rate_limited");
  }

  const loaded = await loadCandidate(db, userId, today);
  if (!loaded) return fail(409, "profile_incomplete");
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

  const history: WeekHistory[] = (weeks ?? []).map((w) => ({
    week: w.week_number,
    sessions: w.sessions.sessions,
    logs: (logs ?? []).filter((l) => l.week_number === w.week_number),
  }));

  const detail = await generate({
    create,
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
    model: MODEL,
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

    const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!apiKey) return fail(503, "ai_not_configured");

    return handle(req, {
      db,
      userId: user.id,
      create: anthropicCreateMessage(apiKey),
      today: indiaToday(),
    });
  });
}
