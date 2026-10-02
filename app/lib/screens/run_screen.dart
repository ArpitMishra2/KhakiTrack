import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import '../data/training_logic.dart';
import '../gps/location_source.dart';
import '../gps/run_analysis.dart';
import '../gps/run_recorder.dart';
import '../gps/run_repository.dart';
import '../l10n/app_localizations.dart';
import 'standard_labels.dart';

/// Records a GPS run: waits for a GPS fix, shows live numbers, then the
/// result checked on the phone and again on the server. Pops true if a run
/// was recorded.
class RunScreen extends StatefulWidget {
  const RunScreen({
    super.key,
    required this.examId,
    required this.runMetres,
    required this.targetSeconds,
    required this.mockPet,
    required this.source,
    required this.runs,
  });

  final String examId;
  final int runMetres;
  final int targetSeconds;

  /// Mock PET over the exam distance, or a free run.
  final bool mockPet;
  final LocationSource source;
  final RunRepository runs;

  @override
  State<RunScreen> createState() => _RunScreenState();
}

enum _Phase { checking, blocked, warmup, running, result }

class _RunScreenState extends State<RunScreen> {
  _Phase _phase = _Phase.checking;
  LocationAccess? _access;
  StreamSubscription<TrackPoint>? _warmup;
  double? _warmupAccuracy;
  RunRecorder? _recorder;
  Timer? _ticker;
  ServerVerdict? _server;
  bool _uploading = false;
  bool _savedOffline = false;
  bool _refused = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _phase = _Phase.checking);
    final access = await widget.source.ensureAccess();
    if (!mounted) return;
    if (access != LocationAccess.granted) {
      setState(() {
        _access = access;
        _phase = _Phase.blocked;
      });
      return;
    }
    setState(() => _phase = _Phase.warmup);
    _warmup = widget.source.track(DateTime.now()).listen((p) {
      if (mounted) setState(() => _warmupAccuracy = p.accuracy);
    });
  }

  void _start() {
    _warmup?.cancel();
    final r = RunRecorder(
      source: widget.source,
      targetM: widget.mockPet ? widget.runMetres : null,
    );
    r.addListener(() {
      if (!mounted) return;
      if (r.finished && _phase == _Phase.running) {
        _finish();
      } else {
        setState(() {});
      }
    });
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => mounted ? setState(() {}) : null,
    );
    setState(() {
      _recorder = r;
      _phase = _Phase.running;
    });
    r.start();
  }

  Future<void> _finish() async {
    // Stopping notifies listeners, which would call this again.
    if (_phase != _Phase.running) return;
    setState(() {
      _phase = _Phase.result;
      _uploading = true;
    });
    final r = _recorder!;
    if (!r.finished) r.stop();
    _ticker?.cancel();
    try {
      final verdict = await widget.runs.submit(
        RunSubmission(
          examId: widget.examId,
          mode: widget.mockPet ? 'mock_pet' : 'free',
          targetM: widget.mockPet ? widget.runMetres : null,
          startedAt: r.startedAt!,
          clientVerdict: r.result!.verdict,
          points: r.points,
        ),
      );
      if (!mounted) return;
      setState(() {
        _server = verdict;
        _savedOffline = verdict == null;
      });
    } on FunctionException {
      if (mounted) setState(() => _refused = true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    _warmup?.cancel();
    _ticker?.cancel();
    _recorder?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: _phase != _Phase.running,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.mockPet ? l10n.mockPetTitle : l10n.freeRunTitle),
          automaticallyImplyLeading: _phase != _Phase.running,
        ),
        body: SafeArea(
          child: switch (_phase) {
            _Phase.checking => const Center(child: CircularProgressIndicator()),
            _Phase.blocked => _blocked(l10n),
            _Phase.warmup => _warmupView(l10n),
            _Phase.running => _runningView(l10n),
            _Phase.result => _resultView(l10n),
          },
        ),
      ),
    );
  }

  Widget _blocked(AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.location_off, size: 48),
        const SizedBox(height: 16),
        Text(
          _access == LocationAccess.serviceOff ? l10n.gpsOff : l10n.gpsDenied,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (_access == LocationAccess.deniedForever)
          FilledButton(
            onPressed: widget.source.openSettings,
            child: Text(l10n.openSettings),
          ),
        OutlinedButton(onPressed: _check, child: Text(l10n.retry)),
      ],
    ),
  );

  Widget _warmupView(AppLocalizations l10n) {
    final textTheme = Theme.of(context).textTheme;
    final acc = _warmupAccuracy;
    final ready = acc != null && acc <= 20;
    final distance = distanceText(l10n, widget.runMetres);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                widget.mockPet
                    ? l10n.mockPetIntro(
                        distance,
                        formatDuration(widget.targetSeconds),
                      )
                    : l10n.freeRunIntro,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(l10n.runTips),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(
                    ready ? Icons.gps_fixed : Icons.gps_not_fixed,
                    color: ready ? Theme.of(context).colorScheme.primary : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      acc == null
                          ? l10n.gpsSearching
                          : ready
                          ? '${l10n.gpsReady} · ${l10n.gpsAccuracy(acc.round())}'
                          : l10n.gpsAccuracy(acc.round()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: acc == null ? null : _start,
              child: Text(ready ? l10n.startRun : l10n.startAnyway),
            ),
          ),
        ),
      ],
    );
  }

  Widget _runningView(AppLocalizations l10n) {
    final r = _recorder!;
    final textTheme = Theme.of(context).textTheme;
    final dist = r.live?.distanceM ?? 0;
    final elapsed = r.elapsedS;
    final speed = r.recentSpeed();
    final target = widget.runMetres;
    final delta = widget.mockPet
        ? paceDelta(dist, elapsed, target, widget.targetSeconds)
        : null;
    final colors = Theme.of(context).colorScheme;

    Widget stat(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(label, style: textTheme.labelLarge),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: textTheme.headlineMedium),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(l10n.elapsed, style: textTheme.titleMedium),
          FittedBox(
            child: Text(
              formatDuration(elapsed),
              style: textTheme.displayLarge?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              stat(
                l10n.distanceLabel,
                l10n.km((dist / 1000).toStringAsFixed(2)),
              ),
              stat(
                l10n.paceLabel,
                speed == null || speed < 0.5
                    ? '–'
                    : l10n.minPerKm(formatDuration(1000 / speed)),
              ),
            ],
          ),
          if (widget.mockPet) ...[
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: (dist / target).clamp(0.0, 1.0),
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.remaining(
                distanceText(l10n, (target - dist).clamp(0, target).round()),
              ),
            ),
            if (delta != null && dist > 50)
              Text(
                delta >= 0
                    ? l10n.aheadBy(formatDuration(delta))
                    : l10n.behindBy(formatDuration(-delta)),
                style: textTheme.titleLarge?.copyWith(
                  color: delta >= 0 ? colors.primary : colors.error,
                ),
              ),
          ],
          const Spacer(),
          GestureDetector(
            onLongPress: _finish,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Text(
                l10n.holdToStop,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultView(AppLocalizations l10n) {
    final r = _recorder!.result!;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final verdict = _server?.verdict ?? r.verdict;
    final flags = _server?.flags ?? r.flags;
    final finish = _server?.finishSeconds ?? r.finishSeconds;
    final distance = distanceText(l10n, widget.runMetres);
    final outcome = petOutcome(finish, widget.targetSeconds);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (widget.mockPet) ...[
          Icon(
            switch (outcome) {
              PetOutcome.qualified => Icons.emoji_events,
              PetOutcome.borderline => Icons.warning_amber,
              _ => Icons.trending_up,
            },
            size: 56,
            color: outcome == PetOutcome.qualified ? colors.primary : null,
          ),
          Text(
            switch (outcome) {
              PetOutcome.qualified => l10n.outcomeQualified,
              PetOutcome.borderline => l10n.outcomeBorderline,
              PetOutcome.notQualified => l10n.outcomeNotQualified,
              PetOutcome.incomplete => l10n.outcomeIncomplete,
            },
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (finish != null) ...[
            Text(
              l10n.finishTime(distance, formatDuration(finish)),
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            Text(
              finish <= widget.targetSeconds
                  ? l10n.marginAhead(
                      formatDuration(widget.targetSeconds - finish),
                    )
                  : l10n.marginBehind(
                      formatDuration(finish - widget.targetSeconds),
                    ),
              textAlign: TextAlign.center,
            ),
          ],
          Text(
            l10n.targetLine(formatDuration(widget.targetSeconds)),
            textAlign: TextAlign.center,
          ),
          if (outcome == PetOutcome.borderline) ...[
            const SizedBox(height: 8),
            Text(l10n.borderlineNote, textAlign: TextAlign.center),
          ],
          const Divider(height: 32),
        ],
        Text(
          l10n.totalDistance(l10n.km((r.distanceM / 1000).toStringAsFixed(2))),
        ),
        Text(l10n.totalTime(formatDuration(r.durationS))),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: Icon(
              switch (verdict) {
                'verified' => Icons.verified,
                'rejected' => Icons.block,
                _ => Icons.help_outline,
              },
              color: verdict == 'verified'
                  ? colors.primary
                  : verdict == 'rejected'
                  ? colors.error
                  : null,
            ),
            title: Text(switch (verdict) {
              'verified' => l10n.verdictVerified,
              'rejected' => l10n.verdictRejected,
              _ => l10n.verdictSuspicious,
            }),
            subtitle: Text(
              [
                for (final f in flags) flagText(l10n, f),
                if (verdict != 'verified') l10n.verdictNotCounted,
              ].join('\n'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_uploading)
          Row(
            children: [
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(l10n.uploading),
            ],
          )
        else if (_savedOffline)
          Text(l10n.savedOffline)
        else if (_refused)
          Text(l10n.uploadRefused, style: TextStyle(color: colors.error))
        else if (_server != null)
          Text(l10n.serverChecked, style: textTheme.bodySmall),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _uploading ? null : () => Navigator.pop(context, true),
          child: Text(l10n.done),
        ),
      ],
    );
  }
}

String flagText(AppLocalizations l10n, String flag) => switch (flag) {
  'mock_location' => l10n.flagMock,
  'teleport' => l10n.flagTeleport,
  'impossible_speed' => l10n.flagImpossibleSpeed,
  'vehicle_like' => l10n.flagVehicle,
  'implausible_average' => l10n.flagAverage,
  'poor_signal' => l10n.flagPoorSignal,
  'signal_gap' => l10n.flagGap,
  'sparse_samples' => l10n.flagSparse,
  'too_short' => l10n.flagTooShort,
  _ => flag,
};
