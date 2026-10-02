import { assert, assertEquals } from "@std/assert";

import type { Answers, PlanOutline, Session, WeekDetail } from "./types.ts";
import { maxFirstWeekKm, maxHardSessions, validateOutline, validateWeek } from "./validate.ts";

export const fitAnswers: Answers = {
  can_complete_distance: true,
  current_time_seconds: 1740,
  longest_continuous_km: null,
  running_experience: "3to12m",
  runs_per_week: 3,
  weekly_km: 12,
  background: ["farm_labour"],
  days_per_week: 5,
  minutes_per_session: 60,
  weeks_to_pet: 4,
  training_time: "morning",
  surface: "ground",
  pain: ["none"],
  pain_note: null,
  medical: ["none"],
  weight_kg: 62,
  height_cm: 170,
};

export const beginnerAnswers: Answers = {
  ...fitAnswers,
  can_complete_distance: false,
  current_time_seconds: null,
  longest_continuous_km: 1,
  running_experience: "none",
  runs_per_week: 0,
  weekly_km: 0,
};

const s = (day: number, type: Session["type"], km: number | null, min = 40): Session => ({
  day,
  type,
  title: "t",
  details: "d",
  distance_km: km,
  duration_min: min,
  target_pace_sec_per_km: null,
});

export function goodWeek(week: number): WeekDetail {
  return {
    week,
    coach_note: "ok",
    sessions: [
      s(1, "easy_run", 4),
      s(2, "strength", null, 25),
      s(3, "intervals", 4),
      s(5, "easy_run", 4),
      s(6, "long_run", 3),
    ],
  };
}

export function goodOutline(): PlanOutline {
  return {
    assessment: "a",
    readiness: "needs_work",
    goal_note: "g",
    phases: [
      { name: "base", from_week: 1, to_week: 2, focus: "f" },
      { name: "sharpen", from_week: 3, to_week: 4, focus: "f" },
    ],
    weeks: [
      { week: 1, focus: "f", weekly_km: 15, hard_sessions: 1, is_recovery_week: false },
      { week: 2, focus: "f", weekly_km: 16, hard_sessions: 1, is_recovery_week: false },
      { week: 3, focus: "f", weekly_km: 18, hard_sessions: 2, is_recovery_week: false },
      { week: 4, focus: "taper", weekly_km: 12, hard_sessions: 1, is_recovery_week: true },
    ],
    first_weeks: [goodWeek(1), goodWeek(2)],
    safety_notes: [],
    see_doctor_first: false,
  };
}

Deno.test("a sensible plan passes", () => {
  assertEquals(validateOutline(goodOutline(), fitAnswers, 4), []);
});

Deno.test("wrong number of weeks and phase gaps are caught", () => {
  const o = goodOutline();
  o.weeks.pop();
  o.phases[1].from_week = 4;
  const errors = validateOutline(o, fitAnswers, 4);
  assert(errors.some((e) => e.includes("exactly 4 entries")));
  assert(errors.some((e) => e.includes("phases must cover")));
});

Deno.test("volume jumps are caught, including after a recovery week", () => {
  const o = goodOutline();
  o.weeks[0].weekly_km = 40; // from 12 km/week today
  const errors = validateOutline(o, fitAnswers, 4);
  assert(errors.some((e) => e.startsWith("week 1 weekly_km")));

  const o2 = goodOutline();
  o2.weeks[2].weekly_km = 10; // recovery
  o2.weeks[3].weekly_km = 22; // 16 peak * 1.15 + 1.5 = 19.9
  assert(validateOutline(o2, fitAnswers, 4).some((e) => e.startsWith("week 4 weekly_km")));
});

Deno.test("beginners get no hard sessions in weeks 1-2 and at most 1 after", () => {
  assertEquals(maxHardSessions(beginnerAnswers, 1), 0);
  assertEquals(maxHardSessions(beginnerAnswers, 3), 1);
  assertEquals(maxHardSessions(fitAnswers, 1), 2);
  const withPain = { ...fitAnswers, pain: ["knee" as const] };
  assertEquals(maxHardSessions(withPain, 2), 0);
  assertEquals(maxHardSessions(withPain, 3), 2);
});

Deno.test("first week volume for a non-runner stays small", () => {
  assertEquals(maxFirstWeekKm(beginnerAnswers), 1 * 1.25 + 4);
});

Deno.test("medical condition requires see_doctor_first", () => {
  const a = { ...fitAnswers, medical: ["asthma" as const] };
  const o = goodOutline();
  o.first_weeks.forEach((w) => w.sessions = w.sessions.filter((x) => x.type !== "intervals"));
  o.weeks.forEach((w) => (w.week <= 2 ? (w.hard_sessions = 0) : null));
  const errors = validateOutline(o, a, 4);
  assert(errors.some((e) => e.includes("see_doctor_first")));
  o.see_doctor_first = true;
  assertEquals(validateOutline(o, a, 4).filter((e) => e.includes("see_doctor_first")), []);
});

Deno.test("week rules: days, rest day, hard days, duration, volume", () => {
  const outline = goodOutline().weeks[0];
  const tooMany: WeekDetail = {
    ...goodWeek(1),
    sessions: [1, 2, 3, 4, 5, 6, 7].map((d) => s(d, "easy_run", 2)),
  };
  const e1 = validateWeek(tooMany, outline, fitAnswers);
  assert(e1.some((e) => e.includes("can train 5 days")));
  assert(e1.some((e) => e.includes("rest day")));

  const backToBack: WeekDetail = {
    ...goodWeek(1),
    sessions: [s(1, "intervals", 5), s(2, "tempo", 5), s(4, "easy_run", 5)],
  };
  const e2 = validateWeek(backToBack, { ...outline, hard_sessions: 2 }, fitAnswers);
  assert(e2.some((e) => e.includes("back-to-back")));

  const long: WeekDetail = { ...goodWeek(1), sessions: [s(1, "long_run", 15, 120)] };
  assert(validateWeek(long, outline, fitAnswers).some((e) => e.includes("longer than")));

  const tiny: WeekDetail = { ...goodWeek(1), sessions: [s(1, "easy_run", 2)] };
  assert(validateWeek(tiny, outline, fitAnswers).some((e) => e.includes("add up to")));

  const sprint: WeekDetail = { ...goodWeek(1), sessions: [...goodWeek(1).sessions.slice(0, 4), s(6, "long_run", 5, 10)] };
  assert(validateWeek(sprint, outline, fitAnswers).some((e) => e.includes("not realistic")));

  const noKm: WeekDetail = { ...goodWeek(1), sessions: [...goodWeek(1).sessions, s(7, "easy_run", null)] };
  assert(validateWeek(noKm, outline, fitAnswers).some((e) => e.includes("needs distance_km")));
});
