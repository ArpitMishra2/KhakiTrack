import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/data/app_settings.dart';
import 'package:maidan/data/heat.dart';
import 'package:maidan/gps/pacer.dart';
import 'package:maidan/l10n/app_localizations.dart';
import 'package:maidan/screens/heat_banner.dart';
import 'package:maidan/screens/settings_screen.dart';

import 'fake_auth_service.dart';

void main() {
  group('Pacer', () {
    // 5 km in 24 min: 288 s per km.
    Pacer pacer() => Pacer(targetM: 5000, targetSeconds: 1440);

    test('stays quiet on pace, ahead, or too early', () {
      final p = pacer();
      expect(p.shouldBuzz(100, 60), isFalse); // too early
      expect(p.shouldBuzz(1000, 280), isFalse); // ahead
      expect(p.shouldBuzz(1000, 300), isFalse); // 12 s behind, within slack
    });

    test('buzzes when behind, then waits for the cooldown', () {
      final p = pacer();
      expect(p.shouldBuzz(1000, 320), isTrue); // 32 s behind
      expect(p.shouldBuzz(1100, 350), isFalse); // 30 s later: cooling down
      expect(p.shouldBuzz(1500, 480), isTrue); // 160 s behind, 160 s later
    });

    test('stops once the distance is done', () {
      expect(pacer().shouldBuzz(5000, 2000), isFalse);
    });
  });

  test('heat hours: 10 to 18 from March to October', () {
    expect(isHeatHour(DateTime(2026, 5, 10, 11)), isTrue);
    expect(isHeatHour(DateTime(2026, 5, 10, 17, 59)), isTrue);
    expect(isHeatHour(DateTime(2026, 5, 10, 18)), isFalse);
    expect(isHeatHour(DateTime(2026, 5, 10, 7)), isFalse);
    expect(isHeatHour(DateTime(2026, 12, 10, 12)), isFalse);
  });

  test('settings survive a restart and ignore a broken file', () async {
    final dir = Directory.systemTemp.createTempSync('maidan_settings');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/settings.json');
    final s = await AppSettings.load(() async => file);
    expect(s.locale.languageCode, 'hi');
    expect(s.lowData, isFalse);
    s
      ..setLanguage('en')
      ..setLowData(true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final again = await AppSettings.load(() async => file);
    expect(again.locale.languageCode, 'en');
    expect(again.lowData, isTrue);

    file.writeAsStringSync('not json');
    final broken = await AppSettings.load(() async => file);
    expect(broken.locale.languageCode, 'hi');
  });

  Widget app(Widget home, {AppSettings? settings}) {
    final s = settings ?? AppSettings();
    return ListenableBuilder(
      listenable: s,
      builder: (_, _) => SettingsScope(
        settings: s,
        child: MaterialApp(
          locale: s.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: home,
        ),
      ),
    );
  }

  testWidgets('heat banner shows only in the hot hours', (tester) async {
    await tester.pumpWidget(app(HeatBanner(now: DateTime(2026, 5, 10, 12))));
    expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    await tester.pumpWidget(app(HeatBanner(now: DateTime(2026, 5, 10, 6))));
    await tester.pump();
    expect(find.byIcon(Icons.wb_sunny), findsNothing);
  });

  testWidgets('settings switch language and low-data mode', (tester) async {
    final settings = AppSettings();
    await tester.pumpWidget(
      app(SettingsScreen(auth: FakeAuthService()), settings: settings),
    );
    expect(find.text('सेटिंग्स'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(settings.lowData, isTrue);
  });
}
