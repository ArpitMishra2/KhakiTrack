import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/data/profile.dart';
import 'package:maidan/data/standards_logic.dart';
import 'package:maidan/main.dart';

import 'fake_auth_service.dart';
import 'fake_exam_repository.dart';
import 'fake_profile_repository.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('age rule matches the database check', () {
    test('turns 18 on the birthday', () {
      final today = DateTime(2026, 10, 2);
      expect(latestAllowedDateOfBirth(today), DateTime(2008, 10, 2));
      expect(isAdult(DateTime(2008, 10, 2), today), isTrue);
      expect(isAdult(DateTime(2008, 10, 3), today), isFalse);
    });

    test('29 February maps to 28 February, like Postgres', () {
      expect(
        latestAllowedDateOfBirth(DateTime(2028, 2, 29)),
        DateTime(2010, 2, 28),
      );
    });
  });

  test('social category maps to the standards category', () {
    final up = loadDataFile('up_police_constable');
    final ssc = loadDataFile('ssc_gd');
    expect(standardsCategoryFor(up, 'st'), 'st');
    expect(standardsCategoryFor(up, 'ews'), 'general_obc_sc');
    expect(standardsCategoryFor(up, 'sc'), 'general_obc_sc');
    expect(standardsCategoryFor(ssc, 'obc'), 'general');
    expect(standardsCategoryFor(ssc, 'st'), 'st');
    expect(standardsCategoryFor(ssc, null), 'general');
  });

  test('profile is complete only with every field and a name', () {
    final full = Profile(
      displayName: 'A',
      gender: 'male',
      dateOfBirth: DateTime(2000),
      category: 'sc',
      examId: 'ssc_gd',
    );
    expect(full.isComplete, isTrue);
    expect(const Profile().isComplete, isFalse);
    expect(
      Profile(
        displayName: '  ',
        gender: 'male',
        dateOfBirth: DateTime(2000),
        category: 'sc',
        examId: 'ssc_gd',
      ).isComplete,
      isFalse,
    );
    expect(full.toJson()['date_of_birth'], '2000-01-01');
  });

  testWidgets('new user fills the profile, then sees their own standards', (
    tester,
  ) async {
    // Tall enough that the whole form, including Save, is built.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final profiles = FakeProfileRepository(const Profile());
    await tester.pumpWidget(
      MaidanApp(
        repository: FakeExamRepository(),
        auth: FakeAuthService(),
        profiles: profiles,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('आपकी जानकारी'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsOneWidget); // from Google
    FilledButton save() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'सेव करें'),
    );
    expect(save().onPressed, isNull);

    await tapVisible(tester, find.text('महिला'));
    await tapVisible(tester, find.text('तारीख चुनें'));
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    final ok = MaterialLocalizations.of(
      tester.element(find.byType(DatePickerDialog)),
    ).okButtonLabel;
    await tester.tap(find.text(ok));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('श्रेणी चुनें'));
    await tester.tap(find.text('अनुसूचित जनजाति (ST)').last);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('यूपी पुलिस कांस्टेबल'));
    expect(save().onPressed, isNotNull);

    await tapVisible(tester, find.text('सेव करें'));
    expect(profiles.saves, 1);
    expect(profiles.stored.gender, 'female');
    expect(profiles.stored.category, 'st');
    expect(profiles.stored.examId, 'up_police_constable');
    expect(profiles.stored.dateOfBirth!.day, 15);
    expect(isAdult(profiles.stored.dateOfBirth!, DateTime.now()), isTrue);

    // Home, then the standards screen opens as female ST.
    expect(find.text('अपनी परीक्षा चुनें'), findsOneWidget);
    await tester.tap(find.text('यूपी पुलिस कांस्टेबल'));
    await tester.pumpAndSettle();
    expect(find.text('147 सेमी'), findsOneWidget);
    expect(find.text('40 किग्रा'), findsOneWidget);
  });

  testWidgets('a failed save shows an error and keeps the form', (
    tester,
  ) async {
    final profiles = FakeProfileRepository(
      Profile(
        displayName: 'A',
        gender: 'male',
        dateOfBirth: DateTime(2000),
        category: 'obc',
      ),
    )..failSave = true;
    await tester.pumpWidget(
      MaidanApp(
        repository: FakeExamRepository(),
        auth: FakeAuthService(),
        profiles: profiles,
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('SSC GD कांस्टेबल'));
    await tapVisible(tester, find.text('सेव करें'));
    expect(find.textContaining('सेव नहीं हो सका'), findsOneWidget);
    expect(find.text('आपकी जानकारी'), findsOneWidget);
  });

  testWidgets('a complete profile skips setup', (tester) async {
    await tester.pumpWidget(
      MaidanApp(
        repository: FakeExamRepository(),
        auth: FakeAuthService(),
        profiles: FakeProfileRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('आपकी जानकारी'), findsNothing);
    expect(find.text('अपनी परीक्षा चुनें'), findsOneWidget);
  });
}
