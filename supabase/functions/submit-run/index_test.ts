import { assert, assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";

import { downsample, handle } from "./index.ts";

const dir = new URL("../../../data/gps_traces/", import.meta.url);
const trace = (name: string) => JSON.parse(Deno.readTextFileSync(new URL(name, dir)));

type Existing = { started_at: string; duration_s: number; distance_m: number; verdict: string };

// 2026-10-03 08:00 IST: just after the sample runs (06:00 IST) finished.
const NOW = Date.parse("2026-10-03T08:00:00+05:30");

/** Records inserts; supports the few query shapes handle() uses. */
function fakeAdmin(opts: { runsToday?: number; existing?: Existing[]; ownsPlan?: boolean } = {}) {
  const inserts: Record<string, Record<string, unknown>[]> = {};
  let nextId = 1;
  const db = {
    from(table: string) {
      return {
        select: (_cols?: string, o?: { head?: boolean }) => {
          const q: Record<string, unknown> = {
            eq: () => q,
            gte: () => q,
            lte: () => q,
            limit: () => q,
            maybeSingle: () => Promise.resolve({ data: opts.ownsPlan ? { id: 1 } : null, error: null }),
            then: (res: (v: unknown) => unknown, rej: (e: unknown) => unknown) =>
              Promise.resolve(
                o?.head
                  ? { count: opts.runsToday ?? 0, error: null }
                  : { data: opts.existing ?? [], error: null },
              ).then(res, rej),
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

const deps = (admin: SupabaseClient, now = NOW) => ({ admin, userId: "u1", now: () => now });

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
  const res = await handle(submission("good_4800_steady.json"), deps(admin));
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
    deps(admin),
  );
  const body = await res.json();
  assertEquals(body.verdict, "rejected");
  assertEquals(inserts.gps_runs[0].verdict, "rejected");
  assertEquals(inserts.gps_runs[0].client_verdict, "verified");
  assertEquals(inserts.time_trials, undefined);
});

Deno.test("free runs never create time trials", async () => {
  const { admin, inserts } = fakeAdmin();
  await handle(submission("good_4800_steady.json", { mode: "free" }), deps(admin));
  assertEquals(inserts.time_trials, undefined);
});

Deno.test("bad input and the daily limit are refused", async () => {
  const { admin } = fakeAdmin();
  assertEquals((await handle({ mode: "free" }, deps(admin))).status, 400);
  const bad = submission("good_4800_steady.json");
  bad.points = [{ t: 0, lat: 200, lon: 0, acc: 5 }, { t: 1, lat: 0, lon: 0, acc: 5 }];
  assertEquals((await handle(bad, deps(admin))).status, 400);
  const limited = fakeAdmin({ runsToday: 12 });
  assertEquals(
    (await handle(submission("good_4800_steady.json"), deps(limited.admin))).status,
    429,
  );
});

Deno.test("downsample keeps about one point per 5 s and at most 800", () => {
  const pts = Array.from({ length: 20000 }, (_, i) => ({ t: i * 1000, lat: 26, lon: 80, acc: 5 }));
  const d = downsample(pts);
  assert(d.length <= 800 && d.length > 600);
  assertEquals(downsample(pts.slice(0, 60)).length, 12);
});

Deno.test("a run cannot claim a start time that is old or in the future", async () => {
  const { admin, inserts } = fakeAdmin();
  const old = submission("good_4800_steady.json", { started_at: "2026-09-20T06:00:00+05:30" });
  assertEquals((await handle(old, deps(admin))).status, 400);
  const future = submission("good_4800_steady.json", { started_at: "2026-10-04T06:00:00+05:30" });
  assertEquals((await handle(future, deps(admin))).status, 400);
  // Ends 30 min after the phone says it is now.
  const live = submission("good_4800_steady.json", { started_at: "2026-10-03T07:50:00+05:30" });
  assertEquals((await handle(live, deps(admin))).status, 400);
  assertEquals(inserts.gps_runs, undefined);
  // A run from two days ago, uploaded late, is fine.
  const late = submission("good_4800_steady.json", { started_at: "2026-10-01T06:00:00+05:30" });
  assertEquals((await handle(late, deps(admin))).status, 200);
});

Deno.test("the same run, or one overlapping in time, is counted once", async () => {
  const first = fakeAdmin();
  assertEquals((await handle(submission("good_4800_steady.json"), deps(first.admin))).status, 200);
  const stored = first.inserts.gps_runs[0];
  const asRow = (startedAt: string): Existing => ({
    started_at: startedAt,
    duration_s: stored.duration_s as number,
    distance_m: stored.distance_m as number,
    verdict: "verified",
  });
  // Exact duplicate.
  const dup = fakeAdmin({ existing: [asRow("2026-10-03T06:00:00+05:30")] });
  const r1 = await handle(submission("good_4800_steady.json"), deps(dup.admin));
  assertEquals(r1.status, 409);
  assertEquals(dup.inserts.gps_runs, undefined);
  // Starts ten minutes later, while the first run is still going.
  const overlap = fakeAdmin({ existing: [asRow("2026-10-03T06:00:00+05:30")] });
  const r2 = await handle(
    submission("good_4800_steady.json", { started_at: "2026-10-03T06:10:00+05:30" }),
    deps(overlap.admin, Date.parse("2026-10-03T09:00:00+05:30")),
  );
  assertEquals(r2.status, 409);
  // A run the evening before does not overlap.
  const fine = fakeAdmin({ existing: [asRow("2026-10-02T18:00:00+05:30")] });
  assertEquals((await handle(submission("good_4800_steady.json"), deps(fine.admin))).status, 200);
});

Deno.test("more distance than a person can cover in a day is refused", async () => {
  const marathons = fakeAdmin({
    existing: [
      { started_at: "2026-10-02T20:00:00+05:30", duration_s: 7200, distance_m: 30000, verdict: "verified" },
      { started_at: "2026-10-03T00:30:00+05:30", duration_s: 7200, distance_m: 30000, verdict: "verified" },
    ],
  });
  const res = await handle(submission("good_4800_steady.json"), deps(marathons.admin));
  assertEquals(res.status, 429);
  assertEquals((await res.json()).error, "daily_limit");
  // Rejected (cheating) runs do not count toward the limit.
  const cheats = fakeAdmin({
    existing: [{ started_at: "2026-10-02T20:00:00+05:30", duration_s: 3600, distance_m: 90000, verdict: "rejected" }],
  });
  assertEquals((await handle(submission("good_4800_steady.json"), deps(cheats.admin))).status, 200);
});

Deno.test("a run can only point at the caller's own plan", async () => {
  const theirs = fakeAdmin({ ownsPlan: false });
  await handle(submission("good_4800_steady.json", { plan_id: 99, week_number: 1, session_index: 0 }), deps(theirs.admin));
  assertEquals(theirs.inserts.gps_runs[0].plan_id, null);
  const mine = fakeAdmin({ ownsPlan: true });
  await handle(submission("good_4800_steady.json", { plan_id: 7 }), deps(mine.admin));
  assertEquals(mine.inserts.gps_runs[0].plan_id, 7);
});
