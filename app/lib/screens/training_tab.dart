import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/exam_models.dart';
import '../data/exam_repository.dart';
import '../data/profile.dart';
import '../data/standards_logic.dart';
import '../data/training_logic.dart';
import '../data/training_models.dart';
import '../data/training_repository.dart';
import '../l10n/app_localizations.dart';
import '../theme/illustrations.dart';
import '../theme/motion.dart';
import '../weather/weather_card.dart';
import '../theme/app_theme.dart';
import '../theme/widgets.dart';
import 'language_button.dart';
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
              const LanguageButton(),
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
            padding: const EdgeInsets.all(16),
            children: [
              WeatherCard(now: DateTime.now()),
              HeroCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: const SunriseScene(height: 170),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.trainingIntroTitle,
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.trainingIntroBody,
                      style: textTheme.bodyMedium?.copyWith(color: Brand.khaki),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
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
                Center(
                  child: Pill(
                    l10n.qTarget(
                      distanceText(l10n, run.runMetres!),
                      formatDuration(run.value!),
                    ),
                    icon: Icons.flag,
                    background: Brand.saffronSoft,
                  ),
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

    return RefreshIndicator(
      onRefresh: () async => widget.onChanged(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          WeatherCard(now: widget.today),
          if (plan.seeDoctorFirst)
            Card(
              color: colors.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.medical_services),
                title: Text(l10n.seeDoctor),
              ),
            ),
          HeroCard(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      color: Colors.white,
                      disabledColor: Colors.white24,
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _week > 1
                          ? () => setState(() => _week--)
                          : null,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            l10n.weekOf(_week, plan.weeksTotal),
                            style: textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          if (phase != null)
                            Text(
                              phase.name,
                              style: textTheme.bodyMedium?.copyWith(
                                color: Brand.khaki,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      color: Colors.white,
                      disabledColor: Colors.white24,
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _week < plan.weeksTotal
                          ? () => setState(() => _week++)
                          : null,
                    ),
                  ],
                ),
                if (outline != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          outline.focus,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        if (outline.isRecoveryWeek)
                          Pill(
                            l10n.recoveryWeek,
                            background: Brand.saffron,
                            foreground: Brand.ink,
                          ),
                      ],
                    ),
                  ),
                if (detail != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              end: progress.total == 0
                                  ? 0
                                  : progress.done / progress.total,
                            ),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            builder: (_, v, _) => LinearProgressIndicator(
                              value: v,
                              minHeight: 10,
                              color: Brand.saffron,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.weekDone(progress.done, progress.total),
                          style: textTheme.labelMedium?.copyWith(
                            color: Brand.khaki,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 6, color: Brand.saffron),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Pill(readinessLabel(l10n, plan.readiness)),
                          const SizedBox(height: 10),
                          Text(plan.assessment),
                          const SizedBox(height: 8),
                          Text(plan.goalNote, style: textTheme.titleSmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (detail != null) ...[
            if (detail.coachNote.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.format_quote, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        detail.coachNote,
                        style: textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            for (var i = 0; i < detail.sessions.length; i++)
              FadeSlideIn(
                key: ValueKey('$_week-$i'),
                index: i,
                child: _SessionTile(
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
      ),
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
    final textTheme = Theme.of(context).textTheme;
    final log = this.log;
    final status = switch (log?.status) {
      'done' => const Icon(Icons.check_circle, color: Brand.good, size: 28),
      'partial' => Icon(Icons.timelapse, color: colors.tertiary, size: 28),
      'missed' => Icon(Icons.cancel, color: colors.error, size: 28),
      _ => Icon(
        session.isHard ? Icons.local_fire_department : Icons.circle_outlined,
        color: session.isHard ? Colors.deepOrange : colors.outline,
        size: 28,
      ),
    };
    final summary = sessionSummary(l10n, session);
    final weekday = DateFormat('EEE', l10n.localeName).format(date);
    return Card(
      color: isToday ? colors.primaryContainer : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isToday ? Brand.saffron : colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$weekday\n',
                        style: textTheme.labelMedium?.copyWith(
                          color: Brand.ink,
                        ),
                      ),
                      TextSpan(
                        text: '${date.day}',
                        style: numerals(28, color: Brand.ink),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isToday)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Pill(
                          l10n.sessionToday,
                          background: Brand.ink,
                          foreground: Colors.white,
                        ),
                      ),
                    Text(session.title, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          sessionTypeIcon(session.type),
                          size: 16,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            sessionTypeLabel(l10n, session.type),
                            style: textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        summary,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              status,
            ],
          ),
        ),
      ),
    );
  }
}
