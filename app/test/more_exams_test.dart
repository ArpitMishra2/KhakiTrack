import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/data/exam_models.dart';
import 'package:maidan/data/profile.dart';
import 'package:maidan/data/standards_logic.dart';
import 'package:maidan/main.dart';
import 'package:maidan/screens/standard_labels.dart';

import 'fake_auth_service.dart';
import 'fake_exam_repository.dart';
import 'fake_gps.dart';
import 'fake_leaderboard_repository.dart';
import 'fake_profile_repository.dart';
import 'fake_training_repository.dart';
import 'test_helpers.dart';

Map<String, double?> resolvedAt(
  List<Standard> all,
  String gender,
  String category,
  int age,
) => {
  for (final s in resolveStandards(forAge(all, age), gender, category))
    s.event: s.value,
};

void main() {
  final dp = loadDataFile('delhi_police_constable');
  final ag = loadDataFile('agniveer_army_gd');

  test('Delhi Police: every row is from the official notice', () {
    expect(dp.every((s) => s.isConfirmed), isTrue);
  });

  test('Delhi Police men by age band', () {
    expect(resolvedAt(dp, 'male', 'general', 24), {
      'height_cm': 170,
      'chest_unexpanded_cm': 81,
      'chest_expansion_cm': 4,
      'run_1600m': 360,
      'long_jump_ft': 14,
      'high_jump_ft': 3.75,
    });
    expect(resolvedAt(dp, 'male', 'general', 30)['run_1600m'], 360);
    expect(resolvedAt(dp, 'male', 'general', 31)['run_1600m'], 420);
    expect(resolvedAt(dp, 'male', 'general', 40)['high_jump_ft'], 3.5);
    expect(resolvedAt(dp, 'male', 'general', 41)['long_jump_ft'], 12);
    expect(resolvedAt(dp, 'male', 'hill_areas', 25)['height_cm'], 165);
    expect(resolvedAt(dp, 'male', 'st', 25)['chest_unexpanded_cm'], 76);
  });

  test('Delhi Police women: SC/ST relaxation and no chest', () {
    expect(standardsCategoryFor(dp, 'sc'), 'sc_st');
    expect(standardsCategoryFor(dp, 'st'), 'sc_st');
    expect(standardsCategoryFor(dp, 'obc'), 'general');
    expect(resolvedAt(dp, 'female', 'sc_st', 22), {
      'height_cm': 155,
      'run_1600m': 480,
      'long_jump_ft': 10,
      'high_jump_ft': 3,
    });
    expect(resolvedAt(dp, 'female', 'police_ward', 35)['height_cm'], 152);
    expect(resolvedAt(dp, 'female', 'general', 45)['run_1600m'], 600);
  });

  test('run standard follows age; Agniveer has men only (sourced)', () {
    expect(runStandardFor(dp, 'male', 'general', age: 35)!.value, 420);
    expect(runStandardFor(dp, 'female', 'sc', age: 22)!.value, 480);
    final army = runStandardFor(ag, 'male', 'general', age: 19)!;
    expect(army.value, 375);
    expect(army.runMetres, 1600);
    // Women's Agniveer GD (Military Police) is a different notice: not loaded.
    expect(runStandardFor(ag, 'female', 'general', age: 19), isNull);
  });

  test('age in completed years', () {
    expect(ageOn(DateTime(2000, 10, 4), DateTime(2030, 10, 3)), 29);
    expect(ageOn(DateTime(2000, 10, 3), DateTime(2030, 10, 3)), 30);
  });

  test('feet and inches as the notice writes them', () {
    expect(feetInches(3.75), "3'9\"");
    expect(feetInches(2.5), "2'6\"");
    expect(feetInches(14), "14'");
  });

  testWidgets('Delhi Police standards for a 35-year-old man', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final now = DateTime.now();
    await tester.pumpWidget(
      MaidanApp(
        repository: FakeExamRepository(),
        auth: FakeAuthService(),
        profiles: FakeProfileRepository(
          Profile(
            displayName: 'Test',
            gender: 'male',
            dateOfBirth: DateTime(now.year - 35, 1, 1),
            category: 'general',
            examId: 'delhi_police_constable',
          ),
        ),
        training: FakeTrainingRepository(),
        runs: FakeRunRepository(),
        location: (_) => FakeLocationSource(),
        boards: FakeLeaderboardRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await openStandards(tester);
    await tester.tap(find.text('दिल्ली पुलिस कांस्टेबल'));
    await tester.pumpAndSettle();
    expect(find.textContaining('35 साल'), findsOneWidget);
    expect(find.text('7 मिनट में'), findsOneWidget);
    expect(find.text("13'"), findsOneWidget);
    expect(find.text("3'6\""), findsOneWidget);
    expect(find.text('लंबी कूद'), findsOneWidget);
  });

  testWidgets('Agniveer shows the sourced Physical Fitness Test', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaidanApp(
        repository: FakeExamRepository(),
        auth: FakeAuthService(),
        profiles: FakeProfileRepository(),
        training: FakeTrainingRepository(),
        runs: FakeRunRepository(),
        location: (_) => FakeLocationSource(),
        boards: FakeLeaderboardRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await openStandards(tester);
    await tester.tap(find.text('अग्निवीर थल सेना (GD)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('पुष्ट नहीं हुए'), findsNothing);
    expect(find.text('पुष्टि बाकी'), findsNothing);
    expect(find.text('1.6 किमी दौड़'), findsOneWidget);
    expect(find.text('6 मिनट 15 सेकंड में'), findsOneWidget);
    expect(find.text('पुल-अप (बीम)'), findsOneWidget);
    expect(find.text('कम से कम 6'), findsOneWidget);
    expect(find.text('पास होना ज़रूरी'), findsNWidgets(2));
  });
}
