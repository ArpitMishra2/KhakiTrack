import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/data/leaderboard_repository.dart';
import 'package:maidan/main.dart';
import 'package:maidan/screens/ranking_tab.dart';

import 'fake_auth_service.dart';
import 'fake_exam_repository.dart';
import 'fake_gps.dart';
import 'fake_leaderboard_repository.dart';
import 'fake_profile_repository.dart';
import 'fake_training_repository.dart';

Future<void> pumpRanking(
  WidgetTester tester,
  FakeLeaderboardRepository boards,
) async {
  tester.view.physicalSize = const Size(400, 1200);
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
      boards: boards,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('रैंकिंग'));
  await tester.pumpAndSettle();
}

void main() {
  test('place names are tidied so friends land on the same board', () {
    expect(cleanPlace('  Ghatampur   Block '), 'Ghatampur Block');
    expect(cleanPlace('   '), isNull);
    expect(cleanPlace(null), isNull);
  });

  testWidgets('no area yet: set district, block and village', (tester) async {
    final boards = FakeLeaderboardRepository();
    await pumpRanking(tester, boards);
    expect(find.textContaining('अपना क्षेत्र चुनें'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'आपका क्षेत्र'));
    await tester.pumpAndSettle();
    FilledButton save() =>
        tester.widget(find.widgetWithText(FilledButton, 'सेव करें'));
    expect(save().onPressed, isNull); // district is required

    await tester.tap(find.byType(DropdownMenu<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('कानपुर नगर').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'ब्लॉक / तहसील'),
      ' Ghatampur ',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'गाँव / मोहल्ला'),
      'Sajeti',
    );
    await tester.tap(find.text('दूसरों की रैंकिंग में मेरा नाम दिखाएं'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'सेव करें'));
    await tester.pumpAndSettle();

    expect(boards.area.district, 'kanpur_nagar');
    expect(boards.area.block, 'Ghatampur');
    expect(boards.area.village, 'Sajeti');
    expect(boards.area.visible, isFalse);
    // Back on the district board, which is empty.
    expect(boards.calls.last, (scope: 'district', metric: 'pet', week: 0));
    expect(find.textContaining('अभी कोई नहीं है'), findsOneWidget);
  });

  testWidgets('boards switch by scope, metric and week; me highlighted', (
    tester,
  ) async {
    final boards =
        FakeLeaderboardRepository(
            area: const Area(district: 'kanpur_nagar', block: 'Ghatampur'),
          )
          ..boards['district/pet/0'] = const [
            LeaderboardEntry(
              rank: 1,
              name: 'Vikas P.',
              value: 1390,
              isMe: false,
            ),
            LeaderboardEntry(
              rank: 2,
              name: 'Ramesh K.',
              value: 1450,
              isMe: true,
            ),
          ]
          ..boards['block/distance/1'] = const [
            LeaderboardEntry(rank: 1, name: 'Suresh', value: 21.5, isMe: false),
          ];
    await pumpRanking(tester, boards);
    expect(find.text('23:10'), findsOneWidget);
    expect(find.text('Ramesh K. (आप)'), findsOneWidget);

    await tester.tap(find.text('ब्लॉक'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('इस हफ्ते की दूरी'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('पिछला हफ्ता'));
    await tester.pumpAndSettle();
    expect(boards.calls.last, (scope: 'block', metric: 'distance', week: 1));
    expect(find.text('21.5 किमी'), findsOneWidget);

    // Village board needs a village first.
    await tester.tap(find.text('गाँव'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ब्लॉक और गाँव जोड़ें'), findsOneWidget);
  });

  testWidgets('rankings fit a 320 px phone at 1.3x text', (tester) async {
    final boards =
        FakeLeaderboardRepository(area: const Area(district: 'kanpur_nagar'))
          ..boards['district/pet/0'] = const [
            LeaderboardEntry(
              rank: 12,
              name: 'Ramashankar Vishwakarma',
              value: 1599,
              isMe: true,
            ),
          ];
    await pumpRanking(tester, boards);
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('26:39'),
      100,
      scrollable: find
          .descendant(
            of: find.byType(RankingTab),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('26:39'), findsOneWidget);
    expect(find.text('Ramashankar Vishwakarma (आप)'), findsOneWidget);
  });
}
