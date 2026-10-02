// GPS run analysis and cheat detection, rules version 1.
//
// Mirrors supabase/functions/submit-run/analysis.ts exactly; the rules and
// their reasons are in data/gps_traces/README.md. Both are tested against
// the traces in data/gps_traces. Change both together.

import 'dart:math';

class TrackPoint {
  const TrackPoint({
    required this.tMs,
    required this.lat,
    required this.lon,
    required this.accuracy,
    this.mock = false,
  });

  factory TrackPoint.fromJson(Map<String, dynamic> j) => TrackPoint(
    tMs: (j['t'] as num).toInt(),
    lat: (j['lat'] as num).toDouble(),
    lon: (j['lon'] as num).toDouble(),
    accuracy: (j['acc'] as num).toDouble(),
    mock: j['mock'] as bool? ?? false,
  );

  /// Milliseconds since the run started.
  final int tMs;
  final double lat;
  final double lon;

  /// Horizontal accuracy in metres (68% confidence), as reported by the OS.
  final double accuracy;
  final bool mock;

  Map<String, dynamic> toJson() => {
    't': tMs,
    'lat': lat,
    'lon': lon,
    'acc': accuracy,
    'mock': mock,
  };
}

abstract final class Rules {
  static const version = 1;
  static const maxAccuracyM = 30.0;
  static const maxDroppedFraction = 0.30;
  static const jitterM = 2.0;
  static const smoothRadius = 2;
  static const smoothWindowS = 10.0;
  static const teleportMinM = 50.0;
  static const teleportSpeed = 12.0;
  static const gapS = 20.0;
  static const gapMaxM = 200.0;
  static const gapLongS = 45.0;
  static const gapMaxFraction = 0.15;
  static const sprintWindowS = 30.0;
  static const sprintMaxSpeed = 9.0;
  static const vehicleWindowS = 180.0;
  static const vehicleMaxSpeed = 6.0;
  static const averageMinM = 1500.0;
  static const averageMaxSpeed = 6.2;
  static const minPointsPerS = 0.1;
  static const minDurationS = 60.0;
  static const minDistanceM = 200.0;
}

const rejectFlags = {
  'mock_location',
  'teleport',
  'impossible_speed',
  'vehicle_like',
  'implausible_average',
};

class RunAnalysis {
  const RunAnalysis({
    required this.verdict,
    required this.flags,
    required this.distanceM,
    required this.durationS,
    required this.finishSeconds,
    required this.keptPoints,
  });

  /// verified | suspicious | rejected
  final String verdict;
  final List<String> flags;
  final double distanceM;
  final double durationS;

  /// Time at which [targetM] was reached, or null.
  final double? finishSeconds;
  final int keptPoints;

  bool get isVerified => verdict == 'verified';
}

/// Great-circle distance in metres.
double haversineM(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371008.8;
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a =
      pow(sin(dLat / 2), 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLon / 2), 2);
  return 2 * r * asin(min(1, sqrt(a)));
}

RunAnalysis analyseRun(List<TrackPoint> input, {int? targetM}) {
  final flags = <String>{};

  // 1. Sort, drop repeated timestamps.
  final sorted = [...input]..sort((a, b) => a.tMs.compareTo(b.tMs));
  final pts = <TrackPoint>[];
  for (final p in sorted) {
    if (pts.isEmpty || p.tMs != pts.last.tMs) pts.add(p);
  }

  // 2. Mock locations.
  if (pts.any((p) => p.mock)) flags.add('mock_location');

  // 3. Accuracy.
  final accurate = pts.where((p) => p.accuracy <= Rules.maxAccuracyM).toList();
  if (pts.isNotEmpty &&
      (pts.length - accurate.length) / pts.length > Rules.maxDroppedFraction) {
    flags.add('poor_signal');
  }

  final durationS = pts.length < 2
      ? 0.0
      : (pts.last.tMs - pts.first.tMs) / 1000;

  // 4 and 6. Teleports and gaps, on the raw accurate points. A step is a
  // break (no smoothing across it) if it is a teleport or a gap.
  final teleportBefore = List<bool>.filled(accurate.length, false);
  final breakBefore = List<bool>.filled(accurate.length, false);
  var gapTime = 0.0;
  for (var i = 1; i < accurate.length; i++) {
    final a = accurate[i - 1], b = accurate[i];
    final d = haversineM(a.lat, a.lon, b.lat, b.lon);
    final dt = (b.tMs - a.tMs) / 1000;
    if (d > Rules.teleportMinM && d / dt > Rules.teleportSpeed) {
      flags.add('teleport');
      teleportBefore[i] = true;
      breakBefore[i] = true;
    }
    if (dt > Rules.gapS) {
      gapTime += dt;
      breakBefore[i] = true;
      if (d > Rules.gapMaxM || dt > Rules.gapLongS) flags.add('signal_gap');
    }
  }
  if (durationS > 0 && gapTime / durationS > Rules.gapMaxFraction) {
    flags.add('signal_gap');
  }

  // 5. Smooth within unbroken stretches, then skip jitter under 2 m.
  final sLat = List<double>.filled(accurate.length, 0);
  final sLon = List<double>.filled(accurate.length, 0);
  // Symmetric: the same number of neighbours on each side, so the ends of
  // the run and the edges of gaps are not pulled in one direction.
  int reach(int i, int dir) {
    var k = 0;
    while (k < Rules.smoothRadius) {
      final j = i + dir * (k + 1);
      if (j < 0 || j >= accurate.length) break;
      if (breakBefore[dir < 0 ? j + 1 : j]) break;
      if ((accurate[j].tMs - accurate[i].tMs).abs() / 1000 >
          Rules.smoothWindowS) {
        break;
      }
      k++;
    }
    return k;
  }

  for (var i = 0; i < accurate.length; i++) {
    final m = min(reach(i, -1), reach(i, 1));
    var lat = 0.0, lon = 0.0;
    for (var j = i - m; j <= i + m; j++) {
      lat += accurate[j].lat;
      lon += accurate[j].lon;
    }
    sLat[i] = lat / (2 * m + 1);
    sLon[i] = lon / (2 * m + 1);
  }

  final kept = <TrackPoint>[];
  final cum = <double>[];
  var lastKept = -1;
  for (var i = 0; i < accurate.length; i++) {
    if (lastKept < 0) {
      lastKept = i;
      kept.add(accurate[i]);
      cum.add(0);
      continue;
    }
    final d = haversineM(sLat[lastKept], sLon[lastKept], sLat[i], sLon[i]);
    var teleported = false;
    for (var k = lastKept + 1; k <= i; k++) {
      teleported |= teleportBefore[k];
    }
    if (d < Rules.jitterM && !breakBefore[i]) continue;
    kept.add(accurate[i]);
    cum.add(cum.last + (teleported ? 0 : d));
    lastKept = i;
  }

  // 7-8. Window speeds: for each end point, the earliest start within the
  // window, measured over at least half the window to avoid tiny spans.
  void windowCheck(double windowS, double maxSpeed, String flag) {
    var start = 0;
    for (var end = 1; end < kept.length; end++) {
      while (start < end &&
          (kept[end].tMs - kept[start].tMs) / 1000 > windowS) {
        start++;
      }
      final span = (kept[end].tMs - kept[start].tMs) / 1000;
      if (span >= windowS / 2 && (cum[end] - cum[start]) / span > maxSpeed) {
        flags.add(flag);
        return;
      }
    }
  }

  windowCheck(Rules.sprintWindowS, Rules.sprintMaxSpeed, 'impossible_speed');
  windowCheck(Rules.vehicleWindowS, Rules.vehicleMaxSpeed, 'vehicle_like');

  final distanceM = cum.isEmpty ? 0.0 : cum.last;
  // 9. Average.
  if (distanceM >= Rules.averageMinM &&
      durationS > 0 &&
      distanceM / durationS > Rules.averageMaxSpeed) {
    flags.add('implausible_average');
  }
  // 10. Sampling.
  if (durationS > 0 && accurate.length / durationS < Rules.minPointsPerS) {
    flags.add('sparse_samples');
  }
  // 11. Too short.
  if (durationS < Rules.minDurationS || distanceM < Rules.minDistanceM) {
    flags.add('too_short');
  }

  // 12. Finish time, interpolated within the crossing step.
  double? finish;
  if (targetM != null && kept.isNotEmpty) {
    final t0 = pts.first.tMs;
    for (var i = 1; i < kept.length; i++) {
      if (cum[i] >= targetM && cum[i] > cum[i - 1]) {
        final frac = (targetM - cum[i - 1]) / (cum[i] - cum[i - 1]);
        final ta = (kept[i - 1].tMs - t0) / 1000;
        final tb = (kept[i].tMs - t0) / 1000;
        finish = ta + frac * (tb - ta);
        break;
      }
    }
  }

  final ordered = flags.toList()..sort();
  return RunAnalysis(
    verdict: ordered.any(rejectFlags.contains)
        ? 'rejected'
        : ordered.isEmpty
        ? 'verified'
        : 'suspicious',
    flags: ordered,
    distanceM: distanceM,
    durationS: durationS,
    finishSeconds: finish,
    keptPoints: kept.length,
  );
}
