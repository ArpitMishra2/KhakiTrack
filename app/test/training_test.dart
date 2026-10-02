import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/data/training_models.dart';
import 'package:maidan/data/training_repository.dart';
import 'package:maidan/screens/home_shell.dart';
import 'package:maidan/main.dart';

import 'fake_auth_service.dart';
import 'fake_exam_repository.dart';
import 'fake_gps.dart';
import 'fake_profile_repository.dart';
import 'fake_training_repository.dart';

/// Scrolls [finder] into view (building it if the list is lazy) and taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The app on a tall screen (so long forms are fully built) at [today].
Future<void> pumpApp(
  WidgetTester tester,
  FakeTrainingRepository training, {
  DateTime? today,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaidanApp(
      runs: FakeRunRepository(),
      location: (_) => FakeLocationSource(),
      repository: FakeExamRepository(),
      auth: FakeAuthService(),
      profiles: FakeProfileRepository(),
      training: training,
    ),
  );
  await tester.pumpAndSettle();
  // Pin "today" for date-dependent views.
  if (today != null) {
    final shell = tester.widget<HomeShell>(find.byType(HomeShell));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('hi'),
        localizationsDelegates: (tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        )).localizationsDelegates,
        supportedLocales: const [Locale('hi'), Locale('en')],
        home: HomeShell(
          exams: shell.exams,
          training: training,
          runs: shell.runs,
          location: shell.location,
          auth: shell.auth,
          profile: shell.profile,
          today: today,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('no plan: intro shows the official target', (tester) async {
    await pumpApp(tester, FakeTrainingRepository());
    expect(find.text('आपका अपना रनिंग प्लान'), findsOneWidget);
    expect(find.text('लक्ष्य: 4.8 किमी 25:00 में'), findsOneWidget);
  });

  testWidgets('questionnaire collects answers and builds the plan', (
    tester,
  ) async {
    final training = FakeTrainingRepository();
    await pumpApp(tester, training, today: DateTime(2026, 10, 5));
    await tapVisible(tester, find.text('प्लान बनाना शुरू करें'));

    // Step 1: level. Next is disabled until answered.
    FilledButton next() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'आगे'));
    expect(find.text('चरण 1 / 4'), findsOneWidget);
    expect(next().onPressed, isNull);
    await tapVisible(tester, find.text('हाँ'));
    await tester.enterText(find.byType(TextField), '29:10');
    await tester.pumpAndSettle();
    expect(next().onPressed, isNotNull);
    await tapVisible(tester, find.text('आगे'));

    // Step 2: experience.
    await tapVisible(tester, find.text('3 से 12 महीने'));
    await tapVisible(tester, find.text('3').first);
    await tapVisible(tester, find.text('10 किमी'));
    await tapVisible(tester, find.text('खेती / मेहनत का काम'));
    await tapVisible(tester, find.text('आगे'));

    // Step 3: schedule.
    await tapVisible(tester, find.text('8 हफ्ते'));
    await tapVisible(tester, find.text('5 दिन'));
    await tapVisible(tester, find.text('60 मिनट'));
    await tapVisible(tester, find.text('आगे'));

    // Step 4: health. Choosing a pain clears "no pain".
    await tapVisible(tester, find.text('घुटना'));
    await tester.enterText(
      find.widgetWithText(TextField, 'दर्द के बारे में थोड़ा बताएं (वैकल्पिक)'),
      'सीढ़ी चढ़ने पर दर्द',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'वज़न किग्रा (वैकल्पिक)'),
      '500', // out of range, dropped
    );
    await tapVisible(tester, find.text('मेरा प्लान बनाएं'));

    final a = training.lastAnswers!.toJson();
    expect(a['can_complete_distance'], true);
    expect(a['current_time_seconds'], 1750);
    expect(a['running_experience'], '3to12m');
    expect(a['runs_per_week'], 3);
    expect(a['weekly_km'], 10.0);
    expect(a['background'], ['farm_labour']);
    expect(a['weeks_to_pet'], 8);
    expect(a['days_per_week'], 5);
    expect(a['minutes_per_session'], 60);
    expect(a['pain'], ['knee']);
    expect(a['pain_note'], 'सीढ़ी चढ़ने पर दर्द');
    expect(a['weight_kg'], isNull);

    // Back on the training tab with the new plan, week 1.
    expect(find.text('हफ्ता 1 / 4'), findsOneWidget);
    expect(find.text('मेहनत की ज़रूरत'), findsOneWidget);
    expect(find.text('आसान दौड़ 1'), findsOneWidget);
  });

  testWidgets('a failed generation shows the reason and keeps answers', (
    tester,
  ) async {
    final training = FakeTrainingRepository()
      ..failWith = const TrainingException('rate_limited');
    await pumpApp(tester, training);
    await tapVisible(tester, find.text('प्लान बनाना शुरू करें'));
    await tapVisible(tester, find.text('नहीं'));
    await tapVisible(tester, find.text('2 किमी'));
    await tapVisible(tester, find.text('आगे'));
    await tapVisible(tester, find.text('अभी शुरू नहीं किया'));
    await tapVisible(tester, find.text('आगे'));
    await tapVisible(tester, find.text('12 हफ्ते'));
    await tapVisible(tester, find.text('आगे'));
    await tapVisible(tester, find.text('मेरा प्लान बनाएं'));
    expect(
      find.textContaining('आज के लिए प्लान बनाने की सीमा'),
      findsOneWidget,
    );
    expect(find.text('चरण 4 / 4'), findsOneWidget);
    expect(training.lastAnswers!.toJson()['longest_continuous_km'], 2.0);
  });

  testWidgets('today is highlighted and a session can be logged', (
    tester,
  ) async {
    final start = DateTime(2026, 10, 5);
    final training = FakeTrainingRepository(plan: samplePlan(start));
    await pumpApp(tester, training, today: DateTime(2026, 10, 9)); // day 5
    expect(find.text('हफ्ता 1 / 4'), findsOneWidget);
    expect(find.text('0 / 3 सेशन पूरे'), findsOneWidget);

    await tapVisible(tester, find.text('4.8 किमी टाइम ट्रायल'));
    expect(find.text('सेशन दर्ज करें'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'कुल समय (मिनट:सेकंड)'),
      '27:40',
    );
    await tapVisible(tester, find.text('4'));
    await tapVisible(tester, find.text('दौड़ते समय या बाद में दर्द हुआ'));
    expect(find.textContaining('डॉक्टर को दिखाएं'), findsOneWidget);
    await tapVisible(tester, find.text('सेव करें'));

    final log = training.savedLogs.single;
    expect(log.week, 1);
    expect(log.sessionIndex, 2);
    expect(log.status, 'done');
    expect(log.distanceKm, 4.8);
    expect(log.durationSeconds, 1660);
    expect(log.effort, 4);
    expect(log.pain, isTrue);
    // A completed time trial also becomes a progress point.
    final trial = training.trials.single;
    expect(trial.distanceM, 4800);
    expect(trial.durationSeconds, 1660);
    expect(trial.source, 'plan');
    expect(find.text('1 / 3 सेशन पूरे'), findsOneWidget);
  });

  testWidgets('next week is locked until two days before, then generated', (
    tester,
  ) async {
    final start = DateTime(2026, 10, 5);
    final training = FakeTrainingRepository(plan: samplePlan(start));
    // 16 Oct is in week 2; week 3 starts 19 Oct and unlocks 17 Oct.
    await pumpApp(tester, training, today: DateTime(2026, 10, 16));
    expect(find.text('हफ्ता 2 / 4'), findsOneWidget);
    await tapVisible(tester, find.byIcon(Icons.chevron_right));
    expect(find.textContaining('हफ्ता 3 का प्लान'), findsOneWidget);
    expect(find.textContaining('को खुलेगा'), findsOneWidget);

    await pumpApp(tester, training, today: DateTime(2026, 10, 17));
    await tapVisible(tester, find.byIcon(Icons.chevron_right));
    await tapVisible(tester, find.text('हफ्ता 3 का प्लान बनाएं'));
    expect(training.nextWeekCalls, 1);
    expect(find.text('आसान दौड़ 3'), findsOneWidget);
  });

  testWidgets('progress shows the gap to the target and estimates', (
    tester,
  ) async {
    final training = FakeTrainingRepository(
      trials: [
        TimeTrial(
          distanceM: 4800,
          durationSeconds: 1750,
          recordedOn: DateTime(2026, 10, 1),
          source: 'assessment',
        ),
        TimeTrial(
          distanceM: 1600,
          durationSeconds: 450,
          recordedOn: DateTime(2026, 10, 8),
          source: 'manual',
        ),
      ],
    );
    await pumpApp(tester, training);
    await tapVisible(tester, find.text('प्रगति'));
    expect(find.text('4.8 किमी का समय'), findsOneWidget);
    expect(find.text('लक्ष्य: 25:00'), findsOneWidget);
    // 450 s over 1.6 km -> about 1449 s over 4.8 km, inside the target.
    expect(find.textContaining('ताज़ा समय: 24:'), findsOneWidget);
    expect(find.textContaining('अनुमानित'), findsWidgets);
    expect(find.textContaining('तेज़ हैं'), findsOneWidget);
  });

  testWidgets('a time trial can be added from the progress tab', (
    tester,
  ) async {
    final training = FakeTrainingRepository();
    await pumpApp(tester, training, today: DateTime(2026, 10, 9));
    await tapVisible(tester, find.text('प्रगति'));
    expect(find.textContaining('अभी कोई टाइम ट्रायल नहीं'), findsOneWidget);
    await tapVisible(tester, find.text('टाइम ट्रायल जोड़ें'));
    await tester.enterText(
      find.widgetWithText(TextField, 'समय (मिनट:सेकंड)'),
      '26:30',
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('सेव करें'));
    expect(training.trials.single.durationSeconds, 1590);
    expect(training.trials.single.distanceM, 4800);
    expect(find.textContaining('1:30 और कम करना है'), findsOneWidget);
  });

  testWidgets('plan view and questionnaire fit a 320 px phone at 1.3x text', (
    tester,
  ) async {
    final training = FakeTrainingRepository(
      plan: samplePlan(DateTime(2026, 10, 5)),
    );
    await pumpApp(tester, training, today: DateTime(2026, 10, 9));
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('4.8 किमी टाइम ट्रायल'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tapVisible(tester, find.text('4.8 किमी टाइम ट्रायल'));
    await tester.tapAt(const Offset(10, 10)); // close the sheet
    await tester.pumpAndSettle();

    training.plan = null;
    await pumpApp(tester, training);
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('प्लान बनाना शुरू करें'));
    await tapVisible(tester, find.text('नहीं'));
    await tapVisible(tester, find.text('2 किमी'));
    await tapVisible(tester, find.text('आगे'));
    await tapVisible(tester, find.text('1 साल से ज़्यादा'));
    await tapVisible(tester, find.text('आगे'));
    await tapVisible(tester, find.text('16 हफ्ते'));
  });
}
