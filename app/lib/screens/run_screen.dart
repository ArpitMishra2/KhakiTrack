import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import '../data/training_logic.dart';
import '../gps/location_source.dart';
import '../gps/pacer.dart';
import '../gps/run_analysis.dart';
import '../gps/run_recorder.dart';
import '../gps/run_repository.dart';
import '../gps/voice_coach.dart';
import '../l10n/app_localizations.dart';
import '../weather/weather_card.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../theme/widgets.dart';
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
    this.voice,
    this.buzzer,
    this.now,
  });

  final String examId;
  final int runMetres;
  final int targetSeconds;

  /// Mock PET over the exam distance, or a free run.
  final bool mockPet;
  final LocationSource source;
  final RunRepository runs;

  /// Spoken updates; defaults to the phone's text-to-speech.
  final VoiceCoach? voice;

  /// Vibrates when a mock PET falls behind pace; defaults to the phone motor.
  final Buzzer? buzzer;

  /// Clock for the heat warning; defaults to now.
  final DateTime? now;

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
  VoiceCoach? _voice;
  Announcer? _announcer;
  Pacer? _pacer;
  bool _voiceOn = true;
  final Buzzer _buzzer = PhoneBuzzer();

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

  void _speak(List<String> lines) {
    if (!_voiceOn) return;
    for (final l in lines) {
      _voice?.say(l);
    }
  }

  CoachPhrases _phrases(AppLocalizations l10n) => CoachPhrases(
    started: l10n.voiceStarted,
    kmDone: l10n.voiceKmDone,
    halfway: l10n.voiceHalfway,
    lastStretch: (m) => l10n.voiceLastStretch(m),
    ahead: (s) => l10n.voiceAhead(s),
    behind: (s) => l10n.voiceBehind(s),
    cheers: [
      l10n.voiceCheer1,
      l10n.voiceCheer2,
      l10n.voiceCheer3,
      l10n.voiceCheer4,
    ],
    finished: l10n.voiceFinished,
  );

  void _start() {
    final l10n = AppLocalizations.of(context);
    _voice = widget.voice ?? TtsVoiceCoach(l10n.localeName);
    _announcer = Announcer(
      phrases: _phrases(l10n),
      targetM: widget.mockPet ? widget.runMetres : null,
      targetSeconds: widget.mockPet ? widget.targetSeconds : null,
    );
    _pacer = widget.mockPet
        ? Pacer(targetM: widget.runMetres, targetSeconds: widget.targetSeconds)
        : null;
    String spoken(double s) =>
        Announcer.spokenTime(s, (m, sec) => l10n.voiceTime(m, sec));
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
        final live = r.live;
        if (live != null) {
          _speak(_announcer!.update(live.distanceM, live.durationS, spoken));
          if (_pacer?.shouldBuzz(live.distanceM, live.durationS) ?? false) {
            (widget.buzzer ?? _buzzer).buzz();
          }
        }
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
    _speak([_announcer!.phrases.finished]);
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
    _voice?.stop();
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
          actions: [
            if (_phase == _Phase.running)
              IconButton(
                tooltip: _voiceOn ? l10n.voiceOn : l10n.voiceOff,
                icon: Icon(_voiceOn ? Icons.volume_up : Icons.volume_off),
                onPressed: () {
                  setState(() => _voiceOn = !_voiceOn);
                  if (!_voiceOn) _voice?.stop();
                },
              ),
          ],
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

  /// 5000 -> "5", 4800 -> "4.8": digits only, for the numeral font.
  static String _kmNumber(int metres) {
    final km = metres / 1000;
    return km == km.roundToDouble()
        ? km.toStringAsFixed(0)
        : km.toStringAsFixed(1);
  }

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
              WeatherCard(now: widget.now ?? DateTime.now()),
              if (widget.mockPet)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: BigStat(
                            value: _kmNumber(widget.runMetres),
                            label:
                                '${l10n.distanceLabel} (${l10n.km('').trim()})',
                            size: 52,
                            color: Brand.saffron,
                            crossAxisAlignment: CrossAxisAlignment.center,
                          ),
                        ),
                        Expanded(
                          child: BigStat(
                            value: formatDuration(widget.targetSeconds),
                            label: l10n
                                .targetLine('')
                                .replaceAll(':', '')
                                .trim(),
                            size: 52,
                            color: Colors.white,
                            crossAxisAlignment: CrossAxisAlignment.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      PingDot(
                        active: ready,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ready
                                ? Brand.saffron
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                          child: Icon(
                            ready ? Icons.gps_fixed : Icons.gps_not_fixed,
                            color: ready ? Brand.ink : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          acc == null
                              ? l10n.gpsSearching
                              : ready
                              ? '${l10n.gpsReady} · ${l10n.gpsAccuracy(acc.round())}'
                              : l10n.gpsAccuracy(acc.round()),
                          style: textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                ),
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
    final colors = Theme.of(context).colorScheme;
    final dist = r.live?.distanceM ?? 0;
    final elapsed = r.elapsedS;
    final speed = r.recentSpeed();
    final target = widget.runMetres;
    final delta = widget.mockPet
        ? paceDelta(dist, elapsed, target, widget.targetSeconds)
        : null;
    final km = (dist / 1000).toStringAsFixed(2);
    final pace = speed == null || speed < 0.5
        ? '–'
        : formatDuration(1000 / speed);

    // The numbers scroll on very short screens; the stop button never does.
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final compact = box.maxHeight < 520;
              final ring = (box.maxHeight * (compact ? 0.42 : 0.4)).clamp(
                120.0,
                300.0,
              );
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                      child: Column(
                        children: [
                          Text(
                            l10n.elapsed,
                            style: textTheme.labelLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          FittedBox(
                            child: Text(
                              formatDuration(elapsed),
                              style: numerals(
                                compact ? 56 : 104,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          SizedBox.square(
                            dimension: ring,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                end: widget.mockPet
                                    ? (dist / target).clamp(0.0, 1.0)
                                    : 0,
                              ),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOut,
                              builder: (context, v, child) => CustomPaint(
                                painter: _RingPainter(
                                  progress: widget.mockPet ? v : null,
                                  color: Brand.saffron,
                                  track: colors.outlineVariant,
                                ),
                                child: child,
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        km,
                                        style: numerals(
                                          ring * 0.34,
                                          color: Brand.saffron,
                                        ),
                                      ),
                                      Text(
                                        l10n.distanceLabel,
                                        style: textTheme.labelLarge?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (widget.mockPet) ...[
                            Text(
                              l10n.remaining(
                                distanceText(
                                  l10n,
                                  (target - dist).clamp(0, target).round(),
                                ),
                              ),
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (delta != null && dist > 50)
                              Pill(
                                delta >= 0
                                    ? l10n.aheadBy(formatDuration(delta))
                                    : l10n.behindBy(formatDuration(-delta)),
                                icon: delta >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                background: delta >= 0
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFC62828),
                                foreground: Colors.white,
                              ),
                          ],
                          const Spacer(),
                          BigStat(
                            value: pace,
                            label:
                                '${l10n.paceLabel} ${l10n.minPerKm('').trim()}',
                            size: compact ? 34 : 48,
                            color: Colors.white,
                            crossAxisAlignment: CrossAxisAlignment.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: GestureDetector(
            onLongPress: _finish,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: colors.outline),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stop_circle_outlined),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.holdToStop,
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (widget.mockPet) ...[
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: outcome == PetOutcome.qualified
                        ? Brand.saffron
                        : colors.secondaryContainer,
                  ),
                  child: Icon(
                    switch (outcome) {
                      PetOutcome.qualified => Icons.emoji_events,
                      PetOutcome.borderline => Icons.warning_amber,
                      _ => Icons.trending_up,
                    },
                    size: 52,
                    color: outcome == PetOutcome.qualified ? Brand.ink : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                switch (outcome) {
                  PetOutcome.qualified => l10n.outcomeQualified,
                  PetOutcome.borderline => l10n.outcomeBorderline,
                  PetOutcome.notQualified => l10n.outcomeNotQualified,
                  PetOutcome.incomplete => l10n.outcomeIncomplete,
                },
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (finish != null) ...[
                Text(
                  l10n.finishTime(distance, formatDuration(finish)),
                  style: textTheme.headlineSmall?.copyWith(
                    color: Brand.saffron,
                  ),
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
            Row(
              children: [
                Expanded(
                  child: BigStat(
                    value: (r.distanceM / 1000).toStringAsFixed(2),
                    label: '${l10n.distanceLabel} (${l10n.km('').trim()})',
                    size: 40,
                    color: Colors.white,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                ),
                Expanded(
                  child: BigStat(
                    value: formatDuration(r.durationS),
                    label: l10n.elapsed,
                    size: 40,
                    color: Colors.white,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                ),
                Expanded(
                  child: BigStat(
                    value: r.distanceM > 0
                        ? formatDuration(r.durationS / (r.distanceM / 1000))
                        : '–',
                    label: '${l10n.paceLabel} ${l10n.minPerKm('').trim()}',
                    size: 40,
                    color: Colors.white,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                ),
              ],
            ),
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
            if (widget.mockPet && finish != null && verdict == 'verified') ...[
              OutlinedButton.icon(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text: l10n.sharePetText(
                      distance,
                      formatDuration(finish),
                      finish <= widget.targetSeconds
                          ? l10n.marginAhead(
                              formatDuration(widget.targetSeconds - finish),
                            )
                          : l10n.marginBehind(
                              formatDuration(finish - widget.targetSeconds),
                            ),
                      switch (outcome) {
                        PetOutcome.qualified => l10n.outcomeQualified,
                        PetOutcome.borderline => l10n.outcomeBorderline,
                        _ => '',
                      },
                    ),
                  ),
                ),
                icon: const Icon(Icons.share),
                label: Text(l10n.shareButton),
              ),
              const SizedBox(height: 8),
            ],
            FilledButton(
              onPressed: _uploading ? null : () => Navigator.pop(context, true),
              child: Text(l10n.done),
            ),
          ],
        ),
        if (widget.mockPet && outcome == PetOutcome.qualified)
          const Positioned.fill(child: ConfettiBurst()),
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

/// Progress ring: an arc from the top, or a plain dim ring when [progress]
/// is null (free run, no target).
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double? progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const width = 14.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(width / 2);
    canvas.drawArc(
      arc,
      0,
      2 * pi,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
    final p = progress;
    if (p != null && p > 0) {
      canvas.drawArc(
        arc,
        -pi / 2,
        2 * pi * p,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
