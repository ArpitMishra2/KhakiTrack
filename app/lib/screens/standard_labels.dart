import 'package:flutter/material.dart';

import '../data/exam_models.dart';
import '../l10n/app_localizations.dart';

String categoryLabel(AppLocalizations l10n, String category) =>
    switch (category) {
      'general' || 'general_obc_sc' => l10n.catGeneral,
      'st' => l10n.catSt,
      'st_ne_states' => l10n.catStNeStates,
      'st_lwe_districts' => l10n.catStLweDistricts,
      'garhwali_kumaoni_dogra_maratha_assam_hp_jk_ladakh' => l10n.catHillGroups,
      'ladakh_region' => l10n.catLadakh,
      'ne_states' => l10n.catNeStates,
      'gta' => l10n.catGta,
      'sc_st' => l10n.catScSt,
      'hill_areas' => l10n.catHillAreas,
      'police_ward' => l10n.catPoliceWard,
      _ => category,
    };

String _number(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// "4.8 किमी" or "800 मीटर".
String distanceText(AppLocalizations l10n, int metres) => metres >= 1000
    ? l10n.distanceKm(_number(metres / 1000))
    : l10n.distanceM('$metres');

/// 3.75 feet -> 3'9", 14 -> 14'.
String feetInches(double feet) {
  final whole = feet.floor();
  final inches = ((feet - whole) * 12).round();
  return inches == 0 ? "$whole'" : "$whole'$inches\"";
}

String eventLabel(AppLocalizations l10n, Standard s) {
  if (s.isRun) return l10n.eventRun(distanceText(l10n, s.runMetres ?? 0));
  return switch (s.event) {
    'height_cm' => l10n.eventHeight,
    'weight_kg' => l10n.eventWeight,
    'chest_unexpanded_cm' => l10n.eventChestUnexpanded,
    'chest_expanded_cm' => l10n.eventChestExpanded,
    'chest_expansion_cm' => l10n.eventChestExpansion,
    'long_jump_ft' => l10n.eventLongJump,
    'high_jump_ft' => l10n.eventHighJump,
    'pull_ups' => l10n.eventPullUps,
    'ditch_9ft' => l10n.eventDitch,
    'zigzag_balance' => l10n.eventZigzag,
    _ => s.event,
  };
}

/// The requirement as shown to the user, or [AppLocalizations.notConfirmed]
/// when the value is not from an official notice.
String valueLabel(AppLocalizations l10n, Standard s) {
  if (s.kind == 'qualify') {
    return s.verified ? l10n.mustPass : l10n.notConfirmed;
  }
  if (!s.isConfirmed) return l10n.notConfirmed;
  final v = s.value!;
  if (s.kind == 'count_min') return l10n.countAtLeast(v.round());
  if (s.event.endsWith('_ft')) return feetInches(v);
  if (s.kind == 'time_max_seconds') {
    final total = v.round();
    final minutes = total ~/ 60, seconds = total % 60;
    return seconds == 0
        ? l10n.timeMinutes(minutes)
        : l10n.timeMinutesSeconds(minutes, seconds);
  }
  return s.event.endsWith('_kg')
      ? l10n.valueKg(_number(v))
      : l10n.valueCm(_number(v));
}

/// Icon for a standard's row.
IconData eventIcon(Standard s) {
  if (s.isRun) return Icons.directions_run;
  return switch (s.event) {
    'height_cm' => Icons.height,
    'weight_kg' => Icons.monitor_weight_outlined,
    'chest_unexpanded_cm' ||
    'chest_expanded_cm' ||
    'chest_expansion_cm' => Icons.accessibility_new,
    'long_jump_ft' => Icons.sports_gymnastics,
    'high_jump_ft' => Icons.north,
    'pull_ups' => Icons.fitness_center,
    'ditch_9ft' => Icons.swap_horiz,
    'zigzag_balance' => Icons.timeline,
    _ => Icons.rule,
  };
}
