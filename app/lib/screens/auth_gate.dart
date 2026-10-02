import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import '../data/exam_repository.dart';
import 'home_screen.dart';
import 'sign_in_screen.dart';

/// Shows sign-in until there is a session, then the app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.auth, required this.repository});

  final AuthService auth;
  final ExamRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: auth.signedInChanges,
      initialData: auth.isSignedIn,
      builder: (context, snapshot) => snapshot.data == true
          ? HomeScreen(repository: repository, auth: auth)
          : SignInScreen(auth: auth),
    );
  }
}
