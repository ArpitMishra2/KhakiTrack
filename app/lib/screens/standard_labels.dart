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
      _ => category,
    };

String _number(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// "4.8 किमी" or "800 मीटर".
String distanceText(AppLocalizations l10n, int metres) => metres >= 1000
    ? l10n.distanceKm(_number(metres / 1000))
    : l10n.distanceM('$metres');

String eventLabel(AppLocalizations l10n, Standard s) {
  if (s.isRun) return l10n.eventRun(distanceText(l10n, s.runMetres ?? 0));
  return switch (s.event) {
    'height_cm' => l10n.eventHeight,
    'weight_kg' => l10n.eventWeight,
    'chest_unexpanded_cm' => l10n.eventChestUnexpanded,
    'chest_expanded_cm' => l10n.eventChestExpanded,
    'chest_expansion_cm' => l10n.eventChestExpansion,
    _ => s.event,
  };
}

/// The requirement as shown to the user, or [AppLocalizations.notConfirmed]
/// when the value is not from an official notice.
String valueLabel(AppLocalizations l10n, Standard s) {
  if (!s.isConfirmed) return l10n.notConfirmed;
  final v = s.value!;
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
