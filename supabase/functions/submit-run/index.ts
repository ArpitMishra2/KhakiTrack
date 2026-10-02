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

const MAX_RUNS_PER_DAY = 30;

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
  deps: { admin: SupabaseClient; userId: string },
): Promise<Response> {
  const parsed = Submission.safeParse(body);
  if (!parsed.success) return reply(400, { error: "invalid_run" });
  const s = parsed.data;
  const { admin, userId } = deps;

  const { count } = await admin.from("gps_runs")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId)
    .gte("created_at", new Date(Date.now() - 86_400_000).toISOString());
  if ((count ?? 0) >= MAX_RUNS_PER_DAY) return reply(429, { error: "rate_limited" });

  const result: RunAnalysis = analyseRun(s.points, s.target_m);

  const { data: run, error } = await admin.from("gps_runs").insert({
    user_id: userId,
    exam_id: s.exam_id,
    mode: s.mode,
    plan_id: s.plan_id,
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

    let body: unknown;
    try {
      body = await req.json();
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
