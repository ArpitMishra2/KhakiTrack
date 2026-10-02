import { assert, assertAlmostEquals, assertEquals } from "@std/assert";

import { analyseRun, haversineM, type TrackPoint } from "./analysis.ts";

const dir = new URL("../../../data/gps_traces/", import.meta.url);
const files = [...Deno.readDirSync(dir)]
  .filter((e) => e.name.endsWith(".json") && e.name !== "golden.json")
  .map((e) => e.name)
  .sort();

Deno.test("trace folder is not empty", () => assert(files.length > 10));

for (const name of files) {
  const trace = JSON.parse(Deno.readTextFileSync(new URL(name, dir)));
  Deno.test(`${name}: ${trace.description}`, () => {
    const r = analyseRun(trace.points as TrackPoint[], trace.target_m ?? null);
    const e = trace.expected;
    const why = `verdict ${r.verdict}, flags ${r.flags}, distance ${Math.round(r.distanceM)} m, finish ${r.finishSeconds}`;
    assertEquals(r.verdict, e.verdict, why);
    for (const f of e.flags) assert(r.flags.includes(f), `missing ${f}: ${why}`);
    if (e.verdict === "verified") assertEquals(r.flags, [], why);
    if (e.distance_m) {
      assert(r.distanceM >= e.distance_m[0] && r.distanceM <= e.distance_m[1], why);
    }
    if (e.finish_seconds) {
      assert(r.finishSeconds != null, why);
      assert(r.finishSeconds! >= e.finish_seconds[0] && r.finishSeconds! <= e.finish_seconds[1], why);
    } else if (e.verdict === "verified") {
      assertEquals(r.finishSeconds, null, why);
    }
  });
}

Deno.test("matches the golden results shared with the app analyser", () => {
  const golden = JSON.parse(Deno.readTextFileSync(new URL("golden.json", dir))).results;
  assertEquals(Object.keys(golden).sort(), files);
  for (const name of files) {
    const trace = JSON.parse(Deno.readTextFileSync(new URL(name, dir)));
    const r = analyseRun(trace.points, trace.target_m ?? null);
    const g = golden[name];
    assertEquals(r.verdict, g.verdict, name);
    assertEquals(r.flags, g.flags, name);
    assertAlmostEquals(r.distanceM, g.distance_m, 0.5, name);
    if (g.finish_seconds == null) assertEquals(r.finishSeconds, null, name);
    else assertAlmostEquals(r.finishSeconds!, g.finish_seconds, 0.05, name);
  }
});

Deno.test("haversine matches a known distance", () => {
  assertAlmostEquals(haversineM(26, 80, 27, 80), 111195, 50);
});

Deno.test("finish time is interpolated inside the crossing step", () => {
  const pts: TrackPoint[] = Array.from({ length: 61 }, (_, i) => ({
    t: i * 2000,
    lat: 26 + (i * 10) / 111195,
    lon: 80,
    acc: 5,
  }));
  const r = analyseRun(pts, 105);
  assertAlmostEquals(r.finishSeconds!, 21, 0.1);
  assertEquals(r.verdict, "verified");
});
