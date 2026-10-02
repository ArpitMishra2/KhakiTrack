import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import '../data/exam_repository.dart';
import '../data/profile.dart';
import 'home_screen.dart';
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
  });

  final AuthService auth;
  final ExamRepository repository;
  final ProfileRepository profiles;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: auth.signedInChanges,
      initialData: auth.isSignedIn,
      builder: (context, snapshot) => snapshot.data == true
          ? _ProfileGate(auth: auth, repository: repository, profiles: profiles)
          : SignInScreen(auth: auth),
    );
  }
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate({
    required this.auth,
    required this.repository,
    required this.profiles,
  });

  final AuthService auth;
  final ExamRepository repository;
  final ProfileRepository profiles;

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late Future<Profile> _profile = widget.profiles.fetchMine();

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
        return HomeScreen(
          repository: widget.repository,
          auth: widget.auth,
          profile: profile,
        );
      },
    );
  }
}
