import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'run_analysis.dart';

/// A finished run waiting to be sent to the server.
class RunSubmission {
  RunSubmission({
    required this.examId,
    required this.mode,
    required this.targetM,
    required this.startedAt,
    required this.clientVerdict,
    required this.points,
    this.planId,
    this.weekNumber,
    this.sessionIndex,
  });

  factory RunSubmission.fromJson(Map<String, dynamic> j) => RunSubmission(
    examId: j['exam_id'] as String,
    mode: j['mode'] as String,
    targetM: j['target_m'] as int?,
    startedAt: DateTime.parse(j['started_at'] as String),
    clientVerdict: j['client_verdict'] as String?,
    points: (j['points'] as List)
        .cast<Map<String, dynamic>>()
        .map(TrackPoint.fromJson)
        .toList(),
    planId: j['plan_id'] as int?,
    weekNumber: j['week_number'] as int?,
    sessionIndex: j['session_index'] as int?,
  );

  final String examId;
  final String mode; // free | mock_pet | session
  final int? targetM;
  final DateTime startedAt;
  final String? clientVerdict;
  final List<TrackPoint> points;
  final int? planId;
  final int? weekNumber;
  final int? sessionIndex;

  Map<String, dynamic> toJson() => {
    'exam_id': examId,
    'mode': mode,
    'target_m': targetM,
    'plan_id': planId,
    'week_number': weekNumber,
    'session_index': sessionIndex,
    'started_at': startedAt.toUtc().toIso8601String(),
    'client_verdict': clientVerdict,
    'points': [for (final p in points) p.toJson()],
  };
}

/// The server's verdict for a submitted run.
class ServerVerdict {
  const ServerVerdict({
    required this.verdict,
    required this.flags,
    required this.finishSeconds,
  });

  final String verdict;
  final List<String> flags;
  final double? finishSeconds;
}

class GpsRunSummary {
  const GpsRunSummary({
    required this.mode,
    required this.startedAt,
    required this.distanceM,
    required this.durationS,
    required this.finishSeconds,
    required this.targetM,
    required this.verdict,
  });

  factory GpsRunSummary.fromRow(Map<String, dynamic> r) => GpsRunSummary(
    mode: r['mode'] as String,
    startedAt: DateTime.parse(r['started_at'] as String).toLocal(),
    distanceM: (r['distance_m'] as num).toDouble(),
    durationS: (r['duration_s'] as num).toDouble(),
    finishSeconds: (r['finish_seconds'] as num?)?.toDouble(),
    targetM: r['target_m'] as int?,
    verdict: r['verdict'] as String,
  );

  final String mode;
  final DateTime startedAt;
  final double distanceM;
  final double durationS;
  final double? finishSeconds;
  final int? targetM;
  final String verdict;
}

abstract class RunRepository {
  /// Sends a run; on a network failure it is kept and retried later, and
  /// null is returned.
  Future<ServerVerdict?> submit(RunSubmission run);

  /// Retries runs saved while offline; returns how many were sent.
  Future<int> flushPending();

  Future<int> pendingCount();
  Future<List<GpsRunSummary>> recentRuns();
}

class SupabaseRunRepository implements RunRepository {
  SupabaseRunRepository(this._client, {Future<Directory> Function()? dir})
    : _dir = dir ?? getApplicationDocumentsDirectory;

  final SupabaseClient _client;
  final Future<Directory> Function() _dir;

  Future<File> get _pendingFile async =>
      File('${(await _dir()).path}/pending_runs.json');

  Future<List<Map<String, dynamic>>> _readPending() async {
    final f = await _pendingFile;
    if (!await f.exists()) return [];
    try {
      return (jsonDecode(await f.readAsString()) as List)
          .cast<Map<String, dynamic>>();
    } on FormatException {
      return [];
    }
  }

  Future<void> _writePending(List<Map<String, dynamic>> runs) async {
    final f = await _pendingFile;
    await f.writeAsString(jsonEncode(runs));
  }

  Future<ServerVerdict> _send(Map<String, dynamic> body) async {
    final res = await _client.functions.invoke('submit-run', body: body);
    final data = res.data as Map<String, dynamic>;
    return ServerVerdict(
      verdict: data['verdict'] as String,
      flags: (data['flags'] as List).cast<String>(),
      finishSeconds: (data['finish_seconds'] as num?)?.toDouble(),
    );
  }

  @override
  Future<ServerVerdict?> submit(RunSubmission run) async {
    final body = run.toJson();
    try {
      return await _send(body);
    } on FunctionException catch (e) {
      // The server refused it (bad data or daily limit): do not retry.
      if (e.status >= 400 && e.status < 500) rethrow;
    } on Exception {
      // Network trouble: keep it for later.
    }
    await _writePending([...await _readPending(), body]);
    return null;
  }

  @override
  Future<int> flushPending() async {
    final pending = await _readPending();
    final left = <Map<String, dynamic>>[];
    var sent = 0;
    for (final body in pending) {
      try {
        await _send(body);
        sent++;
      } on FunctionException catch (e) {
        if (e.status < 400 || e.status >= 500) left.add(body);
      } on Exception {
        left.add(body);
      }
    }
    if (pending.isNotEmpty) await _writePending(left);
    return sent;
  }

  @override
  Future<int> pendingCount() async => (await _readPending()).length;

  @override
  Future<List<GpsRunSummary>> recentRuns() async {
    final rows = await _client
        .from('gps_runs')
        .select(
          'mode, started_at, distance_m, duration_s, finish_seconds, target_m, verdict',
        )
        .eq('user_id', _client.auth.currentUser!.id)
        .order('started_at', ascending: false)
        .limit(60);
    return rows.map(GpsRunSummary.fromRow).toList();
  }
}
