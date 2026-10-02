/// Questionnaire answers, sent to the training-plan edge function. Field names
/// match `Answers` in supabase/functions/training-plan/types.ts.
class TrainingAnswers {
  TrainingAnswers();

  bool? canCompleteDistance;
  int? currentTimeSeconds;
  double? longestContinuousKm;
  String? runningExperience; // none | lt3m | 3to12m | gt1y
  int runsPerWeek = 0;
  double weeklyKm = 0;
  Set<String> background = {};
  int daysPerWeek = 4;
  int minutesPerSession = 45;
  int? weeksToPet;
  String trainingTime = 'morning';
  String surface = 'ground';
  Set<String> pain = {'none'};
  String painNote = '';
  Set<String> medical = {'none'};
  double? weightKg;
  double? heightCm;

  bool get levelComplete =>
      canCompleteDistance != null &&
      (canCompleteDistance!
          ? currentTimeSeconds != null
          : longestContinuousKm != null);
  bool get experienceComplete => runningExperience != null;
  bool get scheduleComplete => weeksToPet != null;

  Map<String, dynamic> toJson() => {
    'can_complete_distance': canCompleteDistance,
    'current_time_seconds': canCompleteDistance == true
        ? currentTimeSeconds
        : null,
    'longest_continuous_km': canCompleteDistance == false
        ? longestContinuousKm
        : null,
    'running_experience': runningExperience,
    'runs_per_week': runsPerWeek,
    'weekly_km': weeklyKm,
    'background': background.isEmpty ? ['none'] : background.toList(),
    'days_per_week': daysPerWeek,
    'minutes_per_session': minutesPerSession,
    'weeks_to_pet': weeksToPet,
    'training_time': trainingTime,
    'surface': surface,
    'pain': pain.toList(),
    'pain_note': painNote.trim().isEmpty ? null : painNote.trim(),
    'medical': medical.toList(),
    'weight_kg': weightKg,
    'height_cm': heightCm,
  };
}

class PlanSession {
  const PlanSession({
    required this.day,
    required this.type,
    required this.title,
    required this.details,
    this.distanceKm,
    this.durationMin,
    this.targetPaceSecPerKm,
  });

  factory PlanSession.fromJson(Map<String, dynamic> j) => PlanSession(
    day: (j['day'] as num).toInt(),
    type: j['type'] as String,
    title: j['title'] as String,
    details: j['details'] as String,
    distanceKm: (j['distance_km'] as num?)?.toDouble(),
    durationMin: (j['duration_min'] as num?)?.toDouble(),
    targetPaceSecPerKm: (j['target_pace_sec_per_km'] as num?)?.toDouble(),
  );

  final int day;
  final String type;
  final String title;
  final String details;
  final double? distanceKm;
  final double? durationMin;
  final double? targetPaceSecPerKm;

  bool get isHard =>
      type == 'tempo' || type == 'intervals' || type == 'time_trial';
}

class PlanWeek {
  const PlanWeek({
    required this.week,
    required this.sessions,
    required this.coachNote,
  });

  factory PlanWeek.fromRow(Map<String, dynamic> row) {
    final body = row['sessions'] as Map<String, dynamic>;
    return PlanWeek(
      week: row['week_number'] as int,
      sessions: (body['sessions'] as List)
          .cast<Map<String, dynamic>>()
          .map(PlanSession.fromJson)
          .toList(),
      coachNote: body['coach_note'] as String? ?? '',
    );
  }

  final int week;
  final List<PlanSession> sessions;
  final String coachNote;
}

class WeekOutline {
  const WeekOutline({
    required this.week,
    required this.focus,
    required this.weeklyKm,
    required this.isRecoveryWeek,
  });

  factory WeekOutline.fromJson(Map<String, dynamic> j) => WeekOutline(
    week: (j['week'] as num).toInt(),
    focus: j['focus'] as String,
    weeklyKm: (j['weekly_km'] as num).toDouble(),
    isRecoveryWeek: j['is_recovery_week'] as bool? ?? false,
  );

  final int week;
  final String focus;
  final double weeklyKm;
  final bool isRecoveryWeek;
}

class PlanPhase {
  const PlanPhase(this.name, this.fromWeek, this.toWeek, this.focus);

  factory PlanPhase.fromJson(Map<String, dynamic> j) => PlanPhase(
    j['name'] as String,
    (j['from_week'] as num).toInt(),
    (j['to_week'] as num).toInt(),
    j['focus'] as String,
  );

  final String name;
  final int fromWeek;
  final int toWeek;
  final String focus;
}

class SessionLog {
  const SessionLog({
    required this.week,
    required this.sessionIndex,
    required this.status,
    this.distanceKm,
    this.durationSeconds,
    this.effort,
    this.pain = false,
    this.note,
  });

  factory SessionLog.fromRow(Map<String, dynamic> r) => SessionLog(
    week: r['week_number'] as int,
    sessionIndex: r['session_index'] as int,
    status: r['status'] as String,
    distanceKm: (r['distance_km'] as num?)?.toDouble(),
    durationSeconds: r['duration_seconds'] as int?,
    effort: (r['effort'] as num?)?.toInt(),
    pain: r['pain'] as bool? ?? false,
    note: r['note'] as String?,
  );

  final int week;
  final int sessionIndex;
  final String status; // done | partial | missed
  final double? distanceKm;
  final int? durationSeconds;
  final int? effort;
  final bool pain;
  final String? note;

  Map<String, dynamic> toRow(int planId) => {
    'plan_id': planId,
    'week_number': week,
    'session_index': sessionIndex,
    'status': status,
    'distance_km': distanceKm,
    'duration_seconds': durationSeconds,
    'effort': effort,
    'pain': pain,
    'note': (note?.trim().isEmpty ?? true) ? null : note!.trim(),
  };
}

class TrainingPlan {
  const TrainingPlan({
    required this.id,
    required this.examId,
    required this.startDate,
    required this.weeksTotal,
    required this.runDistanceM,
    required this.targetSeconds,
    required this.assessment,
    required this.readiness,
    required this.goalNote,
    required this.phases,
    required this.outline,
    required this.safetyNotes,
    required this.seeDoctorFirst,
    required this.weeks,
    required this.logs,
  });

  factory TrainingPlan.fromRows(
    Map<String, dynamic> plan,
    List<Map<String, dynamic>> weekRows,
    List<Map<String, dynamic>> logRows,
  ) {
    final o = plan['outline'] as Map<String, dynamic>;
    return TrainingPlan(
      id: plan['id'] as int,
      examId: plan['exam_id'] as String,
      startDate: DateTime.parse(plan['start_date'] as String),
      weeksTotal: plan['weeks_total'] as int,
      runDistanceM: plan['run_distance_m'] as int,
      targetSeconds: plan['target_seconds'] as int,
      assessment: o['assessment'] as String,
      readiness: o['readiness'] as String,
      goalNote: o['goal_note'] as String,
      phases: (o['phases'] as List)
          .cast<Map<String, dynamic>>()
          .map(PlanPhase.fromJson)
          .toList(),
      outline: (o['weeks'] as List)
          .cast<Map<String, dynamic>>()
          .map(WeekOutline.fromJson)
          .toList(),
      safetyNotes: (o['safety_notes'] as List).cast<String>(),
      seeDoctorFirst: o['see_doctor_first'] as bool? ?? false,
      weeks: {for (final w in weekRows.map(PlanWeek.fromRow)) w.week: w},
      logs: logRows.map(SessionLog.fromRow).toList(),
    );
  }

  final int id;
  final String examId;
  final DateTime startDate;
  final int weeksTotal;
  final int runDistanceM;
  final int targetSeconds;
  final String assessment;
  final String readiness; // on_track | needs_work | big_gap
  final String goalNote;
  final List<PlanPhase> phases;
  final List<WeekOutline> outline;
  final List<String> safetyNotes;
  final bool seeDoctorFirst;
  final Map<int, PlanWeek> weeks;
  final List<SessionLog> logs;

  SessionLog? logFor(int week, int index) {
    for (final l in logs) {
      if (l.week == week && l.sessionIndex == index) return l;
    }
    return null;
  }

  WeekOutline? outlineFor(int week) {
    for (final w in outline) {
      if (w.week == week) return w;
    }
    return null;
  }

  PlanPhase? phaseFor(int week) {
    for (final p in phases) {
      if (week >= p.fromWeek && week <= p.toWeek) return p;
    }
    return null;
  }
}

class TimeTrial {
  const TimeTrial({
    required this.distanceM,
    required this.durationSeconds,
    required this.recordedOn,
    required this.source,
  });

  factory TimeTrial.fromRow(Map<String, dynamic> r) => TimeTrial(
    distanceM: r['distance_m'] as int,
    durationSeconds: r['duration_seconds'] as int,
    recordedOn: DateTime.parse(r['recorded_on'] as String),
    source: r['source'] as String,
  );

  final int distanceM;
  final int durationSeconds;
  final DateTime recordedOn;
  final String source;
}
