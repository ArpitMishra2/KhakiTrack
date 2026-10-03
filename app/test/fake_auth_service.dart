import 'dart:async';

import 'package:maidan/data/auth_service.dart';

/// Signs in instantly with [nextResult]; starts signed in when [signedIn].
class FakeAuthService implements AuthService {
  FakeAuthService({bool signedIn = true}) : _signedIn = signedIn;

  bool _signedIn;
  SignInResult nextResult = SignInResult.signedIn;
  final _changes = StreamController<bool>.broadcast();

  @override
  bool get isSignedIn => _signedIn;

  @override
  Stream<bool> get signedInChanges => _changes.stream;

  @override
  Future<SignInResult> signInWithGoogle() async {
    if (nextResult == SignInResult.signedIn) {
      _signedIn = true;
      _changes.add(true);
    }
    return nextResult;
  }

  bool deleted = false;
  bool failDelete = false;

  @override
  Future<void> deleteAccount() async {
    if (failDelete) throw Exception('offline');
    deleted = true;
    await signOut();
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
    _changes.add(false);
  }
}
