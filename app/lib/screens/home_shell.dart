import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import '../data/exam_repository.dart';
import '../data/profile.dart';
import '../data/training_repository.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'progress_tab.dart';
import 'training_tab.dart';

/// Signed-in app: training (default), standards and progress tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.exams,
    required this.training,
    required this.auth,
    required this.profile,
    this.today,
  });

  final ExamRepository exams;
  final TrainingRepository training;
  final AuthService auth;
  final Profile profile;

  /// Fixed date for tests; defaults to now.
  final DateTime? today;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          TrainingTab(
            exams: widget.exams,
            training: widget.training,
            profile: widget.profile,
            today: widget.today,
          ),
          HomeScreen(
            repository: widget.exams,
            auth: widget.auth,
            profile: widget.profile,
          ),
          ProgressTab(
            exams: widget.exams,
            training: widget.training,
            profile: widget.profile,
            today: widget.today,
            visible: _tab == 2,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.directions_run),
            label: l10n.tabTraining,
          ),
          NavigationDestination(
            icon: const Icon(Icons.rule),
            label: l10n.tabStandards,
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart),
            label: l10n.tabProgress,
          ),
        ],
      ),
    );
  }
}
