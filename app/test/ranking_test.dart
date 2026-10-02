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
  FakeLeaderboardRepository boards, {
  Size size = const Size(400, 1600),
}) async {
  tester.view.physicalSize = size;
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

Future<void> tapIn(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  test('names are tidied like the server does', () {
    expect(cleanName('  Ghatampur   Ground '), 'Ghatampur Ground');
    expect(cleanName('   '), isNull);
  });

  testWidgets('everyone board by default; switch to my community', (
    tester,
  ) async {
    final boards = FakeLeaderboardRepository();
    final village = boards.addCommunity('Sajeti Gaon', join: true);
    boards.boards['all/pet/0'] = const [
      LeaderboardEntry(rank: 1, name: 'Vikas P.', value: 1390, isMe: false),
      LeaderboardEntry(rank: 2, name: 'Ramesh K.', value: 1450, isMe: true),
    ];
    boards.boards['$village/distance/1'] = const [
      LeaderboardEntry(rank: 1, name: 'Suresh', value: 21.5, isMe: false),
    ];
    await pumpRanking(tester, boards);
    expect(boards.calls.first, (community: null, metric: 'pet', week: 0));
    expect(find.text('23:10'), findsOneWidget);
    expect(find.text('Ramesh K. (आप)'), findsOneWidget);

    await tapIn(tester, find.text('Sajeti Gaon'));
    await tapIn(tester, find.text('इस हफ्ते की दूरी'));
    await tapIn(tester, find.text('पिछला हफ्ता'));
    expect(boards.calls.last, (
      community: village,
      metric: 'distance',
      week: 1,
    ));
    expect(find.text('21.5 किमी'), findsOneWidget);
  });

  testWidgets('create a private group, see its code, join by code', (
    tester,
  ) async {
    final boards = FakeLeaderboardRepository();
    final other = boards.addCommunity('Dosti Daud', group: true, private: true);
    await pumpRanking(tester, boards);
    expect(find.textContaining('किसी इलाके या ग्रुप में नहीं'), findsOneWidget);

    await tapIn(tester, find.text('इलाके / ग्रुप'));
    FilledButton create() =>
        tester.widget(find.widgetWithText(FilledButton, 'बनाएं'));
    expect(create().onPressed, isNull); // name needed

    await tester.enterText(
      find.widgetWithText(TextField, 'नाम'),
      '  Subah   Ki Daud ',
    );
    await tester.pumpAndSettle();
    await tapIn(tester, find.text('ग्रुप (दोस्त, बैच, अकादमी)'));
    await tapIn(tester, find.text('प्राइवेट – सिर्फ कोड से जुड़ सकते हैं'));
    await tapIn(tester, find.widgetWithText(FilledButton, 'बनाएं'));
    final mine = await boards.myCommunities();
    expect(mine.single.name, 'Subah Ki Daud');
    expect(mine.single.isPrivate, isTrue);
    expect(find.textContaining('ग्रुप कोड: CODE02'), findsOneWidget);

    // Wrong code, then the right one (case-insensitive).
    await tester.enterText(
      find.widgetWithText(TextField, 'ग्रुप कोड'),
      'zzzzzz',
    );
    await tapIn(tester, find.widgetWithText(FilledButton, 'जुड़ें').last);
    expect(find.textContaining('यह कोड नहीं मिला'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'ग्रुप कोड'),
      'code01',
    );
    await tapIn(tester, find.widgetWithText(FilledButton, 'जुड़ें').last);
    expect(boards.joined, contains(other));

    // Back on rankings, both appear as chips.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Subah Ki Daud'), findsOneWidget);
    expect(find.text('Dosti Daud'), findsOneWidget);
  });

  testWidgets('search and join a public area; duplicate names refused', (
    tester,
  ) async {
    final boards = FakeLeaderboardRepository();
    final ground = boards.addCommunity('Ghatampur Ground');
    await pumpRanking(tester, boards);
    await tapIn(tester, find.text('इलाके / ग्रुप'));
    await tester.enterText(
      find.widgetWithText(TextField, 'गाँव, मैदान या ग्रुप ढूंढें'),
      'ghatam',
    );
    await tester.pumpAndSettle();
    expect(find.text('Ghatampur Ground'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'नाम'),
      'ghatampur ground',
    );
    await tester.pumpAndSettle();
    await tapIn(tester, find.widgetWithText(FilledButton, 'बनाएं'));
    expect(find.textContaining('पहले से है'), findsOneWidget);

    await tapIn(tester, find.widgetWithText(FilledButton, 'जुड़ें').first);
    expect(boards.joined, contains(ground));
    await tapIn(tester, find.text('छोड़ें'));
    expect(boards.joined, isNot(contains(ground)));
  });

  testWidgets('rankings and communities fit a 320 px phone at 1.3x', (
    tester,
  ) async {
    final boards = FakeLeaderboardRepository()
      ..addCommunity('Ghatampur Railway Ground Morning Batch', join: true)
      ..addCommunity('Sajeti', group: true, private: true, join: true);
    boards.boards['all/pet/0'] = const [
      LeaderboardEntry(
        rank: 12,
        name: 'Ramashankar Vishwakarma',
        value: 1599,
        isMe: true,
      ),
    ];
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpRanking(tester, boards, size: const Size(320, 568));
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
    await tapIn(tester, find.text('इलाके / ग्रुप'));
    expect(find.textContaining('ग्रुप कोड'), findsWidgets);
  });
}
