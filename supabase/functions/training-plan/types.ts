import { z } from "zod";

// ---------------------------------------------------------------------------
// Questionnaire answers, sent by the app. Untrusted input: validated here.
// ---------------------------------------------------------------------------

export const Answers = z.object({
  // Can they run the full exam distance today without stopping?
  can_complete_distance: z.boolean(),
  // Their current time for the full distance, if they can complete it.
  current_time_seconds: z.number().int().min(60).max(7200).nullable(),
  // Otherwise, the longest distance they can run without stopping.
  longest_continuous_km: z.number().min(0).max(42).nullable(),
  running_experience: z.enum(["none", "lt3m", "3to12m", "gt1y"]),
  runs_per_week: z.number().int().min(0).max(14),
  weekly_km: z.number().min(0).max(150),
  background: z
    .array(z.enum(["farm_labour", "sports", "gym", "none"]))
    .max(4),
  days_per_week: z.number().int().min(3).max(6),
  minutes_per_session: z.number().int().min(20).max(120),
  weeks_to_pet: z.number().int().min(2).max(26),
  training_time: z.enum(["morning", "evening", "either"]),
  surface: z.enum(["ground", "road", "track", "mixed"]),
  pain: z
    .array(z.enum(["none", "knee", "shin", "ankle", "back", "other"]))
    .max(6),
  pain_note: z.string().max(200).nullable(),
  medical: z
    .array(z.enum(["none", "asthma", "heart", "bp", "diabetes", "other"]))
    .max(6),
  weight_kg: z.number().min(30).max(200).nullable(),
  height_cm: z.number().min(120).max(230).nullable(),
}).refine(
  (a) => a.can_complete_distance ? a.current_time_seconds != null : a.longest_continuous_km != null,
  { message: "current_time_seconds or longest_continuous_km is required" },
);
export type Answers = z.infer<typeof Answers>;

export const hasPain = (a: Answers) => a.pain.some((p) => p !== "none");
export const hasMedical = (a: Answers) => a.medical.some((m) => m !== "none");
export const isBeginner = (a: Answers) =>
  a.running_experience === "none" || a.running_experience === "lt3m" ||
  !a.can_complete_distance;

// ---------------------------------------------------------------------------
// What the model returns. Zod validates shape; validate.ts checks the safety
// rules. JSON schemas below are sent as output_config.format (no numeric
// constraints there: the API does not support them, so ranges live in Zod).
// ---------------------------------------------------------------------------

export const SESSION_TYPES = [
  "easy_run",
  "run_walk",
  "long_run",
  "tempo",
  "intervals",
  "time_trial",
  "strength",
  "mobility",
] as const;
export const HARD_TYPES = new Set(["tempo", "intervals", "time_trial"]);
export const RUN_TYPES = new Set([
  "easy_run",
  "run_walk",
  "long_run",
  "tempo",
  "intervals",
  "time_trial",
]);

export const Session = z.object({
  day: z.number().int().min(1).max(7),
  type: z.enum(SESSION_TYPES),
  title: z.string().min(1).max(200),
  details: z.string().min(1).max(1500),
  distance_km: z.number().min(0).max(42).nullable(),
  duration_min: z.number().min(0).max(240).nullable(),
  target_pace_sec_per_km: z.number().min(150).max(900).nullable(),
});
export type Session = z.infer<typeof Session>;

export const WeekDetail = z.object({
  week: z.number().int().min(1),
  sessions: z.array(Session).min(1).max(7),
  coach_note: z.string().max(1000),
});
export type WeekDetail = z.infer<typeof WeekDetail>;

export const WeekOutline = z.object({
  week: z.number().int().min(1),
  focus: z.string().min(1).max(400),
  weekly_km: z.number().min(0).max(120),
  hard_sessions: z.number().int().min(0).max(3),
  is_recovery_week: z.boolean(),
});
export type WeekOutline = z.infer<typeof WeekOutline>;

export const PlanOutline = z.object({
  assessment: z.string().min(1).max(2000),
  readiness: z.enum(["on_track", "needs_work", "big_gap"]),
  goal_note: z.string().min(1).max(800),
  phases: z
    .array(z.object({
      name: z.string().min(1).max(120),
      from_week: z.number().int().min(1),
      to_week: z.number().int().min(1),
      focus: z.string().min(1).max(400),
    }))
    .min(1)
    .max(6),
  weeks: z.array(WeekOutline).min(2).max(26),
  first_weeks: z.array(WeekDetail).min(1).max(2),
  safety_notes: z.array(z.string().max(400)).max(6),
  see_doctor_first: z.boolean(),
});
export type PlanOutline = z.infer<typeof PlanOutline>;

const sessionSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "day",
    "type",
    "title",
    "details",
    "distance_km",
    "duration_min",
    "target_pace_sec_per_km",
  ],
  properties: {
    day: { type: "integer", description: "Day of the week, 1-7, relative to the plan start day" },
    type: { type: "string", enum: [...SESSION_TYPES] },
    title: { type: "string", description: "Short name, max 80 characters" },
    details: {
      type: "string",
      description: "Exactly what to do: warm-up, main set, cool-down. Max 600 characters.",
    },
    distance_km: { type: ["number", "null"], description: "Total running distance in km, null for strength/mobility" },
    duration_min: { type: ["number", "null"], description: "Total session time in minutes" },
    target_pace_sec_per_km: {
      type: ["number", "null"],
      description: "Target pace for the main running part in seconds per km, null if not a paced run",
    },
  },
};

const weekDetailSchema = {
  type: "object",
  additionalProperties: false,
  required: ["week", "sessions", "coach_note"],
  properties: {
    week: { type: "integer" },
    sessions: { type: "array", items: sessionSchema },
    coach_note: { type: "string", description: "One or two encouraging, practical sentences for this week. Max 400 characters." },
  },
};

export const planOutlineJsonSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "assessment",
    "readiness",
    "goal_note",
    "phases",
    "weeks",
    "first_weeks",
    "safety_notes",
    "see_doctor_first",
  ],
  properties: {
    assessment: { type: "string", description: "Where the candidate stands now against the official requirement. 2-4 sentences, max 800 characters." },
    readiness: { type: "string", enum: ["on_track", "needs_work", "big_gap"] },
    goal_note: { type: "string", description: "The time they will aim for by the final week, and why. Max 300 characters." },
    phases: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["name", "from_week", "to_week", "focus"],
        properties: {
          name: { type: "string" },
          from_week: { type: "integer" },
          to_week: { type: "integer" },
          focus: { type: "string" },
        },
      },
    },
    weeks: {
      type: "array",
      description: "One entry per week of the plan, in order",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["week", "focus", "weekly_km", "hard_sessions", "is_recovery_week"],
        properties: {
          week: { type: "integer" },
          focus: { type: "string", description: "Max 160 characters" },
          weekly_km: { type: "number", description: "Total running km planned for the week" },
          hard_sessions: { type: "integer", description: "Number of tempo/interval/time-trial sessions" },
          is_recovery_week: { type: "boolean" },
        },
      },
    },
    first_weeks: {
      type: "array",
      description: "Full session detail for weeks 1 and 2",
      items: weekDetailSchema,
    },
    safety_notes: { type: "array", items: { type: "string" } },
    see_doctor_first: { type: "boolean" },
  },
};

export const weekDetailJsonSchema = weekDetailSchema;
