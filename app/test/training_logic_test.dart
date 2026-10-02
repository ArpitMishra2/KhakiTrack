import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/data/training_logic.dart';
import 'package:maidan/data/training_models.dart';

import 'fake_training_repository.dart';

void main() {
  final start = DateTime(2026, 10, 5); // a Monday
  final plan = samplePlan(start);

  test('current week counts from the start date and is clamped', () {
    expect(currentWeek(plan, DateTime(2026, 10, 1)), 1);
    expect(currentWeek(plan, start), 1);
    expect(currentWeek(plan, DateTime(2026, 10, 11, 23)), 1);
    expect(currentWeek(plan, DateTime(2026, 10, 12)), 2);
    expect(currentWeek(plan, DateTime(2027, 1, 1)), 4);
  });

  test('session dates follow plan day numbers', () {
    expect(sessionDate(plan, 1, 1), start);
    expect(sessionDate(plan, 2, 5), DateTime(2026, 10, 16));
  });

  test('next week unlocks two days before it starts, like the server', () {
    // Weeks 1-2 exist, so week 3 (starts 19 Oct) is next; unlocks 17 Oct.
    expect(weekToGenerate(plan, DateTime(2026, 10, 16)), isNull);
    expect(weekToGenerate(plan, DateTime(2026, 10, 17)), 3);
    expect(weekUnlocked(plan, 3, DateTime(2026, 10, 17)), isTrue);
  });

  test('no week to generate once the plan is complete', () {
    final full = TrainingPlan.fromRows(
      {
        'id': 1,
        'exam_id': 'ssc_gd',
        'start_date': '2026-10-05',
        'weeks_total': 2,
        'run_distance_m': 5000,
        'target_seconds': 1440,
        'outline': {
          'assessment': 'a',
          'readiness': 'on_track',
          'goal_note': 'g',
          'phases': <Map<String, dynamic>>[],
          'weeks': <Map<String, dynamic>>[],
          'safety_notes': <String>[],
          'see_doctor_first': false,
        },
      },
      [weekRow(1), weekRow(2)],
      [],
    );
    expect(weekToGenerate(full, DateTime(2026, 12, 1)), isNull);
  });

  test('week progress counts done and partial sessions', () {
    final logged = samplePlan(
      start,
      logs: [
        {'week_number': 1, 'session_index': 0, 'status': 'done', 'pain': false},
        {
          'week_number': 1,
          'session_index': 1,
          'status': 'missed',
          'pain': false,
        },
        {
          'week_number': 1,
          'session_index': 2,
          'status': 'partial',
          'pain': false,
        },
      ],
    );
    expect(weekProgress(logged, 1), (done: 2, total: 3));
    expect(weekProgress(logged, 2), (done: 0, total: 3));
  });

  test('durations parse and format as min:sec', () {
    expect(parseDuration('27:30'), 1650);
    expect(parseDuration(' 25 '), 1500);
    expect(parseDuration('8:5'), 485);
    expect(parseDuration('8:60'), isNull);
    expect(parseDuration('abc'), isNull);
    expect(parseDuration('0:00'), isNull);
    expect(formatDuration(1650), '27:30');
    expect(formatDuration(510.4), '8:30');
  });

  test('trials over other distances are converted with Riegel', () {
    final series = trialSeries([
      TimeTrial(
        distanceM: 4800,
        durationSeconds: 1700,
        recordedOn: DateTime(2026, 10, 20),
        source: 'manual',
      ),
      TimeTrial(
        distanceM: 1600,
        durationSeconds: 480,
        recordedOn: DateTime(2026, 10, 10),
        source: 'manual',
      ),
    ], 4800);
    expect(series.first.estimated, isTrue);
    expect(series.first.seconds, closeTo(480 * 3.2045, 1)); // 3^1.06
    expect(series.last.seconds, 1700);
    expect(series.last.estimated, isFalse);
  });

  test('answers JSON matches the edge function schema', () {
    final a = TrainingAnswers()
      ..canCompleteDistance = false
      ..longestContinuousKm = 1.5
      ..currentTimeSeconds =
          999 // ignored when they cannot complete
      ..runningExperience = 'none'
      ..weeksToPet = 12
      ..pain = {'knee'}
      ..painNote = '  घुटने में हल्का दर्द  ';
    final j = a.toJson();
    expect(j['can_complete_distance'], false);
    expect(j['current_time_seconds'], isNull);
    expect(j['longest_continuous_km'], 1.5);
    expect(j['background'], ['none']);
    expect(j['pain'], ['knee']);
    expect(j['pain_note'], 'घुटने में हल्का दर्द');
    expect(j['medical'], ['none']);
    expect(j.keys.toSet(), {
      'can_complete_distance',
      'current_time_seconds',
      'longest_continuous_km',
      'running_experience',
      'runs_per_week',
      'weekly_km',
      'background',
      'days_per_week',
      'minutes_per_session',
      'weeks_to_pet',
      'training_time',
      'surface',
      'pain',
      'pain_note',
      'medical',
      'weight_kg',
      'height_cm',
    });
  });
}
