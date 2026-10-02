import 'dart:math';

import 'package:flutter/material.dart';

import '../data/exam_models.dart';
import '../data/exam_repository.dart';
import '../data/profile.dart';
import '../data/standards_logic.dart';
import '../data/training_logic.dart';
import '../data/training_models.dart';
import '../data/training_repository.dart';
import '../gps/location_source.dart';
import '../gps/run_repository.dart';
import '../l10n/app_localizations.dart';
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
    final results = await Future.wait<Object>([
      widget.training.fetchTimeTrials(examId),
      widget.exams.fetchStandards(examId),
    ]);
    return (
      trials: results[0] as List<TimeTrial>,
      run: runStandardFor(
        results[1] as List<Standard>,
        widget.profile.gender!,
        widget.profile.category,
      ),
      gpsRuns: gps[0] as List<GpsRunSummary>,
      pending: gps[1] as int,
    );
  }

  Future<void> _openRun(Standard run, {required bool mockPet}) async {
    final recorded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (c) => RunScreen(
          examId: widget.profile.examId!,
          runMetres: run.runMetres!,
          targetSeconds: run.value!.round(),
          mockPet: mockPet,
          source: widget.location(AppLocalizations.of(c)),
          runs: widget.runs,
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
    if (widget.visible && !old.visible) {
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
          appBar: AppBar(title: Text(l10n.tabProgress)),
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
              ? const SizedBox.shrink()
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
        const SizedBox(height: 16),
        Text(l10n.progressTitle(distance), style: textTheme.titleLarge),
        Text(l10n.targetTime(formatDuration(target))),
        const SizedBox(height: 12),
        if (latest == null)
          Text(l10n.progressEmpty)
        else ...[
          Text(
            l10n.latestTime(formatDuration(latest.seconds)) +
                (latest.estimated ? ' (${l10n.estimated})' : ''),
            style: textTheme.titleMedium,
          ),
          Text(
            latest.seconds > target
                ? l10n.gapToCut(formatDuration(latest.seconds - target))
                : l10n.underTarget(formatDuration(target - latest.seconds)),
            style: textTheme.titleSmall?.copyWith(
              color: latest.seconds > target
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _TrialChart(
                points: [for (final p in series) p.seconds],
                target: target,
                lineColor: Theme.of(context).colorScheme.primary,
                targetColor: Theme.of(context).colorScheme.error,
                gridColor: Theme.of(context).colorScheme.outlineVariant,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 16),
          for (final (i, t) in trials.reversed.indexed)
            ListTile(
              dense: true,
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
            Text(l10n.estimateNote(distance), style: textTheme.bodySmall),
        ],
        if (data.gpsRuns.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l10n.recentRuns, style: textTheme.titleMedium),
          for (final g in data.gpsRuns)
            ListTile(
              dense: true,
              leading: Icon(switch (g.verdict) {
                'verified' => Icons.verified,
                'rejected' => Icons.block,
                _ => Icons.help_outline,
              }),
              title: Text(
                [
                  g.mode == 'mock_pet' ? l10n.mockPetTitle : l10n.freeRunTitle,
                  l10n.km((g.distanceM / 1000).toStringAsFixed(2)),
                  formatDuration(g.finishSeconds ?? g.durationS),
                ].join(' · '),
              ),
              subtitle: Text(shortDate(l10n, g.startedAt)),
            ),
        ],
      ],
    );
  }
}

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
