import 'package:supabase_flutter/supabase_flutter.dart';

import 'training_models.dart';

/// Why a plan request failed; codes come from the training-plan function.
class TrainingException implements Exception {
  const TrainingException(this.code, {this.unlocksOn});

  /// rate_limited | ai_not_configured | ai_busy | generation_failed | too_early |
  /// profile_incomplete | plan_complete | network | unknown
  final String code;
  final String? unlocksOn;

  @override
  String toString() => 'TrainingException($code)';
}

abstract class TrainingRepository {
  Future<TrainingPlan?> fetchActivePlan();

  /// Generates a new plan with AI; can take a minute or two.
  Future<void> createPlan(TrainingAnswers answers);

  /// Generates the next week from the logs.
  Future<void> generateNextWeek(int planId);

  Future<void> saveLog(int planId, SessionLog log);
  Future<List<TimeTrial>> fetchTimeTrials(String examId);
  Future<void> addTimeTrial(String examId, TimeTrial trial);
}

class SupabaseTrainingRepository implements TrainingRepository {
  SupabaseTrainingRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  @override
  Future<TrainingPlan?> fetchActivePlan() async {
    final plan = await _client
        .from('training_plans')
        .select(
          'id, exam_id, start_date, weeks_total, run_distance_m, target_seconds, outline',
        )
        .eq('user_id', _uid)
        .eq('status', 'active')
        .maybeSingle();
    if (plan == null) return null;
    final id = plan['id'] as int;
    final results = await Future.wait([
      _client
          .from('plan_weeks')
          .select('week_number, sessions')
          .eq('plan_id', id)
          .order('week_number'),
      _client
          .from('session_logs')
          .select(
            'week_number, session_index, status, distance_km, duration_seconds, effort, pain, note',
          )
          .eq('plan_id', id),
    ]);
    return TrainingPlan.fromRows(plan, results[0], results[1]);
  }

  Future<void> _invoke(Map<String, dynamic> body) async {
    try {
      await _client.functions.invoke('training-plan', body: body);
    } on FunctionException catch (e) {
      final details = e.details;
      final code = details is Map ? details['error'] as String? : null;
      final unlocks = details is Map ? details['unlocks_on'] as String? : null;
      throw TrainingException(code ?? 'unknown', unlocksOn: unlocks);
    } on Exception {
      throw const TrainingException('network');
    }
  }

  @override
  Future<void> createPlan(TrainingAnswers answers) =>
      _invoke({'action': 'create', 'answers': answers.toJson()});

  @override
  Future<void> generateNextWeek(int planId) =>
      _invoke({'action': 'next_week', 'plan_id': planId});

  @override
  Future<void> saveLog(int planId, SessionLog log) async {
    await _client.from('session_logs').upsert({
      'user_id': _uid,
      ...log.toRow(planId),
    }, onConflict: 'plan_id,week_number,session_index');
  }

  @override
  Future<List<TimeTrial>> fetchTimeTrials(String examId) async {
    final rows = await _client
        .from('time_trials')
        .select('distance_m, duration_seconds, recorded_on, source')
        .eq('user_id', _uid)
        .eq('exam_id', examId)
        .order('recorded_on');
    return rows.map(TimeTrial.fromRow).toList();
  }

  @override
  Future<void> addTimeTrial(String examId, TimeTrial trial) async {
    final d = trial.recordedOn;
    await _client.from('time_trials').insert({
      'user_id': _uid,
      'exam_id': examId,
      'distance_m': trial.distanceM,
      'duration_seconds': trial.durationSeconds,
      'recorded_on':
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      'source': trial.source,
    });
  }
}
