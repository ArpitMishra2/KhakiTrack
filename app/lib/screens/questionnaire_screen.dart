import 'package:flutter/material.dart';

import '../data/training_logic.dart';
import '../data/training_models.dart';
import '../data/training_repository.dart';
import '../l10n/app_localizations.dart';
import 'standard_labels.dart';
import 'training_labels.dart';

/// Four short steps about the candidate, then AI builds the plan.
/// Pops true once the plan exists.
class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({
    super.key,
    required this.runMetres,
    required this.targetSeconds,
    required this.training,
  });

  final int runMetres;
  final int targetSeconds;
  final TrainingRepository training;

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  static const _steps = 4;
  final _a = TrainingAnswers();
  final _time = TextEditingController();
  final _painNote = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  int _step = 0;
  bool _generating = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_time, _painNote, _weight, _height]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _stepValid => switch (_step) {
    0 => _a.levelComplete,
    1 => _a.experienceComplete,
    2 => _a.scheduleComplete,
    _ => true,
  };

  Future<void> _create() async {
    _a.painNote = _painNote.text;
    // Out-of-range optional values are dropped rather than rejected.
    final w = double.tryParse(_weight.text);
    final h = double.tryParse(_height.text);
    _a.weightKg = w != null && w >= 30 && w <= 200 ? w : null;
    _a.heightCm = h != null && h >= 120 && h <= 230 ? h : null;
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      await widget.training.createPlan(_a);
      if (mounted) Navigator.pop(context, true);
    } on TrainingException catch (e) {
      if (mounted) {
        setState(() {
          _generating = false;
          _error = trainingErrorText(AppLocalizations.of(context), e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_generating) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    l10n.generatingTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.generatingBody, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final last = _step == _steps - 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.qTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / _steps,
                    minHeight: 8,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.outlineVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.qStep(_step + 1, _steps),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        // A new list per step, so every step starts scrolled to the top.
        key: ValueKey(_step),
        padding: const EdgeInsets.all(16),
        children: [
          ...switch (_step) {
            0 => _level(l10n),
            1 => _experience(l10n),
            2 => _schedule(l10n),
            _ => _health(l10n),
          },
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_step > 0)
                OutlinedButton(
                  onPressed: () => setState(() => _step--),
                  child: Text(l10n.qBack),
                ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(140, 54)),
                onPressed: !_stepValid
                    ? null
                    : last
                    ? _create
                    : () => setState(() => _step++),
                child: Text(last ? l10n.qCreate : l10n.qNext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );

  Widget _choices<T>(
    List<T> values,
    String Function(T) label,
    T? selected,
    ValueChanged<T> onSelect,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final v in values)
        ChoiceChip(
          label: Text(label(v)),
          selected: selected == v,
          onSelected: (_) => setState(() => onSelect(v)),
        ),
    ],
  );

  /// Multi-select where 'none' excludes everything else.
  Widget _multi(
    Map<String, String> options,
    Set<String> selected, {
    String? none,
  }) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final e in options.entries)
        FilterChip(
          label: Text(e.value),
          selected: selected.contains(e.key),
          onSelected: (on) => setState(() {
            if (on) {
              if (e.key == none) {
                selected.clear();
              } else if (none != null) {
                selected.remove(none);
              }
              selected.add(e.key);
            } else {
              selected.remove(e.key);
              if (selected.isEmpty && none != null) selected.add(none);
            }
          }),
        ),
    ],
  );

  List<Widget> _level(AppLocalizations l10n) {
    final distance = distanceText(l10n, widget.runMetres);
    final timeText = _time.text;
    return [
      Text(l10n.qLevelTitle, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 4),
      Text(l10n.qTarget(distance, formatDuration(widget.targetSeconds))),
      _title(l10n.qCanComplete(distance)),
      _choices<bool>(
        const [true, false],
        (v) => v ? l10n.yes : l10n.no,
        _a.canCompleteDistance,
        (v) => _a.canCompleteDistance = v,
      ),
      if (_a.canCompleteDistance == true) ...[
        _title(l10n.qCurrentTime(distance)),
        TextField(
          controller: _time,
          keyboardType: TextInputType.datetime,
          decoration: InputDecoration(
            hintText: l10n.qTimeHint,
            errorText: timeText.isNotEmpty && parseDuration(timeText) == null
                ? l10n.qTimeInvalid
                : null,
          ),
          onChanged: (t) =>
              setState(() => _a.currentTimeSeconds = parseDuration(t)),
        ),
      ],
      if (_a.canCompleteDistance == false) ...[
        _title(l10n.qLongest),
        _choices<double>(
          const [0.5, 1, 1.5, 2, 3, 4, 5],
          (v) => l10n.km(v == v.roundToDouble() ? '${v.toInt()}' : '$v'),
          _a.longestContinuousKm,
          (v) => _a.longestContinuousKm = v,
        ),
      ],
    ];
  }

  List<Widget> _experience(AppLocalizations l10n) => [
    Text(
      l10n.qExperienceTitle,
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    _title(l10n.qExperience),
    _choices<String>(
      const ['none', 'lt3m', '3to12m', 'gt1y'],
      (v) => switch (v) {
        'none' => l10n.expNone,
        'lt3m' => l10n.expLt3m,
        '3to12m' => l10n.exp3to12m,
        _ => l10n.expGt1y,
      },
      _a.runningExperience,
      (v) => _a.runningExperience = v,
    ),
    _title(l10n.qRunsPerWeek),
    _choices<int>(
      const [0, 1, 2, 3, 4, 5, 6],
      (v) => '$v',
      _a.runsPerWeek,
      (v) => _a.runsPerWeek = v,
    ),
    _title(l10n.qWeeklyKm),
    _choices<double>(
      const [0, 5, 10, 15, 20, 30, 40],
      (v) => l10n.km('${v.toInt()}'),
      _a.weeklyKm,
      (v) => _a.weeklyKm = v,
    ),
    _title(l10n.qBackground),
    _multi({
      'farm_labour': l10n.bgFarm,
      'sports': l10n.bgSports,
      'gym': l10n.bgGym,
    }, _a.background),
  ];

  List<Widget> _schedule(AppLocalizations l10n) => [
    Text(l10n.qScheduleTitle, style: Theme.of(context).textTheme.headlineSmall),
    _title(l10n.qWeeks),
    _choices<int>(
      const [4, 6, 8, 10, 12, 16, 20],
      l10n.weeksN,
      _a.weeksToPet,
      (v) => _a.weeksToPet = v,
    ),
    Text(l10n.qWeeksUnknown, style: Theme.of(context).textTheme.bodySmall),
    _title(l10n.qDays),
    _choices<int>(
      const [3, 4, 5, 6],
      l10n.daysN,
      _a.daysPerWeek,
      (v) => _a.daysPerWeek = v,
    ),
    _title(l10n.qMinutes),
    _choices<int>(
      const [30, 45, 60, 90],
      l10n.minutesN,
      _a.minutesPerSession,
      (v) => _a.minutesPerSession = v,
    ),
    _title(l10n.qTrainingTime),
    _choices<String>(
      const ['morning', 'evening', 'either'],
      (v) => switch (v) {
        'morning' => l10n.timeMorning,
        'evening' => l10n.timeEvening,
        _ => l10n.timeEither,
      },
      _a.trainingTime,
      (v) => _a.trainingTime = v,
    ),
    _title(l10n.qSurface),
    _choices<String>(
      const ['ground', 'road', 'track', 'mixed'],
      (v) => switch (v) {
        'ground' => l10n.surfaceGround,
        'road' => l10n.surfaceRoad,
        'track' => l10n.surfaceTrack,
        _ => l10n.surfaceMixed,
      },
      _a.surface,
      (v) => _a.surface = v,
    ),
  ];

  List<Widget> _health(AppLocalizations l10n) => [
    Text(l10n.qHealthTitle, style: Theme.of(context).textTheme.headlineSmall),
    _title(l10n.qPain),
    _multi(
      {
        'none': l10n.painNone,
        'knee': l10n.painKnee,
        'shin': l10n.painShin,
        'ankle': l10n.painAnkle,
        'back': l10n.painBack,
        'other': l10n.painOther,
      },
      _a.pain,
      none: 'none',
    ),
    if (!_a.pain.contains('none'))
      TextField(
        controller: _painNote,
        maxLength: 200,
        decoration: InputDecoration(labelText: l10n.qPainNote),
      ),
    _title(l10n.qMedical),
    _multi(
      {
        'none': l10n.medNone,
        'asthma': l10n.medAsthma,
        'heart': l10n.medHeart,
        'bp': l10n.medBp,
        'diabetes': l10n.medDiabetes,
        'other': l10n.medOther,
      },
      _a.medical,
      none: 'none',
    ),
    if (!_a.medical.contains('none'))
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          l10n.seeDoctor,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    const SizedBox(height: 16),
    Row(
      children: [
        Expanded(
          child: TextField(
            controller: _weight,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.qWeight),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _height,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.qHeight),
          ),
        ),
      ],
    ),
  ];
}
