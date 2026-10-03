import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/data/app_settings.dart';
import 'package:maidan/data/demo_leaderboard.dart';
import 'package:maidan/data/leaderboard_repository.dart';
import 'package:maidan/main.dart';

import 'fake_auth_service.dart';
import 'fake_exam_repository.dart';
import 'fake_gps.dart';
import 'fake_leaderboard_repository.dart';
import 'fake_profile_repository.dart';
import 'fake_training_repository.dart';

void main() {
  final demo = DemoLeaderboardRepository(myName: () async => 'Ramesh K.');

  test('short names', () {
    expect(shortName('Rahul Kumar Mishra'), 'Rahul M.');
    expect(shortName('Rahul'), 'Rahul');
    expect(shortName('  '), 'You');
    expect(shortName(null), 'You');
  });

  group('boards', () {
    test(
      'PET board: fastest first, ranks in order, me at 5 this week',
      () async {
        final rows = await demo.fetch(null, 'pet');
        expect(rows.length, greaterThanOrEqualTo(20));
        expect(
          [for (final r in rows) r.rank],
          [for (var i = 1; i <= rows.length; i++) i],
        );
        final times = [for (final r in rows) r.value];
        expect(times, [...times]..sort());
        expect(times.first, inInclusiveRange(1250, 1400)); // about 21 to 23 min
        final me = rows.where((r) => r.isMe).toList();
        expect(me, hasLength(1));
        expect(me.single.rank, 5);
        expect(me.single.name, 'Ramesh K.');
        // Some are past the 25:00 cut-off, so the board is not all green.
        expect(times.last, greaterThan(1500));
      },
    );

    test('distance board: most km first', () async {
      final rows = await demo.fetch(1, 'distance');
      final km = [for (final r in rows) r.value];
      expect(km, [...km]..sort((a, b) => b.compareTo(a)));
      expect(km.last, greaterThanOrEqualTo(4));
      expect(rows.where((r) => r.isMe), hasLength(1));
    });

    test('last week differs and has me lower', () async {
      final now = await demo.fetch(null, 'pet');
      final before = await demo.fetch(null, 'pet', weekOffset: 1);
      expect(before.firstWhere((r) => r.isMe).rank, 7);
      expect([
        for (final r in before) r.name,
      ], isNot([for (final r in now) r.name]));
    });

    test('same question, same answer (stable for a pitch)', () async {
      final a = await demo.fetch(2, 'pet');
      final b = await demo.fetch(2, 'pet');
      expect(
        [for (final r in a) '${r.name}${r.value}'],
        [for (final r in b) '${r.name}${r.value}'],
      );
    });

    test('a small community has a small board with unique names', () async {
      final rows = await demo.fetch(3, 'pet');
      expect(rows.length, 8);
      expect({for (final r in rows) r.name}.length, rows.length);
    });
  });

  group('communities', () {
    test('starts in three, can search public ones, join and leave', () async {
      final d = DemoLeaderboardRepository();
      expect((await d.myCommunities()).map((c) => c.name), [
        'Ghatampur Ground',
        'Sajeti Gaon',
        'Subah Ki Daud',
      ]);
      final found = await d.search('');
      expect(found.any((c) => c.isPrivate), isFalse);
      final bilhaur = found.firstWhere((c) => c.name == 'Bilhaur Maidan');
      expect(bilhaur.isMember, isFalse);
      await d.join(bilhaur.id);
      expect((await d.myCommunities()).length, 4);
      await d.leave(bilhaur.id);
      expect((await d.myCommunities()).length, 3);
    });

    test('private group by code, new communities, duplicate names', () async {
      final d = DemoLeaderboardRepository();
      await d.joinByCode('demo06');
      expect(
        (await d.myCommunities()).any(
          (c) => c.name == 'Maidan Academy Batch 7',
        ),
        isTrue,
      );
      expect(() => d.joinByCode('NOPE'), throwsA(isA<CommunityException>()));
      final id = await d.create('My Village', group: false, private: false);
      expect(await d.fetch(id, 'pet'), isEmpty); // nobody has run yet
      expect(
        () => d.create('my village', group: false, private: false),
        throwsA(isA<CommunityException>()),
      );
    });
  });

  test('switchable uses demo or real depending on the flag', () async {
    final real = FakeLeaderboardRepository()
      ..addCommunity('Real Place', join: true);
    var isDemo = false;
    final s = SwitchableLeaderboards(
      real: real,
      demo: DemoLeaderboardRepository(),
      isDemo: () => isDemo,
    );
    expect((await s.myCommunities()).single.name, 'Real Place');
    isDemo = true;
    expect((await s.myCommunities()).length, 3);
  });

  test('the demo switch is remembered', () async {
    final dir = Directory.systemTemp.createTempSync('maidan_demo');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/settings.json');
    final s = await AppSettings.load(() async => file);
    expect(s.demoData, isFalse);
    s.setDemoData(true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect((await AppSettings.load(() async => file)).demoData, isTrue);
  });

  testWidgets('demo mode fills the rankings tab and says so', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = AppSettings(demoData: true);
    await tester.pumpWidget(
      MaidanApp(
        settings: settings,
        boards: FakeLeaderboardRepository(), // empty: proves the demo is used
        runs: FakeRunRepository(),
        location: (_) => FakeLocationSource(),
        repository: FakeExamRepository(),
        auth: FakeAuthService(),
        profiles: FakeProfileRepository(),
        training: FakeTrainingRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('रैंकिंग').last);
    await tester.pumpAndSettle();
    expect(find.text('डेमो डेटा'), findsOneWidget);
    expect(find.text('Ghatampur Ground'), findsOneWidget);
    expect(find.text('Test U. (आप)'), findsOneWidget);

    // Turning it off goes back to the real (empty) board straight away.
    settings.setDemoData(false);
    await tester.pumpAndSettle();
    expect(find.text('डेमो डेटा'), findsNothing);
    expect(find.text('Test U. (आप)'), findsNothing);
  });
}
