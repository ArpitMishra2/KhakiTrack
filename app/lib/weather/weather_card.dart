import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../l10n/app_localizations.dart';
import '../screens/heat_banner.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../theme/widgets.dart';
import 'weather_advice.dart';
import 'weather_models.dart';
import 'weather_service.dart';

/// Live weather where the user is, with a plain verdict, what to carry or
/// wear, and the best time to run. Without a weather service (tests) it
/// falls back to the clock-based hot-hours nudge.
class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key, required this.now});

  /// For the fallback only.
  final DateTime now;

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  Future<WeatherResult>? _result;
  WeatherService? _service;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service = WeatherScope.maybeOf(context);
    // Low-data mode waits for a tap instead of fetching on its own.
    if (!_started && _service != null && !SettingsScope.lowDataOf(context)) {
      _started = true;
      _result = _service!.load();
    }
  }

  void _load({bool ask = false}) {
    setState(() {
      _started = true;
      _result = _service!.load(askPermission: ask);
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    if (service == null) return HeatBanner(now: widget.now);
    final l10n = AppLocalizations.of(context);
    final result = _result;
    if (result == null) {
      return _Message(
        icon: Icons.cloud_outlined,
        text: l10n.weatherAsk,
        action: l10n.weatherLoad,
        onAction: () => _load(),
      );
    }
    return FutureBuilder<WeatherResult>(
      future: result,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _Skeleton();
        }
        final r = snap.data;
        if (snap.hasError || r == null) {
          return _Message(
            icon: Icons.cloud_off,
            text: l10n.weatherFailed,
            action: l10n.retry,
            onAction: () => _load(),
          );
        }
        return switch (r.status) {
          WeatherStatus.ready => FadeSlideIn(child: _Body(weather: r.weather!)),
          WeatherStatus.needsPermission => _Message(
            icon: Icons.location_on_outlined,
            text: l10n.weatherAsk,
            action: l10n.weatherAllow,
            onAction: () => _load(ask: true),
          ),
          WeatherStatus.blocked => _Message(
            icon: Icons.location_off,
            text: l10n.gpsOff,
            action: l10n.retry,
            onAction: () => _load(ask: true),
          ),
          WeatherStatus.failed => _Message(
            icon: Icons.cloud_off,
            text: l10n.weatherFailed,
            action: l10n.retry,
            onAction: () => _load(),
          ),
        };
      },
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 96,
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Brand.khakiSoft,
              ),
              child: Icon(icon, color: Brand.olive),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.titleSmall),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: onAction,
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final w = weather;
    final advice = adviseFor(w);
    final colors = switch (advice.level) {
      RunLevel.good => const [Brand.olive, Brand.oliveDeep],
      RunLevel.caution => const [Color(0xFF7A5A12), Color(0xFF3F2E08)],
      RunLevel.avoid => const [Color(0xFF8A2A22), Color(0xFF3F1410)],
    };
    final facts = [
      l10n.weatherFeels(w.feelsC.round().toString()),
      l10n.weatherHumidity(w.humidity),
      if (w.aqi != null) l10n.weatherAqi(w.aqi!),
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
                child: Icon(_icon(w), size: 32, color: Brand.saffron),
              ),
              const SizedBox(width: 14),
              Text(
                '${w.tempC.round()}°',
                style: numerals(60, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _condition(l10n, w),
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      facts,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _verdict(l10n, advice.level),
            style: textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            _reason(l10n, advice.reason, w),
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          if (advice.tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in advice.tips)
                  _TipChip(icon: _tipIcon(t), label: _tip(l10n, t)),
              ],
            ),
          ],
          if (advice.bestIsNow || advice.bestAt != null) ...[
            const SizedBox(height: 14),
            Pill(
              advice.bestIsNow
                  ? l10n.bestNow
                  : l10n.bestAt(
                      advice.bestAt!.day == w.now.day
                          ? l10n.dayToday
                          : l10n.dayTomorrow,
                      _hour(l10n, advice.bestAt!.hour),
                    ),
              icon: Icons.schedule,
              background: Brand.saffron,
              foreground: Brand.ink,
            ),
          ],
        ],
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  const _TipChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Brand.khaki),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

String _hour(AppLocalizations l10n, int hour) {
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  if (hour < 12) return l10n.hourMorning(h12);
  if (hour < 17) return l10n.hourDay(h12);
  return l10n.hourEvening(h12);
}

String _condition(AppLocalizations l10n, Weather w) {
  final c = w.code;
  if (c == 0 || c == 1) return w.isDay ? l10n.condClear : l10n.condClearNight;
  if (c == 2 || c == 3) return l10n.condCloudy;
  if (c == 45 || c == 48) return l10n.condFog;
  if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82)) return l10n.condRain;
  if (c >= 95) return l10n.condStorm;
  return l10n.condOther;
}

IconData _icon(Weather w) {
  final c = w.code;
  if (c == 0 || c == 1) {
    return w.isDay ? Icons.wb_sunny : Icons.nightlight_round;
  }
  if (c == 45 || c == 48) {
    return Icons.foggy;
  }
  if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82)) {
    return Icons.umbrella;
  }
  if (c >= 95) {
    return Icons.thunderstorm;
  }
  return Icons.cloud;
}

String _verdict(AppLocalizations l10n, RunLevel level) => switch (level) {
  RunLevel.good => l10n.verdictGood,
  RunLevel.caution => l10n.verdictCaution,
  RunLevel.avoid => l10n.verdictAvoid,
};

String _reason(AppLocalizations l10n, Reason r, Weather w) => switch (r) {
  Reason.fine => l10n.reasonFine,
  Reason.heat => l10n.reasonHeat,
  Reason.storm => l10n.reasonStorm,
  Reason.rain => l10n.reasonRain,
  Reason.smog => l10n.reasonSmog(w.aqi ?? 0),
  Reason.cold => l10n.reasonCold,
  Reason.fog => l10n.reasonFog,
  Reason.sun => l10n.reasonSun,
};

String _tip(AppLocalizations l10n, Tip t) => switch (t) {
  Tip.water => l10n.tipWater,
  Tip.ors => l10n.tipOrs,
  Tip.cap => l10n.tipCap,
  Tip.lightClothes => l10n.tipLight,
  Tip.warmLayer => l10n.tipWarm,
  Tip.longWarmup => l10n.tipWarmup,
  Tip.grip => l10n.tipGrip,
  Tip.bright => l10n.tipBright,
  Tip.keepEasy => l10n.tipEasy,
  Tip.indoors => l10n.tipIndoors,
};

IconData _tipIcon(Tip t) => switch (t) {
  Tip.water => Icons.water_drop,
  Tip.ors => Icons.local_drink,
  Tip.cap => Icons.wb_sunny_outlined,
  Tip.lightClothes => Icons.checkroom,
  Tip.warmLayer => Icons.ac_unit,
  Tip.longWarmup => Icons.accessibility_new,
  Tip.grip => Icons.hiking,
  Tip.bright => Icons.highlight,
  Tip.keepEasy => Icons.speed,
  Tip.indoors => Icons.home,
};
