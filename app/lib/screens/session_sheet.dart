import 'package:flutter/material.dart';

import '../data/training_logic.dart';
import '../data/training_models.dart';
import '../data/training_repository.dart';
import '../l10n/app_localizations.dart';
import 'training_labels.dart';

/// Session details and the form to log it. Pops true after saving.
class SessionSheet extends StatefulWidget {
  const SessionSheet({
    super.key,
    required this.plan,
    required this.week,
    required this.index,
    required this.session,
    required this.training,
    required this.today,
  });

  final TrainingPlan plan;
  final int week;
  final int index;
  final PlanSession session;
  final TrainingRepository training;
  final DateTime today;

  @override
  State<SessionSheet> createState() => _SessionSheetState();
}

class _SessionSheetState extends State<SessionSheet> {
  late final SessionLog? _existing = widget.plan.logFor(
    widget.week,
    widget.index,
  );
  late String _status = _existing?.status ?? 'done';
  late final _distance = TextEditingController(
    text:
        (_existing?.distanceKm ?? widget.session.distanceKm)?.toString() ?? '',
  );
  late final _time = TextEditingController(
    text: _existing?.durationSeconds == null
        ? ''
        : formatDuration(_existing!.durationSeconds!),
  );
  late int? _effort = _existing?.effort;
  late bool _pain = _existing?.pain ?? false;
  late final _note = TextEditingController(text: _existing?.note ?? '');
  bool _saving = false;
  bool _failed = false;

  bool get _isRun => widget.session.distanceKm != null;

  @override
  void dispose() {
    _distance.dispose();
    _time.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final km = double.tryParse(_distance.text.replaceAll(',', '.'));
    final seconds = parseDuration(_time.text);
    final ran = _status != 'missed';
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.training.saveLog(
        widget.plan.id,
        SessionLog(
          week: widget.week,
          sessionIndex: widget.index,
          status: _status,
          distanceKm: ran && _isRun ? km : null,
          durationSeconds: ran ? seconds : null,
          effort: ran ? _effort : null,
          pain: _pain,
          note: _note.text,
        ),
      );
      // A completed time trial also counts as a progress point.
      if (widget.session.type == 'time_trial' &&
          _status == 'done' &&
          km != null &&
          km > 0 &&
          seconds != null) {
        await widget.training.addTimeTrial(
          widget.plan.examId,
          TimeTrial(
            distanceM: (km * 1000).round(),
            durationSeconds: seconds,
            recordedOn: widget.today,
            source: 'plan',
          ),
        );
      }
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
    final textTheme = Theme.of(context).textTheme;
    final s = widget.session;
    final summary = sessionSummary(l10n, s);
    final ran = _status != 'missed';

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.title, style: textTheme.titleLarge),
            Text(
              [
                sessionTypeLabel(l10n, s.type),
                if (summary.isNotEmpty) summary,
              ].join(' · '),
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(s.details),
            const Divider(height: 32),
            Text(l10n.logSession, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                for (final v in const ['done', 'partial', 'missed'])
                  ButtonSegment(value: v, label: Text(statusLabel(l10n, v))),
              ],
              selected: {_status},
              onSelectionChanged: (v) => setState(() => _status = v.first),
            ),
            if (ran) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_isRun) ...[
                    Expanded(
                      child: TextField(
                        controller: _distance,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.logDistance,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: TextField(
                      controller: _time,
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        labelText: l10n.logTime,
                        hintText: l10n.qTimeHint,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(l10n.logEffort),
              Wrap(
                spacing: 8,
                children: [
                  for (var e = 1; e <= 5; e++)
                    ChoiceChip(
                      label: Text('$e'),
                      selected: _effort == e,
                      onSelected: (on) =>
                          setState(() => _effort = on ? e : null),
                    ),
                ],
              ),
            ],
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _pain,
              onChanged: (v) => setState(() => _pain = v ?? false),
              title: Text(l10n.logPain),
            ),
            if (_pain)
              Text(
                l10n.painWarning,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            TextField(
              controller: _note,
              maxLength: 500,
              decoration: InputDecoration(labelText: l10n.logNote),
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
            if (_failed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.saveFailed,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
