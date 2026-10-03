import { assertEquals } from "@std/assert";

import { ageOn, pickRunStandard, type RunRow } from "./run_standard.ts";

const dir = new URL("../../../data/exams/", import.meta.url);
const rows = (exam: string, gender: string): RunRow[] =>
  JSON.parse(Deno.readTextFileSync(new URL(`${exam}.json`, dir))).standards
    .filter((s: { gender: string; verified: boolean }) => s.gender === gender && s.verified)
    .map((s: RunRow) => ({ ...s, age_min: s.age_min ?? null, age_max: s.age_max ?? null }));

Deno.test("age in completed years", () => {
  assertEquals(ageOn("2000-10-04", "2030-10-03"), 29);
  assertEquals(ageOn("2000-10-03", "2030-10-03"), 30);
});

Deno.test("Delhi Police run time follows the age band", () => {
  const men = rows("delhi_police_constable", "male");
  assertEquals(pickRunStandard(men, "general", 22), { metres: 1600, seconds: 360 });
  assertEquals(pickRunStandard(men, "general", 35), { metres: 1600, seconds: 420 });
  assertEquals(pickRunStandard(men, "obc", 45), { metres: 1600, seconds: 480 });
  const women = rows("delhi_police_constable", "female");
  assertEquals(pickRunStandard(women, "sc", 25), { metres: 1600, seconds: 480 });
});

Deno.test("UP Police and SSC GD are unchanged", () => {
  assertEquals(pickRunStandard(rows("up_police_constable", "male"), "st", 20), { metres: 4800, seconds: 1500 });
  assertEquals(pickRunStandard(rows("up_police_constable", "female"), null, 20), { metres: 2400, seconds: 840 });
  assertEquals(pickRunStandard(rows("ssc_gd", "male"), "general", 20), { metres: 5000, seconds: 1440 });
  assertEquals(pickRunStandard(rows("ssc_gd", "female"), "obc", 20), { metres: 1600, seconds: 510 });
});

Deno.test("Agniveer men have the sourced 1.6 km limit, women have none", () => {
  assertEquals(pickRunStandard(rows("agniveer_army_gd", "male"), "general", 19), { metres: 1600, seconds: 375 });
  // Agniveer Women (Military Police) is a different notice and is not loaded.
  assertEquals(pickRunStandard(rows("agniveer_army_gd", "female"), "general", 19), null);
});

Deno.test("an unverified row gives no run standard", () => {
  const unverified = [{ category: "all", event: "run_1600m", value: null, age_min: null, age_max: null }];
  assertEquals(pickRunStandard(unverified as RunRow[], "general", 19), null);
});
