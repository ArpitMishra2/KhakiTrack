// Hard safety rules every AI-generated plan must pass before it is saved.
// Pure functions, unit-tested in validate_test.ts.

import {
  type Answers,
  HARD_TYPES,
  hasMedical,
  hasPain,
  isBeginner,
  type PlanOutline,
  RUN_TYPES,
  type WeekDetail,
  type WeekOutline,
} from "./types.ts";

/** Most a week's running volume may grow over the week before. */
export const maxNextWeekKm = (prevKm: number) => prevKm * 1.15 + 1.5;

/** Most week 1 may hold, from what the candidate runs today. */
export function maxFirstWeekKm(a: Answers): number {
  const base = Math.max(a.weekly_km, a.longest_continuous_km ?? 0);
  return base * 1.25 + 4;
}

/** Hard sessions allowed in a given week. */
export function maxHardSessions(a: Answers, week: number): number {
  if ((hasPain(a) || hasMedical(a)) && week <= 2) return 0;
  if (isBeginner(a)) return week <= 2 ? 0 : 1;
  return 2;
}

export function validateOutline(
  o: PlanOutline,
  a: Answers,
  weeksTotal: number,
): string[] {
  const errors: string[] = [];

  if (o.weeks.length !== weeksTotal) {
    errors.push(`weeks must have exactly ${weeksTotal} entries, got ${o.weeks.length}`);
  }
  o.weeks.forEach((w, i) => {
    if (w.week !== i + 1) errors.push(`weeks[${i}].week must be ${i + 1}, got ${w.week}`);
  });

  // Phases must cover 1..N without gaps or overlaps.
  let expected = 1;
  for (const p of [...o.phases].sort((x, y) => x.from_week - y.from_week)) {
    if (p.from_week !== expected || p.to_week < p.from_week) {
      errors.push(`phases must cover weeks 1-${weeksTotal} in order without gaps; problem at "${p.name}"`);
      break;
    }
    expected = p.to_week + 1;
  }
  if (expected !== weeksTotal + 1 && errors.length === 0) {
    errors.push(`phases must end at week ${weeksTotal}`);
  }

  errors.push(...checkVolumes(o.weeks, a));

  for (const w of o.weeks) {
    const max = maxHardSessions(a, w.week);
    if (w.hard_sessions > max) {
      errors.push(`week ${w.week}: ${w.hard_sessions} hard sessions, at most ${max} allowed for this candidate`);
    }
  }

  if (o.first_weeks.length < Math.min(2, weeksTotal)) {
    errors.push("first_weeks must give full detail for weeks 1 and 2");
  }
  o.first_weeks.forEach((d, i) => {
    if (d.week !== i + 1) errors.push(`first_weeks[${i}].week must be ${i + 1}`);
    const outline = o.weeks.find((w) => w.week === d.week);
    if (outline) errors.push(...validateWeek(d, outline, a));
  });

  if (hasMedical(a) && !o.see_doctor_first) {
    errors.push("see_doctor_first must be true: the candidate reported a medical condition");
  }
  return errors;
}

function checkVolumes(weeks: WeekOutline[], a: Answers): string[] {
  const errors: string[] = [];
  const first = weeks[0];
  if (first && first.weekly_km > maxFirstWeekKm(a)) {
    errors.push(
      `week 1 weekly_km ${first.weekly_km} is too big a jump from the candidate's current ${a.weekly_km} km/week; at most ${round1(maxFirstWeekKm(a))}`,
    );
  }
  // Compare with the highest earlier week, so a recovery week does not reset
  // the base and allow a big jump after it.
  let peak = first?.weekly_km ?? 0;
  for (let i = 1; i < weeks.length; i++) {
    const w = weeks[i];
    if (w.weekly_km > maxNextWeekKm(peak)) {
      errors.push(
        `week ${w.week} weekly_km ${w.weekly_km} rises too fast; at most ${round1(maxNextWeekKm(peak))} after a previous peak of ${peak}`,
      );
    }
    peak = Math.max(peak, w.weekly_km);
  }
  return errors;
}

/** Rules for one fully detailed week. */
export function validateWeek(
  d: WeekDetail,
  outline: WeekOutline,
  a: Answers,
): string[] {
  const errors: string[] = [];
  const p = `week ${d.week}`;

  const days = d.sessions.map((s) => s.day);
  if (new Set(days).size !== days.length) errors.push(`${p}: two sessions on the same day`);
  if (new Set(days).size > a.days_per_week) {
    errors.push(`${p}: uses ${new Set(days).size} days, the candidate can train ${a.days_per_week} days`);
  }
  if (new Set(days).size >= 7) errors.push(`${p}: needs at least one full rest day`);

  const hard = d.sessions.filter((s) => HARD_TYPES.has(s.type)).length;
  const maxHard = Math.min(outline.hard_sessions, maxHardSessions(a, d.week));
  if (hard > maxHard) errors.push(`${p}: ${hard} hard sessions, at most ${maxHard}`);

  // No two hard days in a row.
  const hardDays = d.sessions.filter((s) => HARD_TYPES.has(s.type)).map((s) => s.day).sort();
  for (let i = 1; i < hardDays.length; i++) {
    if (hardDays[i] - hardDays[i - 1] < 2) errors.push(`${p}: hard sessions on back-to-back days`);
  }

  if (d.sessions.filter((s) => s.type === "time_trial").length > 1) {
    errors.push(`${p}: at most one time trial per week`);
  }

  for (const s of d.sessions) {
    if (s.duration_min != null && s.duration_min > a.minutes_per_session + 15) {
      errors.push(`${p} day ${s.day}: ${s.duration_min} min is longer than the candidate's ${a.minutes_per_session} min`);
    }
    if (RUN_TYPES.has(s.type) && s.distance_km == null) {
      errors.push(`${p} day ${s.day}: running session needs distance_km`);
    }
  }

  const km = d.sessions
    .filter((s) => RUN_TYPES.has(s.type))
    .reduce((sum, s) => sum + (s.distance_km ?? 0), 0);
  if (outline.weekly_km > 0 && (km < outline.weekly_km * 0.6 || km > outline.weekly_km * 1.3)) {
    errors.push(`${p}: sessions add up to ${round1(km)} km but the outline says ${outline.weekly_km} km`);
  }
  return errors;
}

const round1 = (n: number) => Math.round(n * 10) / 10;
