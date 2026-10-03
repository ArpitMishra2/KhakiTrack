import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/data/app_settings.dart';
import 'package:maidan/data/demo_repositories.dart';
import 'package:maidan/data/streaks_logic.dart';
import 'package:maidan/data/training_models.dart';
import 'package:maidan/gps/run_repository.dart';
import 'package:maidan/main.dart';

import 'fake_auth_service.dart';
import 'fake_exam_repository.dart';
import 'fake_gps.dart';
import 'fake_leaderboard_repository.dart';
import 'fake_profile_repository.dart';
import 'fake_training_repository.dart';

void main() {
  // A fixed "today" so dates are stable.
  final today = DateTime(2026, 10, 3, 10);
  DateTime clock() => today;

  group('demo user story', () {
    final runs = DemoRunRepository(clock: clock);
    final training = DemoTrainingRepository(clock: clock);

    test('runs tell an improving story and are all verified', () async {
      final list = await runs.recentRuns();
      expect(list.length, greaterThanOrEqualTo(8));
      expect(list.every((r) => r.verdict == 'verified'), isTrue);
      final pets = list.where((r) => r.mode == 'mock_pet').toList();
      final times = [for (final r in pets) r.finishSeconds!];
      // Newest first: each mock PET faster than the one before it.
      expect(times, [...times]..sort());
      expect(times.first, 1488); // 24:48, inside the 25:00 target
      expect(times.last, 1740); // 29:00 to start with
    });

    test('streak and badges show off the Progress tab', () async {
      final plan = (await training.fetchActivePlan())!;
      final list = await runs.recentRuns();
      final days = activityDays(plan.logs, list);
      final s = computeStreak(days, today);
      expect(s.current, 5);
      expect(s.best, 8);
      final b = computeBadges(days, list, today, targetSeconds: 1500);
      expect(
        b.earned,
        containsAll([
          BadgeKind.earlyBird,
          BadgeKind.streak3,
          BadgeKind.streak7,
          BadgeKind.qualified,
          BadgeKind.km50,
        ]),
      );
      expect(b.earned, isNot(contains(BadgeKind.streak30)));
    });

    test('the plan is eight weeks, in week three, with logs', () async {
      final plan = (await training.fetchActivePlan())!;
      expect(plan.weeksTotal, 8);
      expect(plan.weeks.keys.toSet(), {1, 2, 3});
      expect(plan.logs.where((l) => l.status == 'done').length, greaterThan(4));
      expect(plan.outline.length, 8);
    });

    test('trial times improve to under the target', () async {
      final t = await training.fetchTimeTrials('up_police_constable');
      final secs = [for (final x in t) x.durationSeconds];
      expect(secs, [1740, 1668, 1590, 1488]);
      expect(secs.last, lessThan(1500));
    });

    test('the plan text follows the app language', () async {
      var lang = 'hi';
      final t = DemoTrainingRepository(language: () => lang, clock: clock);
      expect((await t.fetchActivePlan())!.goalNote, contains('किमी'));
      lang = 'en';
      expect((await t.fetchActivePlan())!.goalNote, contains('under 25'));
    });

    test('logging a session and adding a trial stick (in memory)', () async {
      final t = DemoTrainingRepository(clock: clock);
      await t.saveLog(
        1,
        const SessionLog(week: 3, sessionIndex: 1, status: 'done'),
      );
      final plan = (await t.fetchActivePlan())!;
      expect(plan.logFor(3, 1)?.status, 'done');
      await t.addTimeTrial(
        'up_police_constable',
        TimeTrial(
          distanceM: 4800,
          durationSeconds: 1470,
          recordedOn: today,
          source: 'manual',
        ),
      );
      expect((await t.fetchTimeTrials('x')).last.durationSeconds, 1470);
      // No AI is called and nothing throws.
      await t.createPlan(TrainingAnswers());
      await t.generateNextWeek(1);
    });

    test('a run recorded live is analysed on the phone', () async {
      final r = DemoRunRepository(clock: clock);
      final points = tracePoints('good_5000_ssc.json');
      final verdict = await r.submit(
        RunSubmission(
          examId: 'ssc_gd',
          mode: 'mock_pet',
          targetM: 5000,
          startedAt: today,
          clientVerdict: 'verified',
          points: points,
        ),
      );
      expect(verdict!.verdict, 'verified');
      expect(verdict.finishSeconds, closeTo(1368.5, 1));
      expect((await r.recentRuns()).first.finishSeconds, closeTo(1368.5, 1));
      // And a bicycle is still caught.
      final bike = await r.submit(
        RunSubmission(
          examId: 'ssc_gd',
          mode: 'mock_pet',
          targetM: 5000,
          startedAt: today,
          clientVerdict: null,
          points: tracePoints('bicycle.json'),
        ),
      );
      expect(bike!.verdict, 'rejected');
    });
  });

  test('switchable training and runs follow the flag', () async {
    var demo = false;
    final real = FakeTrainingRepository();
    final t = SwitchableTraining(
      real: real,
      demo: DemoTrainingRepository(clock: clock),
      isDemo: () => demo,
    );
    expect(await t.fetchActivePlan(), isNull);
    demo = true;
    expect(await t.fetchActivePlan(), isNotNull);
    final rr = SwitchableRuns(
      real: FakeRunRepository(),
      demo: DemoRunRepository(clock: clock),
      isDemo: () => demo,
    );
    expect((await rr.recentRuns()), isNotEmpty);
    demo = false;
    expect((await rr.recentRuns()), isEmpty);
  });

  Widget app({required FakeAuthService auth, AppSettings? settings}) =>
      MaidanApp(
        settings: settings,
        boards: FakeLeaderboardRepository(),
        runs: FakeRunRepository(),
        location: (_) => FakeLocationSource(),
        repository: FakeExamRepository(),
        auth: auth,
        profiles: FakeProfileRepository(),
        training: FakeTrainingRepository(),
      );

  testWidgets('demo mode fills Training and Progress and says so', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = AppSettings(demoData: true);
    await tester.pumpWidget(app(auth: FakeAuthService(), settings: settings));
    await tester.pumpAndSettle();
    // Training: a plan exists although the real repository has none.
    expect(find.text('डेमो डेटा'), findsOneWidget);
    expect(find.textContaining('हफ्ता 3 / 8'), findsOneWidget);
    await tester.tap(find.text('प्रगति').last);
    await tester.pumpAndSettle();
    expect(find.text('5 दिन की लकीर'), findsOneWidget);
    expect(find.text('डेमो डेटा'), findsOneWidget);

    settings.setDemoData(false);
    await tester.pumpAndSettle();
    expect(find.text('5 दिन की लकीर'), findsNothing);
  });

  group('delete account', () {
    Future<void> openSettings(WidgetTester tester, FakeAuthService auth) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(auth: auth));
      await tester.pumpAndSettle();
      await tester.tap(find.text('मानक').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
    }

    testWidgets('spells out what goes, then erases and signs out', (
      tester,
    ) async {
      final auth = FakeAuthService();
      await openSettings(tester, auth);
      await tester.ensureVisible(find.text('खाता हटाएं'));
      await tester.tap(find.text('खाता हटाएं'));
      await tester.pumpAndSettle();
      expect(find.text('खाता हमेशा के लिए हटाएं?'), findsOneWidget);
      expect(find.textContaining('वापस नहीं हो सकता'), findsOneWidget);
      expect(auth.deleted, isFalse); // asking is not deleting
      await tester.tap(find.text('हमेशा के लिए हटाएं'));
      await tester.pumpAndSettle();
      expect(auth.deleted, isTrue);
      expect(find.text('Google से जारी रखें'), findsOneWidget);
    });

    testWidgets('cancel keeps everything', (tester) async {
      final auth = FakeAuthService();
      await openSettings(tester, auth);
      await tester.ensureVisible(find.text('खाता हटाएं'));
      await tester.tap(find.text('खाता हटाएं'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('रद्द करें'));
      await tester.pumpAndSettle();
      expect(auth.deleted, isFalse);
      expect(find.text('सेटिंग्स'), findsOneWidget);
    });

    testWidgets('offline: stays signed in and says so', (tester) async {
      final auth = FakeAuthService()..failDelete = true;
      await openSettings(tester, auth);
      await tester.ensureVisible(find.text('खाता हटाएं'));
      await tester.tap(find.text('खाता हटाएं'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('हमेशा के लिए हटाएं'));
      await tester.pumpAndSettle();
      expect(auth.isSignedIn, isTrue);
      expect(find.textContaining('खाता नहीं हटा'), findsOneWidget);
    });

    testWidgets('the About page states the facts', (tester) async {
      await openSettings(tester, FakeAuthService());
      await tester.ensureVisible(find.text('ऐप के बारे में'));
      await tester.tap(find.text('ऐप के बारे में'));
      await tester.pumpAndSettle();
      expect(find.text('स्वतंत्र ऐप'), findsOneWidget);
      expect(find.textContaining('सरकारी विभाग'), findsOneWidget);
      expect(
        find.textContaining('खाता हटाने पर सब मिट जाता है'),
        findsOneWidget,
      );
    });
  });
}
