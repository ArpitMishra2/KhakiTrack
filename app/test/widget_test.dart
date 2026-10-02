import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/main.dart';

import 'fake_exam_repository.dart';

void main() {
  testWidgets('home screen is Hindi by default and lists exams', (
    tester,
  ) async {
    await tester.pumpWidget(MaidanApp(repository: FakeExamRepository()));
    await tester.pumpAndSettle();
    expect(find.text('अपनी परीक्षा चुनें'), findsOneWidget);
    expect(find.text('यूपी पुलिस कांस्टेबल'), findsOneWidget);
    expect(find.text('SSC GD कांस्टेबल'), findsOneWidget);
  });

  testWidgets('shows retry when offline and recovers', (tester) async {
    final repo = FakeExamRepository()..failing = true;
    await tester.pumpWidget(MaidanApp(repository: repo));
    await tester.pumpAndSettle();
    expect(find.text('फिर कोशिश करें'), findsOneWidget);

    repo.failing = false;
    await tester.tap(find.text('फिर कोशिश करें'));
    await tester.pumpAndSettle();
    expect(find.text('यूपी पुलिस कांस्टेबल'), findsOneWidget);
  });

  testWidgets('UP Police standards for men, then women', (tester) async {
    await tester.pumpWidget(MaidanApp(repository: FakeExamRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('यूपी पुलिस कांस्टेबल'));
    await tester.pumpAndSettle();

    expect(find.text('168 सेमी'), findsOneWidget);
    expect(find.text('84 सेमी'), findsOneWidget);
    expect(find.text('4.8 किमी दौड़'), findsOneWidget);
    expect(find.text('25 मिनट में'), findsOneWidget);

    await tester.tap(find.text('महिला'));
    await tester.pumpAndSettle();
    expect(find.text('152 सेमी'), findsOneWidget);
    expect(find.text('40 किग्रा'), findsOneWidget);
    expect(find.text('2.4 किमी दौड़'), findsOneWidget);
    expect(find.text('14 मिनट में'), findsOneWidget);
    expect(find.text('168 सेमी'), findsNothing);
  });

  testWidgets('fits a 320 px phone at 1.3x text with the longest labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(MaidanApp(repository: FakeExamRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SSC GD कांस्टेबल'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('महिला'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('पूर्वोत्तर राज्य (').last);
    await tester.pumpAndSettle();
    expect(find.text('152.5 सेमी'), findsOneWidget);
    expect(find.text('8 मिनट 30 सेकंड में'), findsOneWidget);
  });

  testWidgets('SSC GD category change updates standards', (tester) async {
    await tester.pumpWidget(MaidanApp(repository: FakeExamRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SSC GD कांस्टेबल'));
    await tester.pumpAndSettle();
    expect(find.text('170 सेमी'), findsOneWidget);
    expect(find.text('5 किमी दौड़'), findsOneWidget);
    expect(find.text('24 मिनट में'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('अनुसूचित जनजाति (ST)').last);
    await tester.pumpAndSettle();
    expect(find.text('162.5 सेमी'), findsOneWidget);
    expect(find.text('76 सेमी'), findsOneWidget);

    await tester.tap(find.text('महिला'));
    await tester.pumpAndSettle();
    expect(find.text('150 सेमी'), findsOneWidget);
    expect(find.text('1.6 किमी दौड़'), findsOneWidget);
    expect(find.text('8 मिनट 30 सेकंड में'), findsOneWidget);
  });
}
