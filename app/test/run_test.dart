import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/gps/location_source.dart';
import 'package:maidan/gps/run_recorder.dart';
import 'package:maidan/gps/run_repository.dart';
import 'package:maidan/l10n/app_localizations.dart';
import 'package:maidan/screens/run_screen.dart';

import 'fake_gps.dart';

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('hi'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);

Future<void> pumpRun(
  WidgetTester tester, {
  required FakeLocationSource source,
  required FakeRunRepository runs,
  bool mockPet = true,
  int runMetres = 5000,
  int targetSeconds = 1440,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(
      RunScreen(
        key: UniqueKey(),
        examId: 'ssc_gd',
        runMetres: runMetres,
        targetSeconds: targetSeconds,
        mockPet: mockPet,
        source: source,
        runs: runs,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Lets a GPS fix arrive (stream delivery) and the screen rebuild.
Future<void> firstFix(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 10));
}

/// Feeds a trace into the running screen, a few points per frame.
Future<void> replay(
  WidgetTester tester,
  FakeLocationSource source,
  String trace,
) async {
  final pts = tracePoints(trace);
  for (var i = 0; i < pts.length; i++) {
    if (source.current!.isClosed) break;
    source.emit(pts[i]);
    if (i % 50 == 0) await tester.pump();
  }
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  group('RunRecorder', () {
    test('a mock PET stops by itself at the target distance', () async {
      final source = FakeLocationSource();
      final r = RunRecorder(source: source, targetM: 5000);
      r.start();
      for (final p in tracePoints('good_5000_ssc.json')) {
        if (r.finished) break;
        source.emit(p);
        await Future<void>.delayed(Duration.zero);
      }
      expect(r.finished, isTrue);
      expect(r.result!.verdict, 'verified');
      expect(r.result!.finishSeconds, closeTo(1368.5, 1));
      // Stopped well before the trace ended.
      expect(r.points.length, lessThan(1441));
    });

    test('outcome uses a 3% margin for GPS error', () {
      expect(petOutcome(1368, 1440), PetOutcome.qualified);
      expect(petOutcome(1396, 1440), PetOutcome.qualified); // 3.1% inside
      expect(petOutcome(1400, 1440), PetOutcome.borderline); // 2.8% inside
      expect(petOutcome(1440, 1440), PetOutcome.borderline);
      expect(petOutcome(1441, 1440), PetOutcome.notQualified);
      expect(petOutcome(null, 1440), PetOutcome.incomplete);
    });

    test('pace delta is positive when ahead of even pace', () {
      // 2500 m of 5000 m in 700 s against a 1440 s target: 20 s ahead.
      expect(paceDelta(2500, 700, 5000, 1440), 20);
      expect(paceDelta(2500, 730, 5000, 1440), -10);
    });
  });

  testWidgets('mock PET: GPS warm-up, live run, qualified result', (
    tester,
  ) async {
    final source = FakeLocationSource();
    final runs = FakeRunRepository(
      verdict: const ServerVerdict(
        verdict: 'verified',
        flags: [],
        finishSeconds: 1368.5,
      ),
    );
    await pumpRun(tester, source: source, runs: runs);
    expect(find.text('GPS सिग्नल ढूंढ रहे हैं…'), findsOneWidget);

    source.emit(tracePoints('good_5000_ssc.json').first);
    await firstFix(tester);
    expect(find.textContaining('GPS तैयार है'), findsOneWidget);
    await tester.tap(find.text('शुरू करें'));
    await tester.pump();
    expect(find.text('रोकने के लिए दबाकर रखें'), findsOneWidget);

    await replay(tester, source, 'good_5000_ssc.json');
    expect(find.text('आप क्वालीफाई करते!'), findsOneWidget);
    expect(find.textContaining('5 किमी का समय: 22:49'), findsOneWidget);
    expect(find.text('GPS जांच: सही'), findsOneWidget);
    expect(find.text('सर्वर जांच पूरी'), findsOneWidget);

    final sent = runs.submitted.single;
    expect(sent.mode, 'mock_pet');
    expect(sent.targetM, 5000);
    expect(sent.examId, 'ssc_gd');
    expect(sent.clientVerdict, 'verified');
    expect(source.tracks, 2); // warm-up stream, then the recording
  });

  testWidgets('a bicycle ride is rejected and explained', (tester) async {
    final source = FakeLocationSource();
    final runs = FakeRunRepository(
      verdict: const ServerVerdict(
        verdict: 'rejected',
        flags: ['vehicle_like'],
        finishSeconds: null,
      ),
    );
    await pumpRun(tester, source: source, runs: runs, mockPet: false);
    source.emit(tracePoints('bicycle.json').first);
    await firstFix(tester);
    await tester.tap(find.text('शुरू करें'));
    await tester.pump();
    await replay(tester, source, 'bicycle.json');
    await tester.longPress(find.text('रोकने के लिए दबाकर रखें'));
    await tester.pumpAndSettle();
    expect(find.text('GPS जांच: अमान्य'), findsOneWidget);
    expect(find.textContaining('गाड़ी/साइकिल'), findsOneWidget);
    expect(find.textContaining('नहीं गिनी जाएगी'), findsOneWidget);
    expect(runs.submitted.single.clientVerdict, 'rejected');
  });

  testWidgets('offline: the run is kept for later', (tester) async {
    final source = FakeLocationSource();
    final runs = FakeRunRepository(offline: true);
    await pumpRun(
      tester,
      source: source,
      runs: runs,
      runMetres: 4800,
      targetSeconds: 1500,
    );
    source.emit(tracePoints('good_4800_steady.json').first);
    await firstFix(tester);
    await tester.tap(find.text('शुरू करें'));
    await tester.pump();
    await replay(tester, source, 'good_4800_steady.json');
    // 1496.8 s against 1500 s is inside the 3% GPS margin: borderline.
    expect(find.textContaining('सीमा पर'), findsOneWidget);
    expect(find.textContaining('इंटरनेट नहीं है'), findsOneWidget);
    expect(runs.pending, hasLength(1));
  });

  testWidgets('no permission: explains and offers settings', (tester) async {
    final source = FakeLocationSource(access: LocationAccess.deniedForever);
    await pumpRun(tester, source: source, runs: FakeRunRepository());
    expect(find.textContaining('लोकेशन की अनुमति'), findsOneWidget);
    await tester.tap(find.text('सेटिंग खोलें'));
    expect(source.settingsOpened, isTrue);

    final off = FakeLocationSource(access: LocationAccess.serviceOff);
    await pumpRun(tester, source: off, runs: FakeRunRepository());
    expect(find.textContaining('लोकेशन (GPS) चालू करें'), findsOneWidget);
  });

  testWidgets('live and result screens fit a 320 px phone at 1.3x text', (
    tester,
  ) async {
    final source = FakeLocationSource();
    final runs = FakeRunRepository();
    await pumpRun(tester, source: source, runs: runs);
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final pts = tracePoints('good_5000_ssc.json');
    source.emit(pts.first);
    await firstFix(tester);
    await tester.tap(find.text('शुरू करें'));
    await tester.pump();
    for (var i = 0; i < 400; i++) {
      source.emit(pts[i]);
      if (i % 50 == 0) await tester.pump();
    }
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('लक्ष्य से'), findsOneWidget);
    await tester.longPress(find.text('रोकने के लिए दबाकर रखें'));
    await tester.pumpAndSettle();
    expect(find.text('दूरी पूरी नहीं हुई'), findsOneWidget);
    expect(runs.submitted, hasLength(1));
  });
}
