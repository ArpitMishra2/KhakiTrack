import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../gps/location_source.dart';
import 'weather_models.dart';

/// Gets live weather for where the user is.
abstract class WeatherService {
  /// [askPermission]: show the phone's location prompt if needed. Without it,
  /// a user who has not allowed location gets [WeatherStatus.needsPermission].
  Future<WeatherResult> load({bool askPermission = false});
}

/// Open-Meteo (open-meteo.com): no account or key. Free for non-commercial
/// use, so a paid or ad-supported release needs their commercial plan.
class OpenMeteoWeatherService implements WeatherService {
  OpenMeteoWeatherService(
    this._location, {
    Future<String> Function(Uri uri)? get,
    DateTime Function()? clock,
  }) : _get = get ?? _httpGet,
       _clock = clock ?? DateTime.now;

  final LocationSource _location;
  final Future<String> Function(Uri uri) _get;
  final DateTime Function() _clock;

  static const _freshFor = Duration(minutes: 20);
  ({String key, DateTime at, Weather weather})? _cache;

  static Future<String> _httpGet(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 8));
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      return await res.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
  }

  @override
  Future<WeatherResult> load({bool askPermission = false}) async {
    final access = askPermission
        ? await _location.ensureAccess()
        : await _location.checkAccess();
    switch (access) {
      case LocationAccess.granted:
        break;
      case LocationAccess.denied:
        return const WeatherResult(WeatherStatus.needsPermission);
      case LocationAccess.deniedForever:
      case LocationAccess.serviceOff:
        return const WeatherResult(WeatherStatus.blocked);
    }
    final pos = await _location.coarsePosition();
    if (pos == null) return const WeatherResult(WeatherStatus.failed);

    // About 10 km squares are plenty for weather and let us reuse answers.
    final key = '${pos.lat.toStringAsFixed(1)},${pos.lon.toStringAsFixed(1)}';
    final c = _cache;
    if (c != null && c.key == key && _clock().difference(c.at) < _freshFor) {
      return WeatherResult(WeatherStatus.ready, c.weather);
    }
    try {
      final lat = pos.lat.toStringAsFixed(3), lon = pos.lon.toStringAsFixed(3);
      final results = await Future.wait<Object?>([
        _get(
          Uri.https('api.open-meteo.com', '/v1/forecast', {
            'latitude': lat,
            'longitude': lon,
            'current':
                'temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,weather_code,is_day',
            'hourly': 'apparent_temperature,precipitation_probability,uv_index',
            'timezone': 'auto',
            'forecast_days': '2',
          }),
        ),
        _get(
          Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
            'latitude': lat,
            'longitude': lon,
            'current': 'us_aqi',
          }),
        ).then<Object?>((v) => v).catchError((_) => null),
      ]);
      int? aqi;
      final air = results[1];
      if (air is String) {
        try {
          aqi = (((jsonDecode(air) as Map)['current'] as Map)['us_aqi'] as num?)
              ?.round();
        } on Object {
          aqi = null; // Weather is still useful without it.
        }
      }
      final weather = Weather.fromOpenMeteo(
        jsonDecode(results[0]! as String) as Map<String, dynamic>,
        aqi: aqi,
      );
      _cache = (key: key, at: _clock(), weather: weather);
      return WeatherResult(WeatherStatus.ready, weather);
    } on Object {
      return const WeatherResult(WeatherStatus.failed);
    }
  }
}

/// Makes the weather service available to cards without passing it through
/// every screen. Absent in tests, where cards fall back to the clock.
class WeatherScope extends InheritedWidget {
  const WeatherScope({super.key, required this.service, required super.child});

  final WeatherService service;

  static WeatherService? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<WeatherScope>()?.service;

  @override
  bool updateShouldNotify(WeatherScope old) => service != old.service;
}
