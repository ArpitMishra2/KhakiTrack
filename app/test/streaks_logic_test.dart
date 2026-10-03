import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/data/streaks_logic.dart';
import 'package:maidan/data/training_models.dart';
import 'package:maidan/gps/run_repository.dart';

GpsRunSummary run(
  DateTime at, {
  String verdict = 'verified',
  String mode = 'free',
  double metres = 3000,
  double? finish,
}) => GpsRunSummary(
  mode: mode,
  startedAt: at,
  distanceM: metres,
  durationS: 1200,
  finishSeconds: finish,
  targetM: null,
  verdict: verdict,
);

SessionLog log(DateTime at, {String status = 'done'}) => SessionLog(
  week: 1,
  sessionIndex: 0,
  status: status,
  loggedAt: at,
);

void main() {
  final today = DateTime(2026, 10, 7, 9); // a Wednesday

  test('only verified runs and non-missed sessions count', () {
    final days = activityDays(
      [
        log(DateTime(2026, 10, 6, 18)),
        log(DateTime(2026, 10, 5), status: 'missed'),
      ],
      [
        run(DateTime(2026, 10, 4, 6)),
        run(DateTime(2026, 10, 3), verdict: 'rejected'),
      ],
    );
    expect(days, {DateTime(2026, 10, 6), DateTime(2026, 10, 4)});
  });

  test('streak survives while today is still open', () {
    final days = {
      DateTime(2026, 10, 4),
      DateTime(2026, 10, 5),
      DateTime(2026, 10, 6),
    };
    expect(computeStreak(days, today).current, 3);
    days.add(DateTime(2026, 10, 7));
    expect(computeStreak(days, today).current, 4);
  });

  test('streak breaks after a missed day and best is remembered', () {
    final days = {
      DateTime(2026, 9, 1),
      DateTime(2026, 9, 2),
      DateTime(2026, 9, 3),
      DateTime(2026, 9, 4),
      DateTime(2026, 10, 5),
    };
    final s = computeStreak(days, today);
    expect(s.current, 0);
    expect(s.best, 4);
    expect(computeStreak({}, today).best, 0);
  });

  test('week dots start on Monday', () {
    final dots = weekDots({
      DateTime(2026, 10, 5),
      DateTime(2026, 10, 7),
    }, today);
    expect(dots, [true, false, true, false, false, false, false]);
  });

  test('badges', () {
    final runs = [
      run(DateTime(2026, 10, 6, 5, 30), mode: 'mock_pet', finish: 1400),
      run(DateTime(2026, 9, 1, 17), metres: 48000),
    ];
    final days = {
      ...activityDays(const [], runs),
      DateTime(2026, 10, 7),
    };
    final b = computeBadges(days, runs, today, targetSeconds: 1440);
    expect(b.earned, containsAll([
      BadgeKind.earlyBird,
      BadgeKind.comeback,
      BadgeKind.qualified,
      BadgeKind.km50,
    ]));
    expect(b.earned, isNot(contains(BadgeKind.streak3)));
    expect(
      computeBadges(days, runs, today, targetSeconds: 1000).earned,
      isNot(contains(BadgeKind.qualified)),
    );
  });

  test('a 7 day run earns the streak badges', () {
    final days = {for (var i = 1; i <= 7; i++) DateTime(2026, 10, i)};
    final b = computeBadges(days, const [], today, targetSeconds: 1440);
    expect(b.earned, containsAll([BadgeKind.streak3, BadgeKind.streak7]));
    expect(b.earned, isNot(contains(BadgeKind.streak30)));
  });
}
