import 'dart:math';

import 'training_models.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Plan week that contains [today], 1-based, clamped to the plan length.
int currentWeek(TrainingPlan plan, DateTime today) {
  final days = _dateOnly(today).difference(_dateOnly(plan.startDate)).inDays;
  return (days ~/ 7 + 1).clamp(1, plan.weeksTotal);
}

/// Calendar date of [day] (1-7) in plan [week].
DateTime sessionDate(TrainingPlan plan, int week, int day) =>
    _dateOnly(plan.startDate).add(Duration(days: (week - 1) * 7 + day - 1));

/// The server unlocks week n two days before it starts (see index.ts).
bool weekUnlocked(TrainingPlan plan, int week, DateTime today) {
  final unlock = _dateOnly(
    plan.startDate,
  ).add(Duration(days: (week - 1) * 7 - 2));
  return !_dateOnly(today).isBefore(unlock);
}

/// The next week that has no sessions yet and may be generated, or null.
int? weekToGenerate(TrainingPlan plan, DateTime today) {
  final next = plan.weeks.isEmpty ? 1 : plan.weeks.keys.reduce(max) + 1;
  if (next > plan.weeksTotal) return null;
  return weekUnlocked(plan, next, today) ? next : null;
}

/// Logged sessions of [week] (done or partial) out of the planned ones.
({int done, int total}) weekProgress(TrainingPlan plan, int week) {
  final sessions = plan.weeks[week]?.sessions ?? const [];
  var done = 0;
  for (var i = 0; i < sessions.length; i++) {
    final s = plan.logFor(week, i)?.status;
    if (s == 'done' || s == 'partial') done++;
  }
  return (done: done, total: sessions.length);
}

/// Riegel's formula: estimated time over [targetM] from a run of [fromM] in
/// [seconds]. Accurate enough for nearby distances; shown as an estimate.
double estimateSeconds(int fromM, int seconds, int targetM) =>
    seconds * pow(targetM / fromM, 1.06).toDouble();

/// Each trial's (estimated) time over the exam distance, oldest first.
List<({DateTime date, double seconds, bool estimated})> trialSeries(
  List<TimeTrial> trials,
  int examDistanceM,
) {
  final sorted = [...trials]
    ..sort((a, b) => a.recordedOn.compareTo(b.recordedOn));
  return [
    for (final t in sorted)
      (
        date: t.recordedOn,
        seconds: t.distanceM == examDistanceM
            ? t.durationSeconds.toDouble()
            : estimateSeconds(t.distanceM, t.durationSeconds, examDistanceM),
        estimated: t.distanceM != examDistanceM,
      ),
  ];
}

/// "m:ss" for a duration in seconds.
String formatDuration(num seconds) {
  final s = seconds.round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Parses "m:ss" or "mm:ss" (or plain minutes) into seconds; null if invalid.
int? parseDuration(String text) {
  final t = text.trim();
  final m = RegExp(r'^(\d{1,3})(?::(\d{1,2}))?$').firstMatch(t);
  if (m == null) return null;
  final minutes = int.parse(m.group(1)!);
  final seconds = m.group(2) == null ? 0 : int.parse(m.group(2)!);
  if (seconds >= 60) return null;
  final total = minutes * 60 + seconds;
  return total == 0 ? null : total;
}
