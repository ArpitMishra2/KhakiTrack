import { assert, assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";

import { downsample, handle } from "./index.ts";

const dir = new URL("../../../data/gps_traces/", import.meta.url);
const trace = (name: string) => JSON.parse(Deno.readTextFileSync(new URL(name, dir)));

/** Records inserts; supports the few query shapes handle() uses. */
function fakeAdmin(runsToday = 0) {
  const inserts: Record<string, Record<string, unknown>[]> = {};
  let nextId = 1;
  const db = {
    from(table: string) {
      return {
        select: () => {
          const q = {
            eq: () => q,
            gte: () => Promise.resolve({ count: runsToday, error: null }),
          };
          return q;
        },
        insert(row: Record<string, unknown>) {
          (inserts[table] ??= []).push(row);
          const done = Promise.resolve({ error: null });
          return Object.assign(done, {
            select: () => ({ single: () => Promise.resolve({ data: { id: nextId++ }, error: null }) }),
          });
        },
      };
    },
  };
  return { admin: db as unknown as SupabaseClient, inserts };
}

function submission(name: string, overrides: Record<string, unknown> = {}) {
  const t = trace(name);
  return {
    exam_id: "up_police_constable",
    mode: "mock_pet",
    target_m: t.target_m,
    plan_id: null,
    week_number: null,
    session_index: null,
    started_at: "2026-10-03T06:00:00+05:30",
    client_verdict: "verified",
    points: t.points,
    ...overrides,
  };
}

Deno.test("verified mock PET is stored with the server verdict and becomes a time trial", async () => {
  const { admin, inserts } = fakeAdmin();
  const res = await handle(submission("good_4800_steady.json"), { admin, userId: "u1" });
  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.verdict, "verified");
  const run = inserts.gps_runs[0];
  assertEquals(run.user_id, "u1");
  assertEquals(run.verdict, "verified");
  assertEquals(run.rules_version, 1);
  assert((run.route as unknown[]).length > 100 && (run.route as unknown[]).length <= 800);
  assertEquals(inserts.gps_run_points[0].run_id, 1);
  const trial = inserts.time_trials[0];
  assertEquals(trial.distance_m, 4800);
  assertEquals(trial.source, "gps");
  assertEquals(trial.recorded_on, "2026-10-03");
  assert(Math.abs((trial.duration_seconds as number) - 1497) <= 1);
});

Deno.test("a cheating run is rejected even if the app claims it is verified", async () => {
  const { admin, inserts } = fakeAdmin();
  const res = await handle(
    submission("bicycle.json", { client_verdict: "verified" }),
    { admin, userId: "u1" },
  );
  const body = await res.json();
  assertEquals(body.verdict, "rejected");
  assertEquals(inserts.gps_runs[0].verdict, "rejected");
  assertEquals(inserts.gps_runs[0].client_verdict, "verified");
  assertEquals(inserts.time_trials, undefined);
});

Deno.test("free runs never create time trials", async () => {
  const { admin, inserts } = fakeAdmin();
  await handle(submission("good_4800_steady.json", { mode: "free" }), { admin, userId: "u1" });
  assertEquals(inserts.time_trials, undefined);
});

Deno.test("bad input and the daily limit are refused", async () => {
  const { admin } = fakeAdmin();
  assertEquals((await handle({ mode: "free" }, { admin, userId: "u1" })).status, 400);
  const bad = submission("good_4800_steady.json");
  bad.points = [{ t: 0, lat: 200, lon: 0, acc: 5 }, { t: 1, lat: 0, lon: 0, acc: 5 }];
  assertEquals((await handle(bad, { admin, userId: "u1" })).status, 400);
  const limited = fakeAdmin(30);
  assertEquals(
    (await handle(submission("good_4800_steady.json"), { admin: limited.admin, userId: "u1" })).status,
    429,
  );
});

Deno.test("downsample keeps about one point per 5 s and at most 800", () => {
  const pts = Array.from({ length: 20000 }, (_, i) => ({ t: i * 1000, lat: 26, lon: 80, acc: 5 }));
  const d = downsample(pts);
  assert(d.length <= 800 && d.length > 600);
  assertEquals(downsample(pts.slice(0, 60)).length, 12);
});
