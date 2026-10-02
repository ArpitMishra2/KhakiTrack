import 'exam_models.dart';

/// Categories a user can pick, in display order. Anything in the data that is
/// not listed here or in [_helperCategories] is shown last, by its raw key.
const categoryOrder = [
  'general',
  'general_obc_sc',
  'st',
  'st_ne_states',
  'st_lwe_districts',
  'garhwali_kumaoni_dogra_maratha_assam_hp_jk_ladakh',
  'ladakh_region',
  'ne_states',
  'gta',
];

/// Categories that exist in the data but are never picked directly:
/// `all` applies to everyone, `ne_states_and_gta` is the SSC chest row shared
/// by the NE states and GTA groups.
const _helperCategories = {'all', 'ne_states_and_gta'};

/// Where a category takes values it does not define itself, before `all` and
/// the exam's default category. Follows the SSC GD 2026 notice, para 12.5:
/// ST sub-groups fall back to ST (chest 76 cm applies to all ST candidates),
/// Ladakh is part of the Garhwali/.../Ladakh height and chest group, and the
/// NE states and GTA share one chest row.
const _fallbacks = {
  'st_ne_states': ['st'],
  'st_lwe_districts': ['st'],
  'ladakh_region': ['garhwali_kumaoni_dogra_maratha_assam_hp_jk_ladakh'],
  'ne_states': ['ne_states_and_gta'],
  'gta': ['ne_states_and_gta'],
};

/// Display order of events. Runs share one slot: a candidate runs one race.
const _eventOrder = [
  'height_cm',
  'weight_kg',
  'chest_unexpanded_cm',
  'chest_expanded_cm',
  'chest_expansion_cm',
  'run',
];

String _slot(Standard s) => s.isRun ? 'run' : s.event;

/// The category everyone falls back to: `general` (SSC GD) or
/// `general_obc_sc` (UP Police).
String? defaultCategory(List<Standard> standards) {
  final present = standards.map((s) => s.category).toSet();
  for (final c in const ['general', 'general_obc_sc']) {
    if (present.contains(c)) return c;
  }
  return null;
}

/// Categories offered to a user of [gender], in display order.
List<String> categoriesFor(List<Standard> standards, String gender) {
  final present = standards
      .where((s) => s.gender == gender)
      .map((s) => s.category)
      .where((c) => !_helperCategories.contains(c))
      .toSet();
  final def = defaultCategory(standards);
  if (def != null) present.add(def);
  int rank(String c) {
    final i = categoryOrder.indexOf(c);
    return i == -1 ? categoryOrder.length : i;
  }

  return present.toList()..sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    return r != 0 ? r : a.compareTo(b);
  });
}

/// The standards that apply to one candidate: for each event slot, the value
/// from the most specific matching category.
List<Standard> resolveStandards(
  List<Standard> standards,
  String gender,
  String category,
) {
  final chain = [
    category,
    ...?_fallbacks[category],
    'all',
    ?defaultCategory(standards),
  ];
  final bySlot = <String, Standard>{};
  for (final c in chain) {
    for (final s in standards) {
      if (s.gender == gender && s.category == c) {
        bySlot.putIfAbsent(_slot(s), () => s);
      }
    }
  }
  int rank(String slot) {
    final i = _eventOrder.indexOf(slot);
    return i == -1 ? _eventOrder.length : i;
  }

  return bySlot.values.toList()
    ..sort((a, b) => rank(_slot(a)).compareTo(rank(_slot(b))));
}

/// The standards category for a user's social category (`profiles.category`).
/// Only ST has its own relaxed standards in both notices; General, OBC, SC and
/// EWS all use the exam's default. Regional relaxations are picked by hand.
String? standardsCategoryFor(List<Standard> standards, String? social) {
  if (social == 'st' && standards.any((s) => s.category == 'st')) return 'st';
  return defaultCategory(standards);
}
