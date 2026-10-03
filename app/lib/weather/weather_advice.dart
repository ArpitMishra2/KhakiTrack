import 'weather_models.dart';

enum RunLevel { good, caution, avoid }

/// The main thing to tell the runner about.
enum Reason { fine, heat, storm, rain, smog, cold, fog, sun }

enum Tip {
  water,
  ors,
  cap,
  lightClothes,
  warmLayer,
  longWarmup,
  grip,
  bright,
  keepEasy,
  indoors,
}

class Advice {
  const Advice({
    required this.level,
    required this.reason,
    required this.tips,
    required this.bestAt,
    required this.bestIsNow,
  });

  final RunLevel level;
  final Reason reason;
  final List<Tip> tips;

  /// Best hour to run in the next day (null when no hour qualifies).
  final DateTime? bestAt;

  /// Now is already about as good as it gets today.
  final bool bestIsNow;
}

bool _isThunder(int code) => code == 95 || code == 96 || code == 99;
bool _isRain(int code) =>
    (code >= 51 && code <= 67) || (code >= 80 && code <= 82);
bool _isFog(int code) => code == 45 || code == 48;

/// Turns the current conditions into a verdict, what to carry or wear, and
/// the best hour to run. Plain thresholds (no medical claims): heat uses the
/// "feels like" temperature, air uses the US AQI bands.
Advice adviseFor(Weather w) {
  final feels = w.feelsC;
  final aqi = w.aqi ?? 0;

  Reason reason;
  RunLevel level;
  if (_isThunder(w.code)) {
    level = RunLevel.avoid;
    reason = Reason.storm;
  } else if (feels >= 40) {
    level = RunLevel.avoid;
    reason = Reason.heat;
  } else if (aqi >= 200) {
    level = RunLevel.avoid;
    reason = Reason.smog;
  } else if (feels >= 33) {
    level = RunLevel.caution;
    reason = Reason.heat;
  } else if (aqi >= 101) {
    level = RunLevel.caution;
    reason = Reason.smog;
  } else if (_isRain(w.code) || w.rainMm >= 0.2) {
    level = RunLevel.caution;
    reason = Reason.rain;
  } else if (feels <= 5) {
    level = RunLevel.caution;
    reason = Reason.cold;
  } else if (_isFog(w.code)) {
    level = RunLevel.caution;
    reason = Reason.fog;
  } else if (w.uv >= 8 && w.isDay) {
    level = RunLevel.caution;
    reason = Reason.sun;
  } else {
    level = RunLevel.good;
    reason = Reason.fine;
  }

  final tips = <Tip>[];
  if (level == RunLevel.avoid) tips.add(Tip.indoors);
  if (feels >= 28) tips.add(Tip.water);
  if (feels >= 34 || (w.humidity >= 70 && feels >= 30)) tips.add(Tip.ors);
  if (w.isDay && (w.uv >= 6 || feels >= 32)) tips.add(Tip.cap);
  if (feels >= 30) tips.add(Tip.lightClothes);
  if (feels <= 12) tips.add(Tip.warmLayer);
  if (feels <= 8) tips.add(Tip.longWarmup);
  if (_isRain(w.code) || w.rainMm >= 0.2) tips.add(Tip.grip);
  if (!w.isDay || _isFog(w.code)) tips.add(Tip.bright);
  if (aqi >= 101 || level == RunLevel.caution && reason == Reason.heat) {
    tips.add(Tip.keepEasy);
  }

  // Best hour: lowest "feels like" among dry daytime hours from now on.
  HourPoint? best;
  for (final p in w.hours) {
    if (p.time.isBefore(
      DateTime(w.now.year, w.now.month, w.now.day, w.now.hour),
    )) {
      continue;
    }
    if (p.time.isAfter(w.now.add(const Duration(hours: 24)))) continue;
    if (p.time.hour < 5 || p.time.hour > 19) continue;
    if (p.rainChance >= 40) continue;
    if (best == null || p.feelsC < best.feelsC) best = p;
  }
  final nowGood = level == RunLevel.good;
  final bestIsNow = best == null
      ? false
      : nowGood &&
            w.feelsC - best.feelsC <= 1.5 &&
            w.now.hour >= 5 &&
            w.now.hour <= 19;
  return Advice(
    level: level,
    reason: reason,
    tips: tips,
    bestAt: bestIsNow ? null : best?.time,
    bestIsNow: bestIsNow,
  );
}
