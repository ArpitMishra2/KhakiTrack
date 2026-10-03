// submit-run: stores a GPS run with a verdict computed here, not on the phone.
//
// The caller is identified from their JWT. The run is re-analysed from the
// raw points with the same rules as the app (analysis.ts) and written with
// the service role, because users have no insert policy on gps_runs: that is
// what stops a modified app from recording its own "verified" runs.
// A verified mock PET also becomes a time trial.

import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { z } from "zod";

import { analyseRun, RULES, type RunAnalysis, type TrackPoint } from "./analysis.ts";

// Limits that keep one account from flooding the rankings or the database.
const MAX_RUNS_PER_DAY = 12;
/** A run may be uploaded late (offline queue), but not claim an old date. */
const MAX_AGE_MS = 7 * 86_400_000;
/** Phone clocks drift a little; a run cannot end in the future beyond this. */
const CLOCK_SKEW_MS = 10 * 60_000;
/** Real distance a person could cover in 24 hours; more is not believable. */
const MAX_DAILY_M = 60_000;
export const MAX_BODY_BYTES = 4_000_000;

export const Submission = z.object({
  exam_id: z.string().min(1).max(64),
  mode: z.enum(["free", "mock_pet", "session"]),
  target_m: z.number().int().min(100).max(42195).nullable(),
  plan_id: z.number().int().nullable(),
  week_number: z.number().int().min(1).max(30).nullable(),
  session_index: z.number().int().min(0).max(10).nullable(),
  started_at: z.string().datetime({ offset: true }),
  client_verdict: z.enum(["verified", "suspicious", "rejected"]).nullable(),
  points: z.array(z.object({
    t: z.number().int().min(0).max(6 * 3600 * 1000),
    lat: z.number().min(-90).max(90),
    lon: z.number().min(-180).max(180),
    acc: z.number().min(0).max(10000),
    mock: z.boolean().optional(),
  })).min(2).max(25000),
});
export type Submission = z.infer<typeof Submission>;

/** About one point every 5 s, at most 800, for drawing the route. */
export function downsample(points: TrackPoint[]): number[][] {
  const out: number[][] = [];
  let last = -Infinity;
  for (const p of points) {
    if (p.t - last >= 5000) {
      out.push([+p.lat.toFixed(6), +p.lon.toFixed(6), Math.round(p.t / 1000)]);
      last = p.t;
    }
  }
  const step = Math.ceil(out.length / 800);
  return step > 1 ? out.filter((_, i) => i % step === 0) : out;
}

const reply = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

export async function handle(
  body: unknown,
  deps: { admin: SupabaseClient; userId: string; now?: () => number },
): Promise<Response> {
  const parsed = Submission.safeParse(body);
  if (!parsed.success) return reply(400, { error: "invalid_run" });
  const s = parsed.data;
  const { admin, userId } = deps;
  const now = (deps.now ?? Date.now)();

  const result: RunAnalysis = analyseRun(s.points, s.target_m);

  // The start time decides which week a run counts in, so it cannot be taken
  // on trust: it must be recent and the run must not end in the future.
  const startMs = Date.parse(s.started_at);
  const endMs = startMs + result.durationS * 1000;
  if (startMs < now - MAX_AGE_MS || endMs > now + CLOCK_SKEW_MS) {
    return reply(400, { error: "invalid_start" });
  }

  const { count } = await admin.from("gps_runs")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId)
    .gte("created_at", new Date(Date.now() - 86_400_000).toISOString());
  if ((count ?? 0) >= MAX_RUNS_PER_DAY) return reply(429, { error: "rate_limited" });

  // The same run cannot be counted twice, and two runs cannot overlap in
  // time (one person cannot run two routes at once). Resending a run whose
  // answer got lost is answered with 409 and is harmless.
  const { data: nearby } = await admin.from("gps_runs")
    .select("started_at, duration_s, distance_m, verdict")
    .eq("user_id", userId)
    .gte("started_at", new Date(startMs - 86_400_000).toISOString())
    .lte("started_at", new Date(endMs).toISOString())
    .limit(200);
  let lastDayM = 0;
  for (const r of (nearby ?? []) as Array<{ started_at: string; duration_s: number; distance_m: number; verdict: string }>) {
    const rs = Date.parse(r.started_at);
    const re = rs + Number(r.duration_s) * 1000;
    if (startMs <= re && endMs >= rs) return reply(409, { error: "duplicate_run" });
    if (r.verdict !== "rejected" && rs >= endMs - 86_400_000) lastDayM += Number(r.distance_m);
  }
  if (result.verdict !== "rejected" && lastDayM + result.distanceM > MAX_DAILY_M) {
    return reply(429, { error: "daily_limit" });
  }

  // A run can only point at the caller's own plan.
  let planId = s.plan_id;
  if (planId != null) {
    const { data: plan } = await admin.from("training_plans").select("id")
      .eq("id", planId).eq("user_id", userId).maybeSingle();
    if (!plan) planId = null;
  }

  const { data: run, error } = await admin.from("gps_runs").insert({
    user_id: userId,
    exam_id: s.exam_id,
    mode: s.mode,
    plan_id: planId,
    week_number: s.week_number,
    session_index: s.session_index,
    started_at: s.started_at,
    target_m: s.target_m,
    distance_m: Math.round(result.distanceM * 10) / 10,
    duration_s: Math.round(result.durationS * 10) / 10,
    finish_seconds: result.finishSeconds == null ? null : Math.round(result.finishSeconds * 10) / 10,
    verdict: result.verdict,
    flags: result.flags,
    client_verdict: s.client_verdict,
    rules_version: RULES.version,
    point_count: s.points.length,
    route: downsample(s.points),
  }).select("id").single();
  if (error) throw error;

  const { error: pErr } = await admin.from("gps_run_points")
    .insert({ run_id: run.id, user_id: userId, points: s.points });
  if (pErr) throw pErr;

  if (
    result.verdict === "verified" && s.target_m != null && result.finishSeconds != null &&
    (s.mode === "mock_pet" || s.mode === "session")
  ) {
    const { error: tErr } = await admin.from("time_trials").insert({
      user_id: userId,
      exam_id: s.exam_id,
      distance_m: s.target_m,
      duration_seconds: Math.round(result.finishSeconds),
      recorded_on: s.started_at.slice(0, 10),
      source: "gps",
    });
    if (tErr) throw tErr;
  }

  return reply(200, {
    run_id: run.id,
    verdict: result.verdict,
    flags: result.flags,
    distance_m: result.distanceM,
    duration_s: result.durationS,
    finish_seconds: result.finishSeconds,
  });
}

if (import.meta.main) {
  Deno.serve(async (req) => {
    if (req.method !== "POST") return reply(405, { error: "method_not_allowed" });
    const auth = req.headers.get("Authorization");
    if (!auth) return reply(401, { error: "unauthorized" });

    const url = Deno.env.get("SUPABASE_URL")!;
    const asUser = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: auth } },
    });
    const { data: { user } } = await asUser.auth.getUser(auth.replace(/^Bearer /, ""));
    if (!user) return reply(401, { error: "unauthorized" });

    // Refuse oversized bodies before reading them (a real run is about 2 MB at most).
    if (Number(req.headers.get("content-length") ?? 0) > MAX_BODY_BYTES) {
      return reply(413, { error: "too_large" });
    }
    let body: unknown;
    try {
      const raw = await req.text();
      if (raw.length > MAX_BODY_BYTES) return reply(413, { error: "too_large" });
      body = JSON.parse(raw);
    } catch {
      return reply(400, { error: "bad_json" });
    }
    // Service role only for the writes users are not allowed to make.
    const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
      auth: { persistSession: false },
    });
    return handle(body, { admin, userId: user.id });
  });
}
