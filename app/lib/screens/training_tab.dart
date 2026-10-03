import 'package:flutter/material.dart';

import '../data/exam_models.dart';
import '../data/exam_repository.dart';
import '../data/profile.dart';
import '../data/standards_logic.dart';
import '../data/training_logic.dart';
import '../data/training_models.dart';
import '../data/training_repository.dart';
import '../l10n/app_localizations.dart';
import 'heat_banner.dart';
import 'load_error.dart';
import 'questionnaire_screen.dart';
import 'session_sheet.dart';
import 'standard_labels.dart';
import 'training_labels.dart';

class TrainingTab extends StatefulWidget {
  const TrainingTab({
    super.key,
    required this.exams,
    required this.training,
    required this.profile,
    this.today,
  });

  final ExamRepository exams;
  final TrainingRepository training;
  final Profile profile;
  final DateTime? today;

  @override
  State<TrainingTab> createState() => _TrainingTabState();
}

typedef _Loaded = ({TrainingPlan? plan, Standard? run});

class _TrainingTabState extends State<TrainingTab> {
  late Future<_Loaded> _data = _load();

  DateTime get _today => widget.today ?? DateTime.now();

  Future<_Loaded> _load() async {
    final results = await Future.wait<Object?>([
      widget.training.fetchActivePlan(),
      widget.exams.fetchStandards(widget.profile.examId!),
    ]);
    return (
      plan: results[0] as TrainingPlan?,
      run: runStandardFor(
        results[1]! as List<Standard>,
        widget.profile.gender!,
        widget.profile.category,
        age: widget.profile.dateOfBirth == null
            ? null
            : ageOn(widget.profile.dateOfBirth!, DateTime.now()),
      ),
    );
  }

  void _reload() => setState(() {
    _data = _load();
  });

  Future<void> _startQuestionnaire(Standard run, {bool replace = false}) async {
    final l10n = AppLocalizations.of(context);
    if (replace) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          content: Text(l10n.newPlanConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(l10n.continueLabel),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuestionnaireScreen(
          runMetres: run.runMetres!,
          targetSeconds: run.value!.round(),
          training: widget.training,
        ),
      ),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<_Loaded>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final plan = data?.plan;
        final run = data?.run;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.tabTraining),
            actions: [
              if (plan != null && run != null)
                PopupMenuButton<String>(
                  onSelected: (_) => _startQuestionnaire(run, replace: true),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'new', child: Text(l10n.newPlan)),
                  ],
                ),
            ],
          ),
          body: snapshot.hasError
              ? Center(child: LoadError(onRetry: _reload))
              : data == null
              ? const Center(child: CircularProgressIndicator())
              : plan == null
              ? _Intro(
                  run: run,
                  onStart: run == null ? null : () => _startQuestionnaire(run),
                )
              : _PlanView(
                  plan: plan,
                  training: widget.training,
                  today: _today,
                  onChanged: _reload,
                ),
        );
      },
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.run, required this.onStart});

  final Standard? run;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final run = this.run;
    // The button stays pinned below the text so it is visible on small
    // phones with large text.
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.directions_run, size: 56),
              const SizedBox(height: 16),
              Text(
                l10n.trainingIntroTitle,
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(l10n.trainingIntroBody, textAlign: TextAlign.center),
              if (run == null) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.examUnconfirmed,
                  style: textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
              ],
              if (run != null) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.qTarget(
                    distanceText(l10n, run.runMetres!),
                    formatDuration(run.value!),
                  ),
                  style: textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onStart,
                child: Text(l10n.startQuestionnaire),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanView extends StatefulWidget {
  const _PlanView({
    required this.plan,
    required this.training,
    required this.today,
    required this.onChanged,
  });

  final TrainingPlan plan;
  final TrainingRepository training;
  final DateTime today;
  final VoidCallback onChanged;

  @override
  State<_PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends State<_PlanView> {
  late int _week = currentWeek(widget.plan, widget.today);
  bool _generating = false;
  String? _error;

  Future<void> _generateWeek() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      await widget.training.generateNextWeek(widget.plan.id);
      widget.onChanged();
    } on TrainingException catch (e) {
      if (mounted) {
        setState(
          () => _error = trainingErrorText(AppLocalizations.of(context), e),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _openSession(int index, PlanSession session) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SessionSheet(
        plan: widget.plan,
        week: _week,
        index: index,
        session: session,
        training: widget.training,
        today: widget.today,
      ),
    );
    if (saved == true) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final plan = widget.plan;
    final outline = plan.outlineFor(_week);
    final phase = plan.phaseFor(_week);
    final detail = plan.weeks[_week];
    final progress = weekProgress(plan, _week);
    final today = currentWeek(plan, widget.today);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeatBanner(now: widget.today),
        if (plan.seeDoctorFirst)
          Card(
            color: colors.errorContainer,
            child: ListTile(
              leading: const Icon(Icons.medical_services),
              title: Text(l10n.seeDoctor),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(label: Text(readinessLabel(l10n, plan.readiness))),
                const SizedBox(height: 8),
                Text(plan.assessment),
                const SizedBox(height: 8),
                Text(plan.goalNote, style: textTheme.titleSmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _week > 1 ? () => setState(() => _week--) : null,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    l10n.weekOf(_week, plan.weeksTotal),
                    style: textTheme.titleMedium,
                  ),
                  if (phase != null)
                    Text(phase.name, style: textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _week < plan.weeksTotal
                  ? () => setState(() => _week++)
                  : null,
            ),
          ],
        ),
        if (outline != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(outline.focus),
                if (outline.isRecoveryWeek)
                  Chip(label: Text(l10n.recoveryWeek)),
              ],
            ),
          ),
        const SizedBox(height: 8),
        if (detail != null) ...[
          if (detail.coachNote.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                detail.coachNote,
                style: textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              l10n.weekDone(progress.done, progress.total),
              style: textTheme.bodySmall,
            ),
          ),
          for (var i = 0; i < detail.sessions.length; i++)
            _SessionTile(
              session: detail.sessions[i],
              date: sessionDate(plan, _week, detail.sessions[i].day),
              isToday:
                  _week == today &&
                  sessionDate(plan, _week, detail.sessions[i].day) ==
                      DateTime(
                        widget.today.year,
                        widget.today.month,
                        widget.today.day,
                      ),
              log: plan.logFor(_week, i),
              onTap: () => _openSession(i, detail.sessions[i]),
            ),
        ] else
          _WeekNotReady(
            week: _week,
            plan: plan,
            today: widget.today,
            generating: _generating,
            onGenerate: _generateWeek,
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(_error!, style: TextStyle(color: colors.error)),
          ),
        if (plan.safetyNotes.isNotEmpty)
          ExpansionTile(
            title: Text(l10n.safetyNotes),
            children: [
              for (final n in plan.safetyNotes)
                ListTile(dense: true, title: Text(n)),
            ],
          ),
        ExpansionTile(
          title: Text(l10n.fullPlan),
          children: [
            for (final w in plan.outline)
              ListTile(
                dense: true,
                leading: Text('${w.week}'),
                title: Text(w.focus),
                trailing: Text(l10n.km(w.weeklyKm.toStringAsFixed(0))),
                onTap: () => setState(() => _week = w.week),
              ),
          ],
        ),
      ],
    );
  }
}

class _WeekNotReady extends StatelessWidget {
  const _WeekNotReady({
    required this.week,
    required this.plan,
    required this.today,
    required this.generating,
    required this.onGenerate,
  });

  final int week;
  final TrainingPlan plan;
  final DateTime today;
  final bool generating;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (generating) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.generatingTitle),
            Text(l10n.generatingBody, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    final next = weekToGenerate(plan, today);
    if (next == week) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: onGenerate,
          icon: const Icon(Icons.auto_awesome),
          label: Text(l10n.generateNextWeek(week)),
        ),
      );
    }
    final unlock = sessionDate(plan, week, 1).subtract(const Duration(days: 2));
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        l10n.nextWeekLocked(week, shortDate(l10n, unlock)),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.date,
    required this.isToday,
    required this.log,
    required this.onTap,
  });

  final PlanSession session;
  final DateTime date;
  final bool isToday;
  final SessionLog? log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final log = this.log;
    final icon = switch (log?.status) {
      'done' => Icon(Icons.check_circle, color: colors.primary),
      'partial' => Icon(Icons.timelapse, color: colors.tertiary),
      'missed' => Icon(Icons.cancel, color: colors.error),
      _ => Icon(
        session.isHard ? Icons.local_fire_department : Icons.circle_outlined,
      ),
    };
    final summary = sessionSummary(l10n, session);
    return Card(
      color: isToday ? colors.primaryContainer : null,
      child: ListTile(
        leading: icon,
        title: Text(session.title),
        subtitle: Text(
          [
            '${isToday ? '${l10n.sessionToday} · ' : ''}${shortDate(l10n, date)}',
            sessionTypeLabel(l10n, session.type),
            if (summary.isNotEmpty) summary,
          ].join('\n'),
        ),
        isThreeLine: true,
        onTap: onTap,
      ),
    );
  }
}
