import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:maidan/gps/location_source.dart';
import 'package:maidan/gps/run_analysis.dart';
import 'package:maidan/gps/run_repository.dart';
import 'package:maidan/gps/voice_coach.dart';

List<TrackPoint> tracePoints(String name) {
  final t =
      jsonDecode(File('../data/gps_traces/$name').readAsStringSync())
          as Map<String, dynamic>;
  return (t['points'] as List)
      .cast<Map<String, dynamic>>()
      .map(TrackPoint.fromJson)
      .toList();
}

/// Each track() call opens a new stream the test feeds through [current].
class FakeLocationSource implements LocationSource {
  FakeLocationSource({this.access = LocationAccess.granted});

  LocationAccess access;
  StreamController<TrackPoint>? current;
  int tracks = 0;
  bool settingsOpened = false;

  @override
  Future<LocationAccess> ensureAccess() async => access;

  @override
  Stream<TrackPoint> track(DateTime start) {
    tracks++;
    current = StreamController<TrackPoint>();
    return current!.stream;
  }

  void emit(TrackPoint p) => current!.add(p);

  @override
  Future<void> openSettings() async => settingsOpened = true;
}

class FakeRunRepository implements RunRepository {
  FakeRunRepository({this.verdict, this.offline = false});

  /// What the "server" answers; null means echo the app's own verdict.
  ServerVerdict? verdict;
  bool offline;
  final List<RunSubmission> submitted = [];
  final List<RunSubmission> pending = [];
  final List<GpsRunSummary> runs = [];

  @override
  Future<ServerVerdict?> submit(RunSubmission run) async {
    submitted.add(run);
    if (offline) {
      pending.add(run);
      return null;
    }
    final v =
        verdict ??
        ServerVerdict(
          verdict: run.clientVerdict ?? 'verified',
          flags: const [],
          finishSeconds: null,
        );
    runs.insert(
      0,
      GpsRunSummary(
        mode: run.mode,
        startedAt: run.startedAt,
        distanceM: 5000,
        durationS: 1400,
        finishSeconds: v.finishSeconds,
        targetM: run.targetM,
        verdict: v.verdict,
      ),
    );
    return v;
  }

  @override
  Future<int> flushPending() async {
    if (offline) return 0;
    final n = pending.length;
    pending.clear();
    return n;
  }

  @override
  Future<int> pendingCount() async => pending.length;

  @override
  Future<List<GpsRunSummary>> recentRuns() async => [...runs];
}

/// Records what would have been spoken.
class FakeVoiceCoach implements VoiceCoach {
  final List<String> said = [];
  int stops = 0;

  @override
  Future<void> say(String text) async => said.add(text);

  @override
  Future<void> stop() async => stops++;
}
