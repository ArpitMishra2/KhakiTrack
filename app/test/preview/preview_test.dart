// Renders the main screens to PNG files so the look can be reviewed without
// a phone. Skipped unless PREVIEW_DIR is set:
//   PREVIEW_DIR=/some/dir PREVIEW_FONTS=/dir/with/NotoSansDevanagari.ttf \
//     flutter test test/preview/preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/data/app_settings.dart';
import 'package:maidan/data/leaderboard_repository.dart';
import 'package:maidan/data/profile.dart';
import 'package:maidan/data/training_models.dart';
import 'package:maidan/gps/run_repository.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:maidan/gps/pacer.dart';
import 'package:maidan/l10n/app_localizations.dart';
import 'package:maidan/main.dart';
import 'package:maidan/weather/weather_models.dart';
import 'package:maidan/weather/weather_service.dart';
import 'package:maidan/screens/run_screen.dart';
import 'package:maidan/theme/app_theme.dart';

import '../fake_auth_service.dart';
import '../fake_exam_repository.dart';
import '../fake_gps.dart';
import '../fake_leaderboard_repository.dart';
import '../fake_profile_repository.dart';
import '../fake_training_repository.dart';

final _out = Platform.environment['PREVIEW_DIR'];
AppSettings _settings() =>
    AppSettings(locale: Locale(Platform.environment['PREVIEW_LANG'] ?? 'hi'));
final _fonts = Platform.environment['PREVIEW_FONTS'];

Future<void> _font(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    final f = File(p);
    if (f.existsSync()) {
      loader.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
    }
  }
  await loader.load();
}

Future<void> _shot(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? 'C:/src/flutter';
  final cache = '$flutterRoot/bin/cache/artifacts/material_fonts';
  await _font('MaterialIcons', ['$cache/materialicons-regular.otf']);
  // Hind covers Hindi and Latin in two weights; stands in for the phone's
  // own fonts under the default Android family name.
  await _font('Roboto', [
    if (_fonts != null) '$_fonts/Hind-Regular.ttf',
    if (_fonts != null) '$_fonts/Hind-Bold.ttf',
  ]);
  await _font('BarlowCondensed', [
    'assets/fonts/BarlowCondensed-ExtraBold.ttf',
  ]);
}

void main() {
  testWidgets('preview screens', (tester) async {
    await _loadFonts();
    tester.view.physicalSize = const Size(800, 1720);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    final now = DateTime.now();
    final training = FakeTrainingRepository(
      start: now,
      trials: [
        for (final (i, secs) in [1750, 1690, 1640, 1590].indexed)
          TimeTrial(
            distanceM: 4800,
            durationSeconds: secs,
            recordedOn: now.subtract(Duration(days: 21 - i * 7)),
            source: 'manual',
          ),
      ],
    )..plan = samplePlan(now);
    final boards = FakeLeaderboardRepository()
      ..addCommunity('Sajeti Gaon', join: true)
      ..addCommunity('Subah Ki Daud', group: true, join: true);
    boards.boards['all/pet/0'] = const [
      LeaderboardEntry(rank: 1, name: 'Vikas P.', value: 1290, isMe: false),
      LeaderboardEntry(rank: 2, name: 'Suresh Y.', value: 1344, isMe: false),
      LeaderboardEntry(rank: 3, name: 'Anil K.', value: 1401, isMe: false),
      LeaderboardEntry(rank: 4, name: 'Ramesh K.', value: 1450, isMe: true),
      LeaderboardEntry(rank: 5, name: 'Mohit S.', value: 1493, isMe: false),
    ];
    final runs = FakeRunRepository();
    for (var d = 0; d < 3; d++) {
      runs.runs.add(
        GpsRunSummary(
          mode: d == 0 ? 'mock_pet' : 'free',
          startedAt: now.subtract(Duration(days: d, hours: 4)),
          distanceM: 4800,
          durationS: 1590.0 + d * 30,
          finishSeconds: d == 0 ? 1590 : null,
          targetM: d == 0 ? 4800 : null,
          verdict: 'verified',
        ),
      );
    }
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaidanApp(
          weather: _PreviewWeather(),
          settings: _settings(),
          boards: boards,
          runs: runs,
          location: (_) => FakeLocationSource(),
          repository: FakeExamRepository(),
          auth: FakeAuthService(),
          profiles: FakeProfileRepository(),
          training: training,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _shot(tester, key, '1_training');
    for (final (i, name) in [
      '2_standards',
      '3_progress',
      '4_ranking',
    ].indexed) {
      final nav = find.byType(NavigationDestination).at(i + 1);
      await tester.tap(nav);
      await tester.pumpAndSettle();
      await _shot(tester, key, name);
    }
  }, skip: _out == null);

  testWidgets('preview run screen', (tester) async {
    await _loadFonts();
    tester.view.physicalSize = const Size(800, 1720);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    final source = FakeLocationSource();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('hi'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: RunScreen(
            examId: 'ssc_gd',
            runMetres: 5000,
            targetSeconds: 1440,
            mockPet: true,
            source: source,
            runs: FakeRunRepository(
              verdict: const ServerVerdict(
                verdict: 'verified',
                flags: [],
                finishSeconds: 1368.5,
              ),
            ),
            voice: FakeVoiceCoach(),
            buzzer: _NoBuzz(),
            now: DateTime(2026, 5, 10, 12),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final pts = tracePoints('good_5000_ssc.json');
    source.emit(pts.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    await _shot(tester, key, '5_run_warmup');
    await tester.tap(find.text('शुरू करें'));
    await tester.pump();
    for (var i = 0; i < 700; i++) {
      source.emit(pts[i]);
      if (i % 50 == 0) await tester.pump();
    }
    await tester.pump();
    await _shot(tester, key, '6_run_live');
    for (var i = 700; i < pts.length; i++) {
      if (source.current!.isClosed) break;
      source.emit(pts[i]);
      if (i % 50 == 0) await tester.pump();
    }
    await tester.pump();
    await tester.pumpAndSettle();
    await _shot(tester, key, '7_run_result');
  }, skip: _out == null);
  _onboardingTests();
  _secondaryTests();
}

Future<void> _pumpShell(
  WidgetTester tester,
  GlobalKey key, {
  required FakeAuthService auth,
  required FakeProfileRepository profiles,
}) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaidanApp(
        settings: _settings(),
        boards: FakeLeaderboardRepository(),
        runs: FakeRunRepository(),
        location: (_) => FakeLocationSource(),
        repository: FakeExamRepository(),
        auth: auth,
        profiles: profiles,
        training: FakeTrainingRepository(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1720);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void _onboardingTests() {
  testWidgets('preview sign-in', (tester) async {
    await _loadFonts();
    _phone(tester);
    final key = GlobalKey();
    await _pumpShell(
      tester,
      key,
      auth: FakeAuthService(signedIn: false),
      profiles: FakeProfileRepository(),
    );
    await _shot(tester, key, '0_signin');
  }, skip: _out == null);

  testWidgets('preview profile setup', (tester) async {
    await _loadFonts();
    _phone(tester);
    final key = GlobalKey();
    await _pumpShell(
      tester,
      key,
      auth: FakeAuthService(),
      profiles: FakeProfileRepository(const Profile()),
    );
    await _shot(tester, key, '8_profile');
  }, skip: _out == null);

  testWidgets('preview no plan yet', (tester) async {
    await _loadFonts();
    _phone(tester);
    final key = GlobalKey();
    await _pumpShell(
      tester,
      key,
      auth: FakeAuthService(),
      profiles: FakeProfileRepository(),
    );
    await _shot(tester, key, '9_training_intro');
  }, skip: _out == null);
}

void _secondaryTests() {
  testWidgets('preview secondary screens', (tester) async {
    await _loadFonts();
    _phone(tester);
    final key = GlobalKey();
    final now = DateTime.now();
    final boards = FakeLeaderboardRepository()
      ..addCommunity('Sajeti Gaon', join: true)
      ..addCommunity('Subah Ki Daud', group: true, join: true);
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaidanApp(
          settings: _settings(),
          boards: boards,
          runs: FakeRunRepository(),
          location: (_) => FakeLocationSource(),
          repository: FakeExamRepository(),
          auth: FakeAuthService(),
          profiles: FakeProfileRepository(),
          training: FakeTrainingRepository(start: now)..plan = samplePlan(now),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Session sheet.
    await tester.tap(find.text('4.8 किमी टाइम ट्रायल'));
    await tester.pumpAndSettle();
    await _shot(tester, key, '10_session_sheet');
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    // Settings.
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await _shot(tester, key, '11_settings');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    // Communities.
    await tester.tap(find.byType(NavigationDestination).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('इलाके / ग्रुप'));
    await tester.pumpAndSettle();
    await _shot(tester, key, '12_communities');
  }, skip: _out == null);

  testWidgets('preview questionnaire', (tester) async {
    await _loadFonts();
    _phone(tester);
    final key = GlobalKey();
    await _pumpShell(
      tester,
      key,
      auth: FakeAuthService(),
      profiles: FakeProfileRepository(),
    );
    await tester.tap(find.text('प्लान बनाना शुरू करें'));
    await tester.pumpAndSettle();
    await _shot(tester, key, '13_questionnaire');
    await tester.tap(find.text('हाँ'));
    await tester.pumpAndSettle();
    await _shot(tester, key, '14_questionnaire_yes');
  }, skip: _out == null);
}

class _PreviewWeather implements WeatherService {
  @override
  Future<WeatherResult> load({bool askPermission = false}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return WeatherResult(
      WeatherStatus.ready,
      Weather(
        now: DateTime(now.year, now.month, now.day, 15, 40),
        tempC: 31,
        feelsC: 36,
        humidity: 67,
        rainMm: 0,
        code: 1,
        isDay: true,
        uv: 7,
        aqi: 156,
        hours: [
          for (var i = 0; i < 48; i++)
            HourPoint(
              time: start.add(Duration(hours: i)),
              feelsC: switch (start.add(Duration(hours: i)).hour) {
                <= 6 => 25,
                <= 9 => 29,
                <= 17 => 36,
                _ => 30,
              }.toDouble(),
              rainChance: 0,
              uv: 3,
            ),
        ],
      ),
    );
  }
}

class _NoBuzz implements Buzzer {
  @override
  Future<void> buzz() async {}
}
