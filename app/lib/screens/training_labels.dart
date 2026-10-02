import 'package:intl/intl.dart';

import '../data/training_logic.dart';
import '../data/training_models.dart';
import '../data/training_repository.dart';
import '../l10n/app_localizations.dart';

String sessionTypeLabel(AppLocalizations l10n, String type) => switch (type) {
  'easy_run' => l10n.typeEasyRun,
  'run_walk' => l10n.typeRunWalk,
  'long_run' => l10n.typeLongRun,
  'tempo' => l10n.typeTempo,
  'intervals' => l10n.typeIntervals,
  'time_trial' => l10n.typeTimeTrial,
  'strength' => l10n.typeStrength,
  'mobility' => l10n.typeMobility,
  _ => type,
};

String readinessLabel(AppLocalizations l10n, String readiness) =>
    switch (readiness) {
      'on_track' => l10n.readinessOnTrack,
      'big_gap' => l10n.readinessBigGap,
      _ => l10n.readinessNeedsWork,
    };

String statusLabel(AppLocalizations l10n, String status) => switch (status) {
  'done' => l10n.statusDone,
  'partial' => l10n.statusPartial,
  _ => l10n.statusMissed,
};

String _num(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

/// "5 किमी · 40 मिनट · 6:30 प्रति किमी", leaving out what is not set.
String sessionSummary(AppLocalizations l10n, PlanSession s) => [
  if (s.distanceKm != null && s.distanceKm! > 0) l10n.km(_num(s.distanceKm!)),
  if (s.durationMin != null) l10n.minutesShort(_num(s.durationMin!)),
  if (s.targetPaceSecPerKm != null)
    l10n.pacePerKm(formatDuration(s.targetPaceSecPerKm!)),
].join(' · ');

String shortDate(AppLocalizations l10n, DateTime d) =>
    DateFormat('EEE, d MMM', l10n.localeName).format(d);

String trainingErrorText(AppLocalizations l10n, TrainingException e) =>
    switch (e.code) {
      'rate_limited' => l10n.errRateLimited,
      'ai_not_configured' => l10n.errAiNotConfigured,
      'ai_busy' => l10n.errAiBusy,
      'too_early' => l10n.errTooEarly(
        e.unlocksOn == null
            ? ''
            : shortDate(l10n, DateTime.parse(e.unlocksOn!)),
      ),
      'network' => l10n.errNetwork,
      _ => l10n.errGeneration,
    };
