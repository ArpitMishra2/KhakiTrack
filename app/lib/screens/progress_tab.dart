import 'dart:math';

import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/exam_models.dart';
import '../data/exam_repository.dart';
import '../data/profile.dart';
import '../data/standards_logic.dart';
import '../data/streaks_logic.dart';
import '../data/training_logic.dart';
import '../data/training_models.dart';
import '../data/training_repository.dart';
import '../gps/location_source.dart';
import '../gps/run_repository.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../theme/widgets.dart';
import 'language_button.dart';
import 'load_error.dart';
import 'run_screen.dart';
import 'standard_labels.dart';
import 'training_labels.dart';

/// Time trials over the exam distance against the qualifying time.
class ProgressTab extends StatefulWidget {
  const ProgressTab({
    super.key,
    required this.exams,
    required this.training,
    required this.runs,
    required this.location,
    required this.profile,
    required this.visible,
    this.today,
  });

  final ExamRepository exams;
  final TrainingRepository training;
  final RunRepository runs;
  final LocationSource Function(AppLocalizations) location;
  final Profile profile;

  /// Reloads when the tab is shown, to pick up trials logged elsewhere.
  final bool visible;
  final DateTime? today;

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

typedef _Data = ({
  List<TimeTrial> trials,
  Standard? run,
  List<GpsRunSummary> gpsRuns,
  List<SessionLog> logs,
  int pending,
});

class _ProgressTabState extends State<ProgressTab> {
  late Future<_Data> _data = _load();

  Future<_Data> _load() async {
    final examId = widget.profile.examId!;
    // Send runs recorded while offline; failures just stay pending.
    try {
      await widget.runs.flushPending();
    } on Exception {
      // Offline again; try next time.
    }
    final gps = await Future.wait<Object>([
      widget.runs.recentRuns(),
      widget.runs.pendingCount(),
    ]);
    final results = await Future.wait<Object?>([
      widget.training.fetchTimeTrials(examId),
      widget.exams.fetchStandards(examId),
      widget.training.fetchActivePlan(),
    ]);
    return (
      trials: results[0] as List<TimeTrial>,
      run: runStandardFor(
        results[1] as List<Standard>,
        widget.profile.gender!,
        widget.profile.category,
        age: widget.profile.dateOfBirth == null
            ? null
            : ageOn(widget.profile.dateOfBirth!, DateTime.now()),
      ),
      gpsRuns: gps[0] as List<GpsRunSummary>,
      logs: (results[2] as TrainingPlan?)?.logs ?? const [],
      pending: gps[1] as int,
    );
  }

  Future<void> _openRun(Standard run, {required bool mockPet}) async {
    final recorded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (c) => Theme(
          data: AppTheme.dark(),
          child: RunScreen(
            examId: widget.profile.examId!,
            runMetres: run.runMetres!,
            targetSeconds: run.value!.round(),
            mockPet: mockPet,
            source: widget.location(AppLocalizations.of(c)),
            runs: widget.runs,
          ),
        ),
      ),
    );
    if (recorded == true && mounted) {
      setState(() {
        _data = _load();
      });
    }
  }

  @override
  void didUpdateWidget(ProgressTab old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible && !SettingsScope.lowDataOf(context)) {
      _data = _load();
    }
  }

  Future<void> _addTrial(int defaultMetres) async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => _AddTrialDialog(
        examId: widget.profile.examId!,
        defaultMetres: defaultMetres,
        training: widget.training,
        today: widget.today ?? DateTime.now(),
      ),
    );
    if (added == true) {
      setState(() {
        _data = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<_Data>(
      future: _data,
      builder: (context, snapshot) {
        final run = snapshot.data?.run;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.tabProgress),
            actions: const [LanguageButton()],
          ),
          floatingActionButton: run == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _addTrial(run.runMetres!),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addTrial),
                ),
          body: snapshot.hasError
              ? Center(
                  child: LoadError(
                    onRetry: () => setState(() {
                      _data = _load();
                    }),
                  ),
                )
              : snapshot.data == null
              ? const Center(child: CircularProgressIndicator())
              : run == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.examUnconfirmed,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _body(context, l10n, snapshot.data!, run),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    _Data data,
    Standard run,
  ) {
    final trials = data.trials;
    final textTheme = Theme.of(context).textTheme;
    final metres = run.runMetres!;
    final target = run.value!;
    final distance = distanceText(l10n, metres);
    final series = trialSeries(trials, metres);
    final latest = series.isEmpty ? null : series.last;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        FadeSlideIn(
          child: _StreakCard(
            days: activityDays(data.logs, data.gpsRuns),
            runs: data.gpsRuns,
            today: widget.today ?? DateTime.now(),
            targetSeconds: target,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: () => _openRun(run, mockPet: true),
                  icon: const Icon(Icons.timer),
                  label: Text(l10n.mockPetCta),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _openRun(run, mockPet: false),
                  icon: const Icon(Icons.directions_run),
                  label: Text(l10n.recordRun),
                ),
                if (data.pending > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.pendingRuns(data.pending),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.progressTitle(distance), style: textTheme.titleLarge),
                Text(
                  l10n.targetTime(formatDuration(target)),
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                if (latest == null)
                  Text(l10n.progressEmpty)
                else ...[
                  Text(
                    l10n.latestTime(formatDuration(latest.seconds)) +
                        (latest.estimated ? ' (${l10n.estimated})' : ''),
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Pill(
                    latest.seconds > target
                        ? l10n.gapToCut(formatDuration(latest.seconds - target))
                        : l10n.underTarget(
                            formatDuration(target - latest.seconds),
                          ),
                    icon: latest.seconds > target
                        ? Icons.trending_down
                        : Icons.check_circle,
                    background: latest.seconds > target
                        ? Theme.of(context).colorScheme.errorContainer
                        : const Color(0xFFD7EBD8),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: CustomPaint(
                      painter: _TrialChart(
                        points: [for (final p in series) p.seconds],
                        target: target,
                        lineColor: Theme.of(context).colorScheme.primary,
                        targetColor: Brand.olive,
                        gridColor: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final (i, t) in trials.reversed.indexed)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${distanceText(l10n, t.distanceM)} · ${formatDuration(t.durationSeconds)}',
                      ),
                      subtitle: Text(shortDate(l10n, t.recordedOn)),
                      trailing: t.distanceM == metres
                          ? null
                          : Text(
                              '≈ ${formatDuration(series[series.length - 1 - i].seconds)}',
                            ),
                    ),
                  if (series.any((p) => p.estimated))
                    Text(
                      l10n.estimateNote(distance),
                      style: textTheme.bodySmall,
                    ),
                ],
              ],
            ),
          ),
        ),
        if (data.gpsRuns.isNotEmpty) ...[
          SectionTitle(l10n.recentRuns),
          Card(
            child: Column(
              children: [
                for (final g in data.gpsRuns.take(10))
                  ListTile(
                    dense: true,
                    leading: Icon(switch (g.verdict) {
                      'verified' => Icons.verified,
                      'rejected' => Icons.block,
                      _ => Icons.help_outline,
                    }, color: g.verdict == 'verified' ? Brand.good : null),
                    title: Text(
                      [
                        g.mode == 'mock_pet'
                            ? l10n.mockPetTitle
                            : l10n.freeRunTitle,
                        l10n.km((g.distanceM / 1000).toStringAsFixed(2)),
                        formatDuration(g.finishSeconds ?? g.durationS),
                      ].join(' · '),
                    ),
                    subtitle: Text(shortDate(l10n, g.startedAt)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.days,
    required this.runs,
    required this.today,
    required this.targetSeconds,
  });

  final Set<DateTime> days;
  final List<GpsRunSummary> runs;
  final DateTime today;
  final double targetSeconds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final streak = computeStreak(days, today);
    final dots = weekDots(days, today);
    final badges = computeBadges(
      days,
      runs,
      today,
      targetSeconds: targetSeconds,
    );
    final initials = l10n.weekdayInitials.split(',');
    final todayIndex = DateTime(today.year, today.month, today.day).weekday - 1;
    final lit = streak.current > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: lit ? Brand.saffron : Colors.white12,
                    ),
                    child: Icon(
                      Icons.local_fire_department,
                      size: 32,
                      color: lit ? Brand.ink : Brand.khaki,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.streakDays(streak.current),
                          style: textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          streak.current == 0
                              ? l10n.streakStart
                              : l10n.streakBest(streak.best),
                          style: textTheme.bodySmall?.copyWith(
                            color: Brand.khaki,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 7; i++)
                    Column(
                      children: [
                        Text(
                          initials[i],
                          style: textTheme.labelSmall?.copyWith(
                            color: Brand.khaki,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dots[i] ? Brand.saffron : Colors.white12,
                            border: i == todayIndex && !dots[i]
                                ? Border.all(color: Brand.saffron, width: 2)
                                : null,
                          ),
                          child: dots[i]
                              ? const Icon(
                                  Icons.check,
                                  size: 20,
                                  color: Brand.ink,
                                )
                              : null,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.badgesTitle,
                        style: textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${badges.earned.length} / ${BadgeKind.values.length}',
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  children: [
                    for (final b in BadgeKind.values)
                      _Medal(
                        name: badgeName(l10n, b),
                        hint: badgeHint(l10n, b),
                        earned: badges.earned.contains(b),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Medal extends StatelessWidget {
  const _Medal({required this.name, required this.hint, required this.earned});

  final String name;
  final String hint;
  final bool earned;

  Widget _maybePop(Widget w) => earned ? PopIn(child: w) : w;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: hint,
      triggerMode: TooltipTriggerMode.tap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            _maybePop(
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: earned
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFB347), Brand.saffron],
                        )
                      : null,
                  color: earned ? null : colors.secondaryContainer,
                ),
                child: Icon(
                  earned ? Icons.emoji_events : Icons.lock_outline,
                  color: earned ? Brand.ink : colors.outline,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: earned ? colors.onSurface : colors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String badgeName(AppLocalizations l10n, BadgeKind b) => switch (b) {
  BadgeKind.earlyBird => l10n.badgeEarlyBird,
  BadgeKind.comeback => l10n.badgeComeback,
  BadgeKind.streak3 => l10n.badgeStreak3,
  BadgeKind.streak7 => l10n.badgeStreak7,
  BadgeKind.streak30 => l10n.badgeStreak30,
  BadgeKind.qualified => l10n.badgeQualified,
  BadgeKind.km50 => l10n.badgeKm50,
};

String badgeHint(AppLocalizations l10n, BadgeKind b) => switch (b) {
  BadgeKind.earlyBird => l10n.badgeEarlyBirdHint,
  BadgeKind.comeback => l10n.badgeComebackHint,
  BadgeKind.streak3 => l10n.badgeStreak3Hint,
  BadgeKind.streak7 => l10n.badgeStreak7Hint,
  BadgeKind.streak30 => l10n.badgeStreak30Hint,
  BadgeKind.qualified => l10n.badgeQualifiedHint,
  BadgeKind.km50 => l10n.badgeKm50Hint,
};

class _TrialChart extends CustomPainter {
  _TrialChart({
    required this.points,
    required this.target,
    required this.lineColor,
    required this.targetColor,
    required this.gridColor,
  });

  final List<double> points;
  final double target;
  final Color lineColor;
  final Color targetColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final all = [...points, target];
    final lo = all.reduce(min) * 0.95;
    final hi = all.reduce(max) * 1.05;
    // Faster (lower) times are drawn higher.
    double y(double s) => (s - lo) / (hi - lo) * size.height;
    double x(int i) => points.length == 1
        ? size.width / 2
        : i / (points.length - 1) * size.width;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = gridColor
        ..style = PaintingStyle.stroke,
    );

    final ty = y(target);
    final dash = Paint()
      ..color = targetColor
      ..strokeWidth = 2;
    for (double dx = 0; dx < size.width; dx += 12) {
      canvas.drawLine(
        Offset(dx, ty),
        Offset(min(dx + 6, size.width), ty),
        dash,
      );
    }

    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final o = Offset(x(i), y(points[i]));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      canvas.drawCircle(o, 4, Paint()..color = lineColor);
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(_TrialChart old) =>
      old.points != points || old.target != target;
}

class _AddTrialDialog extends StatefulWidget {
  const _AddTrialDialog({
    required this.examId,
    required this.defaultMetres,
    required this.training,
    required this.today,
  });

  final String examId;
  final int defaultMetres;
  final TrainingRepository training;
  final DateTime today;

  @override
  State<_AddTrialDialog> createState() => _AddTrialDialogState();
}

class _AddTrialDialogState extends State<_AddTrialDialog> {
  late final _metres = TextEditingController(text: '${widget.defaultMetres}');
  final _time = TextEditingController();
  late DateTime _date = widget.today;
  bool _saving = false;
  bool _failed = false;

  int? get _m {
    final v = int.tryParse(_metres.text);
    return v != null && v >= 100 && v <= 42195 ? v : null;
  }

  @override
  void dispose() {
    _metres.dispose();
    _time.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.training.addTimeTrial(
        widget.examId,
        TimeTrial(
          distanceM: _m!,
          durationSeconds: parseDuration(_time.text)!,
          recordedOn: _date,
          source: 'manual',
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final valid = _m != null && parseDuration(_time.text) != null;
    return AlertDialog(
      title: Text(l10n.addTrial),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _metres,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.trialDistance),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _time,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: l10n.trialTime,
                hintText: l10n.qTimeHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(shortDate(l10n, _date)),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: widget.today.subtract(const Duration(days: 365)),
                  lastDate: widget.today,
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            if (_failed)
              Text(
                l10n.trialSaveFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: valid && !_saving ? _save : null,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
