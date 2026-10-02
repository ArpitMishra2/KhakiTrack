import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/gps/run_analysis.dart';

/// Every trace in data/gps_traces must produce its expected result.
void main() {
  final files =
      Directory('../data/gps_traces')
          .listSync()
          .whereType<File>()
          .where(
            (f) => f.path.endsWith('.json') && !f.path.endsWith('golden.json'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test(
    'trace folder is not empty',
    () => expect(files.length, greaterThan(10)),
  );

  for (final f in files) {
    final trace = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final name = f.uri.pathSegments.last;
    test('$name: ${trace['description']}', () {
      final points = (trace['points'] as List)
          .cast<Map<String, dynamic>>()
          .map(TrackPoint.fromJson)
          .toList();
      final r = analyseRun(points, targetM: trace['target_m'] as int?);
      final e = trace['expected'] as Map<String, dynamic>;
      final why =
          'verdict ${r.verdict}, flags ${r.flags}, distance ${r.distanceM.round()} m, finish ${r.finishSeconds?.round()} s';

      expect(r.verdict, e['verdict'], reason: why);
      expect(r.flags, containsAll(e['flags'] as List), reason: why);
      if (e['verdict'] == 'verified') expect(r.flags, isEmpty, reason: why);
      final dist = e['distance_m'] as List?;
      if (dist != null) {
        expect(r.distanceM, inInclusiveRange(dist[0], dist[1]), reason: why);
      }
      if (e.containsKey('finish_seconds')) {
        final fin = e['finish_seconds'] as List?;
        if (fin == null) {
          if (e['verdict'] == 'verified') {
            expect(r.finishSeconds, isNull, reason: why);
          }
        } else {
          expect(r.finishSeconds, isNotNull, reason: why);
          expect(
            r.finishSeconds,
            inInclusiveRange(fin[0], fin[1]),
            reason: why,
          );
        }
      }
    });
  }

  test('matches the golden results shared with the server analyser', () {
    final golden =
        (jsonDecode(File('../data/gps_traces/golden.json').readAsStringSync())
                as Map<String, dynamic>)['results']
            as Map<String, dynamic>;
    expect(
      golden.keys.toSet(),
      files.map((f) => f.uri.pathSegments.last).toSet(),
    );
    for (final f in files) {
      final name = f.uri.pathSegments.last;
      final trace = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final r = analyseRun(
        (trace['points'] as List)
            .cast<Map<String, dynamic>>()
            .map(TrackPoint.fromJson)
            .toList(),
        targetM: trace['target_m'] as int?,
      );
      final g = golden[name] as Map<String, dynamic>;
      expect(r.verdict, g['verdict'], reason: name);
      expect(r.flags, g['flags'], reason: name);
      expect(r.distanceM, closeTo(g['distance_m'] as num, 0.5), reason: name);
      final gf = g['finish_seconds'] as num?;
      if (gf == null) {
        expect(r.finishSeconds, isNull, reason: name);
      } else {
        expect(r.finishSeconds, closeTo(gf, 0.05), reason: name);
      }
    }
  });

  test('haversine matches a known distance', () {
    // One degree of latitude is about 111.2 km.
    expect(haversineM(26, 80, 27, 80), closeTo(111195, 50));
  });

  test('finish time is interpolated inside the crossing step', () {
    // Straight line north, 10 m every 2 s, so 5 m/s; 100 m reached at 20 s.
    final pts = [
      for (var i = 0; i <= 60; i++)
        TrackPoint(
          tMs: i * 2000,
          lat: 26 + i * 10 / 111195,
          lon: 80,
          accuracy: 5,
        ),
    ];
    final r = analyseRun(pts, targetM: 105);
    expect(r.finishSeconds, closeTo(21, 0.1));
    expect(r.verdict, 'verified');
  });
}
