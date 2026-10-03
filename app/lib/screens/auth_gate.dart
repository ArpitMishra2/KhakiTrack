import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import '../data/exam_repository.dart';
import '../data/leaderboard_repository.dart';
import '../data/profile.dart';
import '../data/training_repository.dart';
import '../gps/location_source.dart';
import '../gps/run_repository.dart';
import '../l10n/app_localizations.dart';
import 'home_shell.dart';
import 'load_error.dart';
import 'profile_setup_screen.dart';
import 'sign_in_screen.dart';

/// Shows sign-in until there is a session, then profile setup until the
/// profile is complete, then the app.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.auth,
    required this.repository,
    required this.profiles,
    required this.training,
    required this.runs,
    required this.location,
    required this.boards,
  });

  final AuthService auth;
  final ExamRepository repository;
  final ProfileRepository profiles;
  final TrainingRepository training;
  final RunRepository runs;
  final LeaderboardRepository boards;
  final LocationSource Function(AppLocalizations) location;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: auth.signedInChanges,
      initialData: auth.isSignedIn,
      builder: (context, snapshot) => snapshot.data == true
          ? _ProfileGate(
              auth: auth,
              repository: repository,
              profiles: profiles,
              training: training,
              runs: runs,
              location: location,
              boards: boards,
            )
          : SignInScreen(auth: auth),
    );
  }
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate({
    required this.auth,
    required this.repository,
    required this.profiles,
    required this.training,
    required this.runs,
    required this.location,
    required this.boards,
  });

  final AuthService auth;
  final ExamRepository repository;
  final ProfileRepository profiles;
  final TrainingRepository training;
  final RunRepository runs;
  final LeaderboardRepository boards;
  final LocationSource Function(AppLocalizations) location;

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late Future<Profile> _profile = widget.profiles.fetchMine();
  bool _localeSynced = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: LoadError(
                onRetry: () => setState(() {
                  _profile = widget.profiles.fetchMine();
                }),
              ),
            ),
          );
        }
        final profile = snapshot.data;
        if (profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!profile.isComplete) {
          return ProfileSetupScreen(
            initial: profile,
            profiles: widget.profiles,
            exams: widget.repository,
            onSaved: (saved) => setState(() {
              _profile = Future.value(saved);
            }),
          );
        }
        if (!_localeSynced) {
          // Plans are written in the language the profile says; keep it in
          // step with the language the app is showing.
          _localeSynced = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.profiles.saveLocale(
                Localizations.localeOf(context).languageCode,
              );
            }
          });
        }
        return HomeShell(
          exams: widget.repository,
          training: widget.training,
          runs: widget.runs,
          location: widget.location,
          boards: widget.boards,
          auth: widget.auth,
          profile: profile,
        );
      },
    );
  }
}
