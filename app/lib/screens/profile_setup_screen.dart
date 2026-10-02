import 'package:flutter/material.dart';

import '../data/exam_models.dart';
import '../data/exam_repository.dart';
import '../data/profile.dart';
import '../l10n/app_localizations.dart';
import 'load_error.dart';

/// First-run form: name, gender, date of birth (18+), exam and category.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
    required this.initial,
    required this.profiles,
    required this.exams,
    required this.onSaved,
    this.today,
  });

  final Profile initial;
  final ProfileRepository profiles;
  final ExamRepository exams;
  final ValueChanged<Profile> onSaved;

  /// Fixed date for tests; defaults to now.
  final DateTime? today;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final _name = TextEditingController(
    text: widget.initial.displayName ?? widget.profiles.suggestedName ?? '',
  );
  late String? _gender = widget.initial.gender;
  late DateTime? _dob = widget.initial.dateOfBirth;
  late String? _category = widget.initial.category;
  late String? _examId = widget.initial.examId;
  late Future<List<Exam>> _examList = widget.exams.fetchExams();
  bool _saving = false;
  bool _saveFailed = false;

  DateTime get _today => widget.today ?? DateTime.now();

  Profile get _profile => Profile(
    displayName: _name.text,
    gender: _gender,
    dateOfBirth: _dob,
    category: _category,
    examId: _examId,
  );

  bool get _canSave =>
      !_saving && _profile.isComplete && isAdult(_dob!, _today);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final latest = latestAllowedDateOfBirth(_today);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(latest.year - 2, latest.month, latest.day),
      firstDate: DateTime(latest.year - 42),
      lastDate: latest,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    final profile = _profile;
    try {
      await widget.profiles.saveMine(profile);
      widget.onSaved(profile);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final textTheme = Theme.of(context).textTheme;
    final dob = _dob;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.profileIntro),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l10n.name),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text(l10n.gender, style: textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            emptySelectionAllowed: true,
            segments: [
              ButtonSegment(value: 'male', label: Text(l10n.male)),
              ButtonSegment(value: 'female', label: Text(l10n.female)),
            ],
            selected: {?_gender},
            onSelectionChanged: (s) =>
                setState(() => _gender = s.isEmpty ? null : s.first),
          ),
          const SizedBox(height: 16),
          Text(l10n.dateOfBirth, style: textTheme.titleSmall),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickDob,
            icon: const Icon(Icons.calendar_today),
            label: Text(
              dob == null
                  ? l10n.chooseDate
                  : '${dob.day.toString().padLeft(2, '0')}-'
                        '${dob.month.toString().padLeft(2, '0')}-${dob.year}',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l10n.adultsOnly, style: textTheme.bodySmall),
          ),
          const SizedBox(height: 16),
          Text(l10n.category, style: textTheme.titleSmall),
          DropdownButton<String>(
            isExpanded: true,
            hint: Text(l10n.chooseCategory),
            value: _category,
            items: [
              for (final c in socialCategories)
                DropdownMenuItem(value: c, child: Text(_socialLabel(l10n, c))),
            ],
            onChanged: (c) => setState(() => _category = c),
          ),
          const SizedBox(height: 16),
          Text(l10n.chooseExam, style: textTheme.titleSmall),
          FutureBuilder<List<Exam>>(
            future: _examList,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return LoadError(
                  onRetry: () => setState(() {
                    _examList = widget.exams.fetchExams();
                  }),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return RadioGroup<String>(
                groupValue: _examId,
                onChanged: (v) => setState(() => _examId = v),
                child: Column(
                  children: [
                    for (final e in snapshot.data!)
                      RadioListTile<String>(
                        value: e.id,
                        title: Text(e.nameFor(language)),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _canSave ? _save : null,
            child: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
          if (_saveFailed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                l10n.saveFailed,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

String _socialLabel(AppLocalizations l10n, String c) => switch (c) {
  'general' => l10n.socialGeneral,
  'obc' => l10n.socialObc,
  'sc' => l10n.socialSc,
  'st' => l10n.socialSt,
  'ews' => l10n.socialEws,
  _ => c,
};
