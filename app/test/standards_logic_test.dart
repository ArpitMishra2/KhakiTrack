import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/data/exam_models.dart';
import 'package:maidan/data/standards_logic.dart';

import 'fake_exam_repository.dart';

Map<String, double?> resolved(List<Standard> all, String g, String c) => {
  for (final s in resolveStandards(all, g, c)) s.event: s.value,
};

void main() {
  final up = loadDataFile('up_police_constable');
  final ssc = loadDataFile('ssc_gd');

  test('every data row is confirmed from an official source', () {
    for (final s in [...up, ...ssc]) {
      expect(s.isConfirmed, isTrue, reason: '${s.category} ${s.event}');
    }
  });

  group('UP Police', () {
    test('default category is general_obc_sc', () {
      expect(defaultCategory(up), 'general_obc_sc');
      expect(categoriesFor(up, 'male'), ['general_obc_sc', 'st']);
      expect(categoriesFor(up, 'female'), ['general_obc_sc', 'st']);
    });

    test('male general', () {
      expect(resolved(up, 'male', 'general_obc_sc'), {
        'height_cm': 168,
        'chest_unexpanded_cm': 79,
        'chest_expanded_cm': 84,
        'chest_expansion_cm': 5,
        'run_4800m': 1500,
      });
    });

    test('female ST gets relaxed height, shared weight and run', () {
      expect(resolved(up, 'female', 'st'), {
        'height_cm': 147,
        'weight_kg': 40,
        'run_2400m': 840,
      });
    });
  });

  group('SSC GD', () {
    test('male general', () {
      expect(resolved(ssc, 'male', 'general'), {
        'height_cm': 170,
        'chest_unexpanded_cm': 80,
        'chest_expansion_cm': 5,
        'run_5000m': 1440,
      });
    });

    test('female general runs 1.6 km in 8.5 min', () {
      expect(resolved(ssc, 'female', 'general'), {
        'height_cm': 157,
        'run_1600m': 510,
      });
    });

    test('ST of NE states: own height, ST chest, general run', () {
      expect(resolved(ssc, 'male', 'st_ne_states'), {
        'height_cm': 157,
        'chest_unexpanded_cm': 76,
        'chest_expansion_cm': 5,
        'run_5000m': 1440,
      });
    });

    test('NE states and GTA share the 77 cm chest row', () {
      expect(resolved(ssc, 'male', 'ne_states')['chest_unexpanded_cm'], 77);
      expect(resolved(ssc, 'male', 'gta')['chest_unexpanded_cm'], 77);
      expect(resolved(ssc, 'male', 'gta')['height_cm'], 157);
    });

    test('Ladakh: hill-group height and chest, Ladakh race only', () {
      expect(resolved(ssc, 'male', 'ladakh_region'), {
        'height_cm': 165,
        'chest_unexpanded_cm': 78,
        'chest_expansion_cm': 5,
        'run_1600m': 420,
      });
      expect(resolved(ssc, 'female', 'ladakh_region'), {
        'height_cm': 155,
        'run_800m': 300,
      });
    });

    test('helper categories are not offered', () {
      final cats = categoriesFor(ssc, 'male');
      expect(cats.first, 'general');
      expect(cats, isNot(contains('ne_states_and_gta')));
      expect(cats, isNot(contains('all')));
      expect(cats, contains('ladakh_region'));
    });
  });

  test('unverified values are never shown as confirmed', () {
    final s = Standard.fromJson({
      'gender': 'male',
      'category': 'all',
      'event': 'run_4800m',
      'kind': 'time_max_seconds',
      'value': null,
      'source_url': null,
      'verified': false,
    });
    expect(s.isConfirmed, isFalse);
    expect(s.runMetres, 4800);
  });
}
