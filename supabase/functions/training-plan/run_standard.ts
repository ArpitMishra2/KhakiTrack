// Picks the official run standard for a candidate, mirroring the app's
// runStandardFor (app/lib/data/standards_logic.dart): rows for other age
// bands are ignored, then the candidate's own relaxed category if the exam
// has one, then the all-candidates row, then the exam's default category.

export interface RunRow {
  category: string;
  event: string;
  value: number | string | null;
  age_min: number | null;
  age_max: number | null;
}

export function ageOn(dateOfBirth: string, today: string): number {
  const dob = new Date(dateOfBirth), t = new Date(today);
  let age = t.getFullYear() - dob.getFullYear();
  if (t.getMonth() < dob.getMonth() || (t.getMonth() === dob.getMonth() && t.getDate() < dob.getDate())) {
    age--;
  }
  return age;
}

export function pickRunStandard(
  rows: RunRow[],
  socialCategory: string | null,
  age: number,
): { metres: number; seconds: number } | null {
  const inBand = rows.filter((r) =>
    r.event.startsWith("run_") && r.value != null &&
    (r.age_min == null || age >= r.age_min) &&
    (r.age_max == null || age <= r.age_max)
  );
  const has = (c: string) => inBand.some((r) => r.category === c);
  const own = (socialCategory === "sc" || socialCategory === "st") && has("sc_st")
    ? "sc_st"
    : socialCategory === "st" && has("st")
    ? "st"
    : "";
  for (const c of [own, "all", "general", "general_obc_sc"]) {
    const row = inBand.find((r) => r.category === c);
    if (row) return { metres: Number(row.event.slice(4, -1)), seconds: Number(row.value) };
  }
  return null;
}
