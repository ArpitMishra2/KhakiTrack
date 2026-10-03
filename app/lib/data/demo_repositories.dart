import '../gps/run_analysis.dart';
import '../gps/run_repository.dart';
import 'training_models.dart';
import 'training_repository.dart';

DateTime _dayAgo(DateTime now, int days, {int hour = 18, int minute = 0}) {
  final d = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: days));
  return DateTime(d.year, d.month, d.day, hour, minute);
}

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// A believable few weeks of running for one demo user: times improving from
/// 29:00 to 24:48 over 4.8 km, a 5 day streak (8 days at its best), a run at
/// dawn, and 50+ km in total, so every part of Progress has something to show.
/// Runs recorded while demoing are analysed on the phone with the real cheat
/// rules, kept in memory and never sent anywhere.
class DemoRunRepository implements RunRepository {
  DemoRunRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final List<GpsRunSummary> _added = [];

  GpsRunSummary _run(
    int daysAgo,
    String mode,
    double km,
    double seconds, {
    int hour = 18,
    int minute = 0,
    bool target = false,
  }) => GpsRunSummary(
    mode: mode,
    startedAt: _dayAgo(_clock(), daysAgo, hour: hour, minute: minute),
    distanceM: km * 1000,
    durationS: seconds,
    finishSeconds: target ? seconds : null,
    targetM: target ? 4800 : null,
    verdict: 'verified',
  );

  List<GpsRunSummary> get _history => [
    _run(1, 'free', 5.2, 1713, hour: 5, minute: 40), // dawn run
    _run(
      3,
      'mock_pet',
      4.8,
      1488,
      hour: 6,
      target: true,
    ), // 24:48, inside 25:00
    _run(5, 'free', 6.0, 2080, hour: 17),
    _run(8, 'mock_pet', 4.8, 1590, hour: 6, target: true),
    _run(9, 'free', 7.5, 2700),
    _run(10, 'free', 4.0, 1360, hour: 7),
    _run(11, 'free', 8.0, 2840),
    _run(12, 'free', 3.5, 1190, hour: 6),
    _run(13, 'mock_pet', 4.8, 1668, hour: 6, target: true),
    _run(16, 'mock_pet', 4.8, 1740, hour: 6, target: true), // 29:00
  ];

  @override
  Future<ServerVerdict?> submit(RunSubmission run) async {
    final a = analyseRun(run.points, targetM: run.targetM);
    _added.insert(
      0,
      GpsRunSummary(
        mode: run.mode,
        startedAt: run.startedAt,
        distanceM: a.distanceM,
        durationS: a.durationS,
        finishSeconds: a.finishSeconds,
        targetM: run.targetM,
        verdict: a.verdict,
      ),
    );
    return ServerVerdict(
      verdict: a.verdict,
      flags: a.flags,
      finishSeconds: a.finishSeconds,
    );
  }

  @override
  Future<int> flushPending() async => 0;

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<List<GpsRunSummary>> recentRuns() async => [..._added, ..._history];
}

/// The demo user's plan, trials and logs, in the language the app shows.
class DemoTrainingRepository implements TrainingRepository {
  DemoTrainingRepository({
    String Function()? language,
    DateTime Function()? clock,
  }) : _language = language ?? (() => 'hi'),
       _clock = clock ?? DateTime.now;

  final String Function() _language;
  final DateTime Function() _clock;

  TrainingAnswers? _draft;
  final List<Map<String, dynamic>> _extraLogs = [];
  final List<TimeTrial> _extraTrials = [];

  String _t(String hi, String en) => _language() == 'en' ? en : hi;

  /// Week 3 of 8 is in progress: the plan began 16 days ago.
  DateTime get _start {
    final n = _clock();
    return DateTime(n.year, n.month, n.day).subtract(const Duration(days: 16));
  }

  Map<String, dynamic> _session(
    int day,
    String type,
    String title,
    double? km,
    double min,
    String details,
  ) => {
    'day': day,
    'type': type,
    'title': title,
    'details': details,
    'distance_km': km,
    'duration_min': min,
    'target_pace_sec_per_km': null,
  };

  Map<String, dynamic> _week(int w) {
    final trial = w % 3 == 0;
    return {
      'week_number': w,
      'sessions': {
        'coach_note': switch (w) {
          1 => _t(
            'पहला हफ्ता: आराम से, रफ्तार की चिंता नहीं।',
            'Week one: easy does it, no speed yet.',
          ),
          2 => _t(
            'अच्छा चल रहा है। साँस पर ध्यान दें।',
            'Going well. Watch your breathing.',
          ),
          _ => _t(
            'इस हफ्ते शनिवार को टाइम ट्रायल है। पूरा ज़ोर लगाएं।',
            'Time trial on Saturday. Give it everything.',
          ),
        },
        'sessions': [
          _session(
            1,
            'easy_run',
            _t('आसान दौड़', 'Easy run'),
            2.5 + 0.5 * w,
            30 + 3.0 * w,
            _t(
              '10 मिनट वार्म-अप, आराम की रफ्तार से दौड़ें, 5 मिनट कूल-डाउन।',
              '10 min warm-up, run at a comfortable pace, 5 min cool-down.',
            ),
          ),
          _session(
            3,
            'strength',
            _t('ताकत की कसरत', 'Strength'),
            null,
            25,
            _t(
              'स्क्वाट, लंज, प्लैंक और पुश-अप, 3 राउंड।',
              'Squats, lunges, planks and push-ups, 3 rounds.',
            ),
          ),
          trial
              ? _session(
                  6,
                  'time_trial',
                  _t('4.8 किमी टाइम ट्रायल', '4.8 km time trial'),
                  4.8,
                  40,
                  _t(
                    '10 मिनट वार्म-अप, फिर 4.8 किमी पूरा ज़ोर, 5 मिनट कूल-डाउन।',
                    '10 min warm-up, then 4.8 km flat out, 5 min cool-down.',
                  ),
                )
              : _session(
                  6,
                  'long_run',
                  _t('लंबी दौड़', 'Long run'),
                  3.5 + 0.5 * w,
                  40 + 4.0 * w,
                  _t(
                    'धीमी, लगातार रफ्तार। बीच में चलना पड़े तो चलें।',
                    'Slow and steady. Walk if you must.',
                  ),
                ),
        ],
      },
    };
  }

  Map<String, dynamic> _log(
    int week,
    int index,
    int daysAgo,
    String status, {
    double? km,
    int? seconds,
    int effort = 3,
  }) => {
    'week_number': week,
    'session_index': index,
    'status': status,
    'distance_km': km,
    'duration_seconds': seconds,
    'effort': effort,
    'pain': false,
    'note': null,
    'logged_at': _dayAgo(_clock(), daysAgo).toIso8601String(),
  };

  @override
  Future<TrainingPlan?> fetchActivePlan() async {
    final phases = [
      {'name': _t('बेस', 'Base'), 'from_week': 1, 'to_week': 3, 'focus': 'f'},
      {
        'name': _t('स्पीड', 'Speed'),
        'from_week': 4,
        'to_week': 6,
        'focus': 'f',
      },
      {'name': _t('पीक', 'Peak'), 'from_week': 7, 'to_week': 8, 'focus': 'f'},
    ];
    final focus = [
      _t('आदत बनाएं', 'Build the habit'),
      _t('दूरी धीरे-धीरे बढ़ाएं', 'Add distance slowly'),
      _t('पहला टाइम ट्रायल', 'First time trial'),
      _t('आराम का हफ्ता', 'Recovery week'),
      _t('रफ्तार पर काम', 'Work on speed'),
      _t('इंटरवल और टेम्पो', 'Intervals and tempo'),
      _t('PET जैसी दौड़', 'PET-style runs'),
      _t('टेपर और टाइम ट्रायल', 'Taper and final trial'),
    ];
    final plan = {
      'id': 1,
      'exam_id': 'up_police_constable',
      'start_date': _isoDate(_start),
      'weeks_total': 8,
      'run_distance_m': 4800,
      'target_seconds': 1500,
      'outline': {
        'assessment': _t(
          'आप अभी 4.8 किमी करीब 29 मिनट में दौड़ते हैं। 8 हफ्ते में 25 मिनट के अंदर आना मुमकिन है।',
          'You run 4.8 km in about 29 minutes today. Getting under 25 in 8 weeks is realistic.',
        ),
        'readiness': 'needs_work',
        'goal_note': _t(
          'आखिरी हफ्ते तक 4.8 किमी, 25 मिनट से कम।',
          '4.8 km in under 25 minutes by the last week.',
        ),
        'phases': phases,
        'weeks': [
          for (var w = 1; w <= 8; w++)
            {
              'week': w,
              'focus': focus[w - 1],
              'weekly_km': 8 + w * 1.5,
              'hard_sessions': w < 3 ? 0 : 1,
              'is_recovery_week': w == 4,
            },
        ],
        'safety_notes': [
          _t(
            'दर्द हो तो रुकें और आराम करें।',
            'Stop and rest if anything hurts.',
          ),
          _t(
            'गर्मी में सुबह या शाम को दौड़ें।',
            'Run early or late when it is hot.',
          ),
        ],
        'see_doctor_first': false,
      },
    };
    final logs = [
      _log(1, 0, 16, 'done', km: 3, seconds: 1980),
      _log(1, 1, 14, 'done'),
      _log(1, 2, 11, 'done', km: 4, seconds: 2400, effort: 4),
      _log(2, 0, 9, 'done', km: 3.5, seconds: 2100),
      _log(2, 1, 7, 'done'),
      _log(2, 2, 4, 'partial', km: 3, seconds: 1900, effort: 4),
      _log(3, 0, 2, 'done', km: 4, seconds: 2200),
      ..._extraLogs,
    ];
    return TrainingPlan.fromRows(plan, [_week(1), _week(2), _week(3)], logs);
  }

  @override
  Future<List<TimeTrial>> fetchTimeTrials(String examId) async {
    final n = _clock();
    DateTime on(int ago) =>
        DateTime(n.year, n.month, n.day).subtract(Duration(days: ago));
    return [
      TimeTrial(
        distanceM: 4800,
        durationSeconds: 1740,
        recordedOn: on(16),
        source: 'manual',
      ),
      TimeTrial(
        distanceM: 4800,
        durationSeconds: 1668,
        recordedOn: on(13),
        source: 'gps',
      ),
      TimeTrial(
        distanceM: 4800,
        durationSeconds: 1590,
        recordedOn: on(8),
        source: 'gps',
      ),
      TimeTrial(
        distanceM: 4800,
        durationSeconds: 1488,
        recordedOn: on(3),
        source: 'gps',
      ),
      ..._extraTrials,
    ];
  }

  @override
  Future<void> addTimeTrial(String examId, TimeTrial trial) async =>
      _extraTrials.add(trial);

  @override
  Future<void> saveLog(int planId, SessionLog log) async {
    _extraLogs.removeWhere(
      (r) =>
          r['week_number'] == log.week &&
          r['session_index'] == log.sessionIndex,
    );
    _extraLogs.add({
      ...log.toRow(planId)..remove('plan_id'),
      'logged_at': _clock().toIso8601String(),
    });
  }

  // The demo user already has a plan, so these do nothing: no AI is called.
  @override
  Future<void> createPlan(TrainingAnswers answers) async {}

  @override
  Future<void> generateNextWeek(int planId) async {}

  @override
  Future<TrainingAnswers?> loadDraft() async => _draft;

  @override
  Future<void> saveDraft(TrainingAnswers answers) async => _draft = answers;

  @override
  Future<void> clearDraft() async => _draft = null;
}

/// Uses the demo user's data while [isDemo] says so, the server otherwise.
class SwitchableTraining implements TrainingRepository {
  SwitchableTraining({
    required this.real,
    required this.demo,
    required this.isDemo,
  });

  final TrainingRepository real;
  final TrainingRepository demo;
  final bool Function() isDemo;

  TrainingRepository get _r => isDemo() ? demo : real;

  @override
  Future<TrainingPlan?> fetchActivePlan() => _r.fetchActivePlan();
  @override
  Future<void> createPlan(TrainingAnswers answers) => _r.createPlan(answers);
  @override
  Future<void> generateNextWeek(int planId) => _r.generateNextWeek(planId);
  @override
  Future<void> saveLog(int planId, SessionLog log) => _r.saveLog(planId, log);
  @override
  Future<List<TimeTrial>> fetchTimeTrials(String examId) =>
      _r.fetchTimeTrials(examId);
  @override
  Future<void> addTimeTrial(String examId, TimeTrial trial) =>
      _r.addTimeTrial(examId, trial);
  @override
  Future<TrainingAnswers?> loadDraft() => _r.loadDraft();
  @override
  Future<void> saveDraft(TrainingAnswers answers) => _r.saveDraft(answers);
  @override
  Future<void> clearDraft() => _r.clearDraft();
}

class SwitchableRuns implements RunRepository {
  SwitchableRuns({
    required this.real,
    required this.demo,
    required this.isDemo,
  });

  final RunRepository real;
  final RunRepository demo;
  final bool Function() isDemo;

  RunRepository get _r => isDemo() ? demo : real;

  @override
  Future<ServerVerdict?> submit(RunSubmission run) => _r.submit(run);
  @override
  Future<int> flushPending() => _r.flushPending();
  @override
  Future<int> pendingCount() => _r.pendingCount();
  @override
  Future<List<GpsRunSummary>> recentRuns() => _r.recentRuns();
}
