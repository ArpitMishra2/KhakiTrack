import '../gps/run_repository.dart';
import 'training_models.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Days on which the user trained: a logged session (done or partial) or a
/// GPS run that passed the check. Missed sessions and rejected runs do not count.
Set<DateTime> activityDays(List<SessionLog> logs, List<GpsRunSummary> runs) => {
  for (final l in logs)
    if (l.status != 'missed' && l.loggedAt != null) _day(l.loggedAt!),
  for (final r in runs)
    if (r.verdict == 'verified') _day(r.startedAt),
};

class Streak {
  const Streak({required this.current, required this.best});

  final int current;
  final int best;
}

/// Current streak counts back from today, or from yesterday when today has no
/// activity yet (the day is not over, so the streak is not broken).
Streak computeStreak(Set<DateTime> days, DateTime today) {
  final t = _day(today);
  var current = 0;
  var cursor = days.contains(t) ? t : DateTime(t.year, t.month, t.day - 1);
  while (days.contains(cursor)) {
    current++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  var best = 0;
  final sorted = days.toList()..sort();
  var run = 0;
  DateTime? prev;
  for (final d in sorted) {
    run = prev != null && DateTime(prev.year, prev.month, prev.day + 1) == d
        ? run + 1
        : 1;
    if (run > best) best = run;
    prev = d;
  }
  return Streak(current: current, best: best);
}

/// Seven flags, Monday first, for the week containing [today].
List<bool> weekDots(Set<DateTime> days, DateTime today) {
  final t = _day(today);
  final monday = DateTime(t.year, t.month, t.day - (t.weekday - 1));
  return [
    for (var i = 0; i < 7; i++)
      days.contains(DateTime(monday.year, monday.month, monday.day + i)),
  ];
}

enum BadgeKind {
  earlyBird, // verified run started between 4:00 and 6:59
  comeback, // trained again after 3+ days off
  streak3,
  streak7,
  streak30,
  qualified, // verified mock PET inside the target
  km50, // 50 km of verified GPS running
}

class BadgeStats {
  const BadgeStats(this.earned, {required this.totalKm});

  final Set<BadgeKind> earned;
  final double totalKm;
}

BadgeStats computeBadges(
  Set<DateTime> days,
  List<GpsRunSummary> runs,
  DateTime today, {
  required num targetSeconds,
}) {
  final earned = <BadgeKind>{};
  final verified = runs.where((r) => r.verdict == 'verified').toList();
  final km = verified.fold<double>(0, (s, r) => s + r.distanceM) / 1000;

  if (verified.any((r) => r.startedAt.hour >= 4 && r.startedAt.hour < 7)) {
    earned.add(BadgeKind.earlyBird);
  }
  if (verified.any(
    (r) =>
        r.mode == 'mock_pet' &&
        r.finishSeconds != null &&
        r.finishSeconds! <= targetSeconds,
  )) {
    earned.add(BadgeKind.qualified);
  }
  final sorted = days.toList()..sort();
  for (var i = 1; i < sorted.length; i++) {
    if (sorted[i].difference(sorted[i - 1]).inDays >= 4) {
      earned.add(BadgeKind.comeback);
    }
  }
  final best = computeStreak(days, today).best;
  if (best >= 3) earned.add(BadgeKind.streak3);
  if (best >= 7) earned.add(BadgeKind.streak7);
  if (best >= 30) earned.add(BadgeKind.streak30);
  if (km >= 50) earned.add(BadgeKind.km50);
  return BadgeStats(earned, totalKm: km);
}
