import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/gps/location_source.dart';
import 'package:maidan/l10n/app_localizations.dart';
import 'package:maidan/weather/weather_advice.dart';
import 'package:maidan/weather/weather_card.dart';
import 'package:maidan/weather/weather_models.dart';
import 'package:maidan/weather/weather_service.dart';

import 'fake_gps.dart';

Weather weather({
  double feels = 30,
  int humidity = 50,
  double rain = 0,
  int code = 0,
  bool isDay = true,
  double uv = 3,
  int? aqi = 60,
  DateTime? now,
  List<HourPoint> hours = const [],
}) => Weather(
  now: now ?? DateTime(2026, 6, 10, 15),
  tempC: feels,
  feelsC: feels,
  humidity: humidity,
  rainMm: rain,
  code: code,
  isDay: isDay,
  uv: uv,
  aqi: aqi,
  hours: hours,
);

List<HourPoint> day(DateTime start, double Function(int hour) feels) => [
  for (var i = 0; i < 48; i++)
    HourPoint(
      time: start.add(Duration(hours: i)),
      feelsC: feels(start.add(Duration(hours: i)).hour),
      rainChance: 0,
      uv: 3,
    ),
];

void main() {
  group('verdict', () {
    test('mild and clean is good, with no scary advice', () {
      final a = adviseFor(weather(feels: 24));
      expect(a.level, RunLevel.good);
      expect(a.reason, Reason.fine);
      expect(a.tips, isNot(contains(Tip.indoors)));
    });

    test('hot afternoon: caution, water, ORS, cap, light clothes', () {
      final a = adviseFor(weather(feels: 37, humidity: 40));
      expect(a.level, RunLevel.caution);
      expect(a.reason, Reason.heat);
      expect(
        a.tips,
        containsAll([
          Tip.water,
          Tip.ors,
          Tip.cap,
          Tip.lightClothes,
          Tip.keepEasy,
        ]),
      );
    });

    test('extreme heat, storms and very poor air say skip it', () {
      expect(adviseFor(weather(feels: 41)).level, RunLevel.avoid);
      expect(adviseFor(weather(code: 95)).reason, Reason.storm);
      expect(adviseFor(weather(code: 95)).tips, contains(Tip.indoors));
      final smog = adviseFor(weather(feels: 22, aqi: 230));
      expect(smog.level, RunLevel.avoid);
      expect(smog.reason, Reason.smog);
    });

    test('poor air, rain, cold and fog are cautions with the right tips', () {
      expect(adviseFor(weather(feels: 22, aqi: 130)).reason, Reason.smog);
      final rain = adviseFor(weather(feels: 24, code: 61));
      expect(rain.reason, Reason.rain);
      expect(rain.tips, contains(Tip.grip));
      final cold = adviseFor(weather(feels: 4));
      expect(cold.reason, Reason.cold);
      expect(cold.tips, containsAll([Tip.warmLayer, Tip.longWarmup]));
      final fog = adviseFor(weather(feels: 10, code: 45, isDay: false));
      expect(fog.reason, Reason.fog);
      expect(fog.tips, contains(Tip.bright));
    });

    test('a missing air reading never blocks advice', () {
      expect(adviseFor(weather(feels: 24, aqi: null)).level, RunLevel.good);
    });
  });

  group('best time', () {
    final start = DateTime(2026, 6, 10, 0);
    // Cool at dawn, hot by day, cooling in the evening.
    double curve(int h) => switch (h) {
      <= 6 => 26,
      <= 9 => 29,
      <= 17 => 38,
      _ => 31,
    };

    test('a hot afternoon points at the cool early morning', () {
      final a = adviseFor(
        weather(
          feels: 38,
          hours: day(start, curve),
          now: DateTime(2026, 6, 10, 15),
        ),
      );
      expect(a.bestIsNow, isFalse);
      expect(a.bestAt, DateTime(2026, 6, 11, 5)); // tomorrow, first cool hour
    });

    test('already the best hour of the day: say so', () {
      final a = adviseFor(
        weather(
          feels: 26,
          hours: day(start, curve),
          now: DateTime(2026, 6, 10, 5),
        ),
      );
      expect(a.bestIsNow, isTrue);
      expect(a.bestAt, isNull);
    });

    test('rainy hours are never suggested', () {
      final hours = [
        for (final p in day(start, curve))
          HourPoint(
            time: p.time,
            feelsC: p.feelsC,
            rainChance: p.time.hour == 5 ? 80 : 0,
            uv: 3,
          ),
      ];
      final a = adviseFor(
        weather(feels: 38, hours: hours, now: DateTime(2026, 6, 10, 15)),
      );
      expect(a.bestAt!.hour, isNot(5));
    });
  });

  group('service', () {
    const forecast = {
      'current': {
        'time': '2026-06-10T15:00',
        'temperature_2m': 39.4,
        'apparent_temperature': 41.2,
        'relative_humidity_2m': 28,
        'precipitation': 0.0,
        'weather_code': 1,
        'is_day': 1,
      },
      'hourly': {
        'time': ['2026-06-10T14:00', '2026-06-10T15:00', '2026-06-10T16:00'],
        'apparent_temperature': [40.0, 41.2, 40.1],
        'precipitation_probability': [0, 0, 10],
        'uv_index': [8.5, 7.9, 6.0],
      },
    };

    test('parses the forecast and picks this hour for UV', () {
      final w = Weather.fromOpenMeteo(forecast, aqi: 180);
      expect(w.tempC, 39.4);
      expect(w.feelsC, 41.2);
      expect(w.humidity, 28);
      expect(w.isDay, isTrue);
      expect(w.uv, 7.9);
      expect(w.aqi, 180);
      expect(w.hours, hasLength(3));
      expect(adviseFor(w).level, RunLevel.avoid);
    });

    test(
      'asks both services, survives an air-quality failure, and caches',
      () async {
        var calls = 0;
        final svc = OpenMeteoWeatherService(
          FakeLocationSource(),
          get: (uri) async {
            calls++;
            if (uri.host.startsWith('air-quality')) throw Exception('down');
            return jsonEncode(forecast);
          },
        );
        final r = await svc.load();
        expect(r.status, WeatherStatus.ready);
        expect(r.weather!.aqi, isNull);
        expect(calls, 2);
        await svc.load(); // fresh: no new requests
        expect(calls, 2);
      },
    );

    test('permission states are reported, not thrown', () async {
      Future<WeatherStatus> status(LocationAccess a, {bool ask = false}) async {
        final svc = OpenMeteoWeatherService(
          FakeLocationSource(access: a),
          get: (_) async => jsonEncode(forecast),
        );
        return (await svc.load(askPermission: ask)).status;
      }

      expect(
        await status(LocationAccess.denied),
        WeatherStatus.needsPermission,
      );
      expect(await status(LocationAccess.serviceOff), WeatherStatus.blocked);
      expect(await status(LocationAccess.deniedForever), WeatherStatus.blocked);
      expect(await status(LocationAccess.granted), WeatherStatus.ready);
    });

    test('a network failure is a failed result', () async {
      final svc = OpenMeteoWeatherService(
        FakeLocationSource(),
        get: (_) async => throw Exception('offline'),
      );
      expect((await svc.load()).status, WeatherStatus.failed);
    });
  });

  group('card', () {
    Widget app(WeatherService service) => WeatherScope(
      service: service,
      child: MaterialApp(
        locale: const Locale('hi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: WeatherCard(now: DateTime(2026, 6, 10, 15)),
          ),
        ),
      ),
    );

    testWidgets('shows temperature, verdict, tips and best time', (
      tester,
    ) async {
      final start = DateTime(2026, 6, 10, 0);
      await tester.pumpWidget(
        app(
          _FakeService(
            WeatherResult(
              WeatherStatus.ready,
              weather(
                feels: 38,
                humidity: 40,
                hours: day(start, (h) => h <= 6 ? 26 : (h <= 17 ? 38 : 31)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('38°'), findsOneWidget);
      expect(find.text('संभलकर दौड़ें'), findsOneWidget);
      expect(find.text('पानी साथ रखें'), findsOneWidget);
      expect(
        find.textContaining('सबसे अच्छा समय: कल सुबह 5 बजे'),
        findsOneWidget,
      );
    });

    testWidgets('asks for location, then shows the weather', (tester) async {
      final svc = _FakeService(
        const WeatherResult(WeatherStatus.needsPermission),
      )..afterAsk = WeatherResult(WeatherStatus.ready, weather(feels: 24));
      await tester.pumpWidget(app(svc));
      await tester.pumpAndSettle();
      expect(find.text('मौसम देखें'), findsOneWidget);
      await tester.tap(find.text('मौसम देखें'));
      await tester.pumpAndSettle();
      expect(svc.asked, isTrue);
      expect(find.text('दौड़ने के लिए अच्छा मौसम'), findsOneWidget);
    });

    testWidgets('failure offers a retry', (tester) async {
      final svc = _FakeService(const WeatherResult(WeatherStatus.failed));
      await tester.pumpWidget(app(svc));
      await tester.pumpAndSettle();
      expect(find.text('मौसम नहीं मिला'), findsOneWidget);
      expect(find.text('फिर कोशिश करें'), findsOneWidget);
    });

    testWidgets('without a service the clock-based nudge still shows', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('hi'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: WeatherCard(now: DateTime(2026, 6, 10, 13))),
        ),
      );
      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    });
  });
}

class _FakeService implements WeatherService {
  _FakeService(this.result);

  final WeatherResult result;
  WeatherResult? afterAsk;
  bool asked = false;

  @override
  Future<WeatherResult> load({bool askPermission = false}) async {
    if (askPermission) {
      asked = true;
      return afterAsk ?? result;
    }
    return result;
  }
}
