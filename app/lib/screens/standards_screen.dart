import 'package:flutter/material.dart';

import '../data/exam_models.dart';
import '../data/exam_repository.dart';
import '../data/profile.dart';
import '../data/standards_logic.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'load_error.dart';
import 'standard_labels.dart';

/// Pick gender and category, then see the exact PST and PET standards.
class StandardsScreen extends StatefulWidget {
  const StandardsScreen({
    super.key,
    required this.exam,
    required this.repository,
    required this.profile,
  });

  final Exam exam;
  final ExamRepository repository;

  /// Pre-selects gender and category; the user can still change both.
  final Profile profile;

  @override
  State<StandardsScreen> createState() => _StandardsScreenState();
}

class _StandardsScreenState extends State<StandardsScreen> {
  late Future<List<Standard>> _standards = _load();
  late String _gender = widget.profile.gender ?? 'male';
  String? _category;

  Future<List<Standard>> _load() =>
      widget.repository.fetchStandards(widget.exam.id);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(widget.exam.nameFor(language))),
      body: FutureBuilder<List<Standard>>(
        future: _standards,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return LoadError(
              onRetry: () => setState(() {
                _standards = _load();
              }),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _body(context, l10n, snapshot.data!);
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    List<Standard> everyAge,
  ) {
    final dob = widget.profile.dateOfBirth;
    final age = dob == null ? null : ageOn(dob, DateTime.now());
    final all = forAge(everyAge, age);
    final ageBanded = everyAge.any((s) => s.ageBanded);
    final categories = categoriesFor(all, _gender);
    final fromProfile = standardsCategoryFor(all, widget.profile.category);
    final category = categories.contains(_category)
        ? _category!
        : categories.contains(fromProfile)
        ? fromProfile!
        : (categories.isEmpty ? '' : categories.first);
    final resolved = resolveStandards(all, _gender, category);
    final pst = resolved.where((s) => s.isMeasurement).toList();
    final pet = resolved.where((s) => !s.isMeasurement).toList();
    final unconfirmed =
        resolved.isNotEmpty && resolved.every((s) => !s.verified);
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.gender, style: textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'male', label: Text(l10n.male)),
            ButtonSegment(value: 'female', label: Text(l10n.female)),
          ],
          selected: {_gender},
          onSelectionChanged: (s) => setState(() => _gender = s.first),
        ),
        const SizedBox(height: 16),
        Text(l10n.category, style: textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButton<String>(
          isExpanded: true,
          value: categories.contains(category) ? category : null,
          items: [
            for (final c in categories)
              DropdownMenuItem(
                value: c,
                child: Text(
                  categoryLabel(l10n, c),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (c) => setState(() => _category = c),
        ),
        const SizedBox(height: 16),
        if (ageBanded && age != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(l10n.standardsForAge(age), style: textTheme.bodySmall),
          ),
        if (unconfirmed)
          Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.examUnconfirmed),
            ),
          ),
        if (resolved.isEmpty) Text(l10n.noStandards),
        if (pst.isNotEmpty) _section(l10n, l10n.sectionPst, pst, textTheme),
        if (pet.isNotEmpty) _section(l10n, l10n.sectionPet, pet, textTheme),
        const SizedBox(height: 16),
        Text(
          l10n.sourceNote(widget.exam.dataVersion),
          style: textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _section(
    AppLocalizations l10n,
    String title,
    List<Standard> items,
    TextTheme textTheme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Brand.saffron,
                    ),
                    child: Icon(
                      items.first.isMeasurement
                          ? Icons.straighten
                          : Icons.directions_run,
                      size: 20,
                      color: Brand.ink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: textTheme.titleMedium)),
                ],
              ),
            ),
            // A Row rather than ListTile so long values wrap on small phones.
            for (final s in items)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(eventLabel(l10n, s))),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Brand.khakiSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          valueLabel(l10n, s),
                          style: textTheme.titleMedium,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
