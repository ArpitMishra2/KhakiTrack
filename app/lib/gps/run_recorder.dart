import 'dart:async';

import 'package:flutter/foundation.dart';

import 'location_source.dart';
import 'run_analysis.dart';

/// Records one run: collects fixes, keeps live numbers, and stops itself
/// when a mock PET reaches its target distance.
class RunRecorder extends ChangeNotifier {
  RunRecorder({required this.source, this.targetM, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final LocationSource source;

  /// Mock PET distance; the run stops by itself once it is reached.
  final int? targetM;
  final DateTime Function() _clock;

  final List<TrackPoint> points = [];
  StreamSubscription<TrackPoint>? _sub;
  DateTime? startedAt;
  RunAnalysis? live;
  RunAnalysis? result;
  bool get running => _sub != null;
  bool get finished => result != null;

  /// Latest fix accuracy in metres, for the "waiting for GPS" check.
  double? get lastAccuracy => points.isEmpty ? null : points.last.accuracy;

  int _lastAnalysedCount = 0;

  void start() {
    if (running || finished) return;
    startedAt = _clock();
    _sub = source.track(startedAt!).listen(_onPoint);
    notifyListeners();
  }

  void _onPoint(TrackPoint p) {
    points.add(p);
    // Re-analyse at most once per new second of data; cheap at 1 Hz.
    if (points.length - _lastAnalysedCount >= 1) {
      _lastAnalysedCount = points.length;
      live = analyseRun(points, targetM: targetM);
      if (targetM != null && live!.finishSeconds != null) {
        stop();
        return;
      }
    }
    notifyListeners();
  }

  /// Seconds since start by the wall clock, for the on-screen timer.
  double get elapsedS => startedAt == null
      ? 0
      : _clock().difference(startedAt!).inMilliseconds / 1000;

  /// Average speed over the last [windowS] seconds of fixes, m/s.
  double? recentSpeed({double windowS = 30}) {
    final a = live;
    if (a == null || points.length < 2) return null;
    final end = points.last.tMs;
    final startIdx = points.indexWhere((p) => end - p.tMs <= windowS * 1000);
    if (startIdx < 0 || startIdx >= points.length - 1) return null;
    final seg = analyseRun(points.sublist(startIdx));
    if (seg.durationS <= 0) return null;
    return seg.distanceM / seg.durationS;
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    result = analyseRun(points, targetM: targetM);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Mock PET outcome, with a margin for GPS error: within 3% of the
/// cut-off is reported as borderline rather than a pass.
enum PetOutcome { qualified, borderline, notQualified, incomplete }

PetOutcome petOutcome(double? finishSeconds, num targetSeconds) {
  if (finishSeconds == null) return PetOutcome.incomplete;
  if (finishSeconds <= targetSeconds * 0.97) return PetOutcome.qualified;
  if (finishSeconds <= targetSeconds) return PetOutcome.borderline;
  return PetOutcome.notQualified;
}

/// Seconds ahead (+) or behind (-) the even pace needed to finish [targetM]
/// in [targetSeconds], given [distanceM] covered after [elapsedS].
double paceDelta(
  double distanceM,
  double elapsedS,
  int targetM,
  num targetSeconds,
) {
  final expected = distanceM / targetM * targetSeconds;
  return expected - elapsedS;
}
