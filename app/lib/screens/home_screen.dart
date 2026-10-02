import 'package:flutter/material.dart';

import '../data/exam_models.dart';
import '../data/exam_repository.dart';
import '../l10n/app_localizations.dart';
import 'load_error.dart';
import 'standards_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final ExamRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Exam>> _exams = widget.repository.fetchExams();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.welcomeTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(l10n.welcomeSubtitle),
          const SizedBox(height: 24),
          Text(l10n.chooseExam, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder<List<Exam>>(
            future: _exams,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return LoadError(
                  onRetry: () => setState(() {
                    _exams = widget.repository.fetchExams();
                  }),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Column(
                children: [
                  for (final exam in snapshot.data!)
                    Card(
                      child: ListTile(
                        title: Text(exam.nameFor(language)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => StandardsScreen(
                              exam: exam,
                              repository: widget.repository,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
