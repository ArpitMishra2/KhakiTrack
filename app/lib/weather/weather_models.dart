/// One forecast hour.
class HourPoint {
  const HourPoint({
    required this.time,
    required this.feelsC,
    required this.rainChance,
    required this.uv,
  });

  /// Local time at the place, hour start.
  final DateTime time;
  final double feelsC;

  /// Percent, 0 to 100.
  final int rainChance;
  final double uv;
}

/// Conditions at one place right now, plus the next day or so by the hour.
class Weather {
  const Weather({
    required this.now,
    required this.tempC,
    required this.feelsC,
    required this.humidity,
    required this.rainMm,
    required this.code,
    required this.isDay,
    required this.uv,
    required this.aqi,
    required this.hours,
  });

  /// Local time at the place when this was measured.
  final DateTime now;
  final double tempC;
  final double feelsC;
  final int humidity;
  final double rainMm;

  /// WMO weather code (0 clear, 45 fog, 61 rain, 95 thunderstorm ...).
  final int code;
  final bool isDay;
  final double uv;

  /// US AQI, or null when the air-quality service did not answer.
  final int? aqi;
  final List<HourPoint> hours;

  /// Parses the Open-Meteo forecast answer, with [aqi] from the air-quality
  /// service when it was available.
  factory Weather.fromOpenMeteo(Map<String, dynamic> forecast, {int? aqi}) {
    final cur = forecast['current'] as Map<String, dynamic>;
    final h = forecast['hourly'] as Map<String, dynamic>;
    final times = (h['time'] as List).cast<String>();
    final feels = (h['apparent_temperature'] as List);
    final rain = (h['precipitation_probability'] as List);
    final uv = (h['uv_index'] as List);
    final now = DateTime.parse(cur['time'] as String);
    final hours = [
      for (var i = 0; i < times.length; i++)
        HourPoint(
          time: DateTime.parse(times[i]),
          feelsC: (feels[i] as num?)?.toDouble() ?? 0,
          rainChance: (rain[i] as num?)?.toInt() ?? 0,
          uv: (uv[i] as num?)?.toDouble() ?? 0,
        ),
    ];
    final thisHour = hours.where(
      (p) =>
          p.time.year == now.year &&
          p.time.month == now.month &&
          p.time.day == now.day &&
          p.time.hour == now.hour,
    );
    return Weather(
      now: now,
      tempC: (cur['temperature_2m'] as num).toDouble(),
      feelsC: (cur['apparent_temperature'] as num).toDouble(),
      humidity: (cur['relative_humidity_2m'] as num).toInt(),
      rainMm: (cur['precipitation'] as num?)?.toDouble() ?? 0,
      code: (cur['weather_code'] as num).toInt(),
      isDay: (cur['is_day'] as num?) == 1,
      uv: thisHour.isEmpty ? 0 : thisHour.first.uv,
      aqi: aqi,
      hours: hours,
    );
  }
}

enum WeatherStatus {
  ready,

  /// Location permission not given yet: ask.
  needsPermission,

  /// Permission refused for good, or the phone's location is off.
  blocked,

  /// Network or service trouble.
  failed,
}

class WeatherResult {
  const WeatherResult(this.status, [this.weather]);

  final WeatherStatus status;
  final Weather? weather;
}
