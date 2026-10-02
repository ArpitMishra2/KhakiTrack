import {
  type Answers,
  hasMedical,
  hasPain,
  isBeginner,
  type PlanOutline,
  type WeekDetail,
} from "./types.ts";
import { maxFirstWeekKm, maxHardSessions } from "./validate.ts";

export interface Candidate {
  examName: string;
  gender: "male" | "female";
  age: number;
  runDistanceM: number;
  targetSeconds: number;
  language: "hi" | "en";
}

// Stable across requests (no per-user data) so it can be cached.
export const SYSTEM_PROMPT = `You are an experienced running coach who prepares candidates for the physical efficiency test (PET) of Indian police and paramilitary recruitment, such as UP Police Constable and SSC GD. Your candidates are mostly young people from small towns and villages in Uttar Pradesh. They train on village grounds, roads and school fields, often in heat, usually without a watch or coach, and many do hard physical work during the day.

Your job is to write a personal, week-by-week running plan that takes this candidate from where they are today to finishing the official PET distance comfortably inside the qualifying time by the final week. Aim for a finishing time a little under the cut-off, so that a bad day on test day still qualifies.

How you coach:
- Start from the candidate's real level. Someone who cannot yet run the full distance starts with run-walk and builds continuous running before any speed work. An experienced runner can start with structured sessions straight away.
- Most running is easy and conversational. Speed work (intervals, tempo, time trials) is at most what the rules below allow, never on back-to-back days.
- Increase load gradually and include a lighter recovery week every 3 to 4 weeks. Make the final week before the PET a lighter taper week.
- Put a time trial over the PET distance (or a shorter test distance for beginners) every 2 to 3 weeks once the candidate can run continuously, so progress is measured.
- Include short no-equipment strength and mobility work (squats, lunges, calf raises, planks, stretching) for injury prevention, within the candidate's days.
- Give paces in seconds per km where it helps, but also describe effort in plain words (for example: you can still talk, or you can only say a few words), because most candidates have no watch.
- Every session lists warm-up, main set and cool-down in the details.
- Every time, distance or pace you write inside details must be realistic for this candidate and match the session's distance_km and duration_min. A beginner runs 400 m in about 2 to 3 minutes, not 30 seconds; nobody in this group runs faster than about 3:30 per km.
- If the candidate reports pain, keep the first weeks gentle, avoid hard sessions, and tell them in safety_notes to stop and see a doctor if pain gets worse. If they report a medical condition such as asthma, heart trouble or high blood pressure, set see_doctor_first to true and keep the plan conservative.
- Practical advice for their setting is welcome: train in the cooler morning or evening, drink water, wear proper shoes, run on soft ground when possible.
- Never promise selection. Be encouraging and honest.

Tone: you are the funny, warm "bade bhaiya" coach from the village ground. Candidates should smile every time they read your plan. Put light, kind humour into the assessment, goal_note, phase names, session titles and coach notes: playful desi comparisons (chai, cricket, the neighbour's buffalo, a famous filmy dialogue now and then), gentle teasing about lazy mornings, and big cheering for effort. Keep jokes short and never let them hide the instruction; the details of each session stay clear and exact. Never joke about the candidate's body, weight, caste, religion, gender, money or family, and never make fun of failing. Safety notes, pain and medical advice are always plain and serious, with no jokes.

Talk to the candidate directly, never about them in the third person. In Hindi use the friendly "तुम", the way a big brother talks. Every assessment, goal_note and coach_note should have at least one line that makes them grin. Examples of the tone (do not copy them, write your own):
- "अभी 1 किमी में साँस फूलती है? कोई बात नहीं, धोनी ने भी पहले ही दिन छक्का नहीं मारा था।"
- "इस हफ्ते आलस को छुट्टी दे दो, अलार्म को नहीं।"
- "हफ्ता 3: टांगें पूछेंगी 'भाई, ये क्या हो रहा है?' जवाब दो: 'PET की तैयारी!'"

Writing style: short, simple, practical sentences. Write every text field in the language you are told to use. For Hindi, write everyday Devanagari Hindi that a 12th-pass candidate understands, keeping common English running words where they are natural (for example: वार्म-अप, इंटरवल, टाइम ट्रायल).

The plan must obey every rule listed in the request exactly. Plans that break a rule are rejected.`;

const fmtTime = (s: number) => `${Math.floor(s / 60)} min ${Math.round(s % 60)} s`;

function describeCandidate(c: Candidate, a: Answers): string {
  const km = c.runDistanceM / 1000;
  const lines = [
    `Exam: ${c.examName}. Official PET: run ${km} km within ${fmtTime(c.targetSeconds)} (${c.targetSeconds} seconds; goal pace ${Math.round(c.targetSeconds / km)} s/km).`,
    `Candidate: ${c.gender}, age ${c.age}${a.height_cm ? `, height ${a.height_cm} cm` : ""}${a.weight_kg ? `, weight ${a.weight_kg} kg` : ""}.`,
    a.can_complete_distance
      ? `Can run the full ${km} km now in ${fmtTime(a.current_time_seconds!)} (${a.current_time_seconds} seconds).`
      : `Cannot yet run the full ${km} km. Longest continuous run today: ${a.longest_continuous_km} km.`,
    `Running experience: ${{ none: "never trained regularly", lt3m: "less than 3 months", "3to12m": "3 to 12 months", gt1y: "more than a year" }[a.running_experience]}. Currently runs ${a.runs_per_week} times a week, about ${a.weekly_km} km a week.`,
    `Other physical background: ${a.background.join(", ") || "none"}.`,
    `Available: ${a.days_per_week} days a week, up to ${a.minutes_per_session} minutes a session, prefers ${a.training_time}. Trains on: ${a.surface}.`,
    `Pain or injury: ${hasPain(a) ? a.pain.filter((p) => p !== "none").join(", ") : "none"}${a.pain_note ? ` (candidate's words: "${a.pain_note}")` : ""}.`,
    `Medical conditions: ${hasMedical(a) ? a.medical.filter((m) => m !== "none").join(", ") : "none"}.`,
  ];
  return lines.join("\n");
}

function rules(c: Candidate, a: Answers, weeksTotal: number): string {
  const hardRule = (hasPain(a) || hasMedical(a))
    ? "0 hard sessions in weeks 1-2, then at most " + (isBeginner(a) ? "1" : "2") + " per week"
    : isBeginner(a)
    ? "0 hard sessions in weeks 1-2, then at most 1 per week"
    : "at most 2 hard sessions per week";
  return [
    `- The plan has exactly ${weeksTotal} weeks, numbered 1 to ${weeksTotal}. Phases cover weeks 1-${weeksTotal} in order with no gaps.`,
    `- Week 1 total running is at most ${Math.round(maxFirstWeekKm(a) * 10) / 10} km.`,
    `- Each week's weekly_km is at most 15% plus 1.5 km above the highest earlier week.`,
    `- Hard sessions (tempo, intervals, time_trial): ${hardRule}; never on back-to-back days; at most one time_trial per week.`,
    `- Each week uses at most ${a.days_per_week} different days (day 1-7) and always keeps at least one full rest day. One session per day.`,
    `- No session longer than ${a.minutes_per_session + 15} minutes.`,
    `- Every running session (easy_run, run_walk, long_run, tempo, intervals, time_trial) has distance_km. The running sessions of a week add up to within 60-130% of that week's weekly_km.`,
    `- Week ${weeksTotal} is a taper week ending in readiness for the PET.`,
    hasMedical(a) ? "- see_doctor_first must be true." : "",
    `- Write all text in ${c.language === "hi" ? "Hindi (Devanagari)" : "English"}.`,
  ].filter(Boolean).join("\n");
}

export function outlineRequest(c: Candidate, a: Answers, weeksTotal: number): string {
  return `Create the training plan for this candidate.

${describeCandidate(c, a)}

Rules:
${rules(c, a, weeksTotal)}

Return the assessment, the phases, an outline for every week, and full session detail for weeks 1 and 2 in first_weeks.`;
}

export interface WeekHistory {
  week: number;
  sessions: WeekDetail["sessions"];
  logs: Array<{
    session_index: number;
    status: string;
    distance_km: number | null;
    duration_seconds: number | null;
    effort: number | null;
    pain: boolean;
    note: string | null;
  }>;
}

export function nextWeekRequest(
  c: Candidate,
  a: Answers,
  outline: PlanOutline,
  weekNumber: number,
  history: WeekHistory[],
  latestTrial: { distance_m: number; duration_seconds: number; recorded_on: string } | null,
): string {
  const target = outline.weeks.find((w) => w.week === weekNumber)!;
  const recent = history.slice(-3).map((h) => {
    const rows = h.sessions.map((s, i) => {
      const log = h.logs.find((l) => l.session_index === i);
      const done = log
        ? `${log.status}${log.distance_km != null ? `, ran ${log.distance_km} km` : ""}${log.duration_seconds != null ? ` in ${fmtTime(log.duration_seconds)}` : ""}${log.effort != null ? `, effort ${log.effort}/5` : ""}${log.pain ? ", REPORTED PAIN" : ""}${log.note ? `, note: "${log.note}"` : ""}`
        : "not logged";
      return `  day ${s.day} ${s.type} ${s.distance_km ?? "-"} km: ${done}`;
    });
    return `Week ${h.week}:\n${rows.join("\n")}`;
  }).join("\n");

  return `Write the full sessions for week ${weekNumber} of this candidate's plan, adjusted to how the last weeks actually went.

${describeCandidate(c, a)}

Plan so far: ${outline.assessment}
Goal: ${outline.goal_note}
Outline for week ${weekNumber}: focus "${target.focus}", about ${target.weekly_km} km, ${target.hard_sessions} hard sessions${target.is_recovery_week ? ", recovery week" : ""}.

What the candidate logged recently:
${recent || "Nothing logged yet."}
${latestTrial ? `Latest time trial: ${latestTrial.distance_m} m in ${fmtTime(latestTrial.duration_seconds)} on ${latestTrial.recorded_on}.` : "No time trial recorded yet."}

Adjust to the logs: if sessions were missed, effort was very high or pain was reported, make this week easier than the outline; if everything was done comfortably, follow the outline. Never exceed the outline's weekly_km or hard sessions.

Rules:
- week is ${weekNumber}.
- Hard sessions (tempo, intervals, time_trial): at most ${Math.min(target.hard_sessions, maxHardSessions(a, weekNumber))}; never on back-to-back days; at most one time_trial.
- At most ${a.days_per_week} different days (day 1-7), at least one full rest day, one session per day.
- No session longer than ${a.minutes_per_session + 15} minutes.
- Every running session has distance_km; running sessions add up to within 60-130% of ${target.weekly_km} km.
- Write all text in ${c.language === "hi" ? "Hindi (Devanagari)" : "English"}.
- coach_note tells the candidate in one or two sentences how this week builds on the last.`;
}
