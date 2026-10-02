import 'package:maidan/data/training_models.dart';
import 'package:maidan/data/training_repository.dart';

Map<String, dynamic> _session(
  int day,
  String type,
  String title,
  double? km, {
  double? min = 40,
}) => {
  'day': day,
  'type': type,
  'title': title,
  'details': '10 मिनट वार्म-अप, फिर $title, 5 मिनट कूल-डाउन',
  'distance_km': km,
  'duration_min': min,
  'target_pace_sec_per_km': null,
};

Map<String, dynamic> weekRow(int week) => {
  'week_number': week,
  'sessions': {
    'coach_note': 'हफ्ता $week: धीरे-धीरे आगे बढ़ें।',
    'sessions': [
      _session(1, 'easy_run', 'आसान दौड़ $week', 3),
      _session(3, 'strength', 'ताकत की कसरत', null, min: 25),
      _session(5, 'time_trial', '4.8 किमी टाइम ट्रायल', 4.8),
    ],
  },
};

/// A 4-week UP Police plan starting on [start], with weeks 1-2 generated.
TrainingPlan samplePlan(
  DateTime start, {
  List<Map<String, dynamic>>? logs,
}) => TrainingPlan.fromRows(
  {
    'id': 7,
    'exam_id': 'up_police_constable',
    'start_date':
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
    'weeks_total': 4,
    'run_distance_m': 4800,
    'target_seconds': 1500,
    'outline': {
      'assessment': 'आप अभी 4.8 किमी 29 मिनट में दौड़ते हैं।',
      'readiness': 'needs_work',
      'goal_note': 'आखिरी हफ्ते तक 24 मिनट का लक्ष्य।',
      'phases': [
        {'name': 'बेस', 'from_week': 1, 'to_week': 2, 'focus': 'f'},
        {'name': 'स्पीड', 'from_week': 3, 'to_week': 4, 'focus': 'f'},
      ],
      'weeks': [
        for (var w = 1; w <= 4; w++)
          {
            'week': w,
            'focus': 'हफ्ता $w का फोकस',
            'weekly_km': 10 + w,
            'hard_sessions': 1,
            'is_recovery_week': w == 4,
          },
      ],
      'safety_notes': ['पानी पीते रहें।'],
      'see_doctor_first': false,
    },
  },
  [weekRow(1), weekRow(2)],
  logs ?? const [],
);

class FakeTrainingRepository implements TrainingRepository {
  FakeTrainingRepository({this.plan, List<TimeTrial>? trials, DateTime? start})
    : trials = trials ?? [],
      _start = start ?? DateTime(2026, 10, 5);

  TrainingPlan? plan;
  final List<TimeTrial> trials;
  final DateTime _start;
  TrainingAnswers? lastAnswers;
  TrainingException? failWith;
  final List<SessionLog> savedLogs = [];
  int nextWeekCalls = 0;

  @override
  Future<TrainingPlan?> fetchActivePlan() async => plan;

  @override
  Future<void> createPlan(TrainingAnswers answers) async {
    lastAnswers = answers;
    if (failWith != null) throw failWith!;
    plan = samplePlan(_start);
  }

  @override
  Future<void> generateNextWeek(int planId) async {
    nextWeekCalls++;
    if (failWith != null) throw failWith!;
    final p = plan!;
    final next = p.weeks.length + 1;
    plan = TrainingPlan.fromRows(
      _planRow(p),
      [for (var w = 1; w <= next; w++) weekRow(w)],
      [for (final l in p.logs) _logRow(l)],
    );
  }

  @override
  Future<void> saveLog(int planId, SessionLog log) async {
    savedLogs.add(log);
    final p = plan!;
    plan = TrainingPlan.fromRows(
      _planRow(p),
      [for (final w in p.weeks.keys) weekRow(w)],
      [
        for (final l in p.logs)
          if (l.week != log.week || l.sessionIndex != log.sessionIndex)
            _logRow(l),
        _logRow(log),
      ],
    );
  }

  @override
  Future<List<TimeTrial>> fetchTimeTrials(String examId) async => [...trials];

  @override
  Future<void> addTimeTrial(String examId, TimeTrial trial) async {
    trials.add(trial);
  }

  Map<String, dynamic> _planRow(TrainingPlan p) {
    final base = samplePlan(p.startDate);
    return {
      'id': p.id,
      'exam_id': p.examId,
      'start_date':
          '${p.startDate.year}-${p.startDate.month.toString().padLeft(2, '0')}-${p.startDate.day.toString().padLeft(2, '0')}',
      'weeks_total': p.weeksTotal,
      'run_distance_m': p.runDistanceM,
      'target_seconds': p.targetSeconds,
      'outline': {
        'assessment': base.assessment,
        'readiness': base.readiness,
        'goal_note': base.goalNote,
        'phases': [
          for (final ph in base.phases)
            {
              'name': ph.name,
              'from_week': ph.fromWeek,
              'to_week': ph.toWeek,
              'focus': ph.focus,
            },
        ],
        'weeks': [
          for (final w in base.outline)
            {
              'week': w.week,
              'focus': w.focus,
              'weekly_km': w.weeklyKm,
              'hard_sessions': 1,
              'is_recovery_week': w.isRecoveryWeek,
            },
        ],
        'safety_notes': base.safetyNotes,
        'see_doctor_first': base.seeDoctorFirst,
      },
    };
  }

  Map<String, dynamic> _logRow(SessionLog l) => {
    'week_number': l.week,
    'session_index': l.sessionIndex,
    'status': l.status,
    'distance_km': l.distanceKm,
    'duration_seconds': l.durationSeconds,
    'effort': l.effort,
    'pain': l.pain,
    'note': l.note,
  };
}
