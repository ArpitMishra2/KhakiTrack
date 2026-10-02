import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

enum SignInResult { signedIn, cancelled, failed }

abstract class AuthService {
  bool get isSignedIn;

  /// Emits whenever the user signs in or out.
  Stream<bool> get signedInChanges;

  Future<SignInResult> signInWithGoogle();
  Future<void> signOut();
}

/// Native Google sign-in (Android Credential Manager) exchanged for a
/// Supabase session with signInWithIdToken. The ID token is issued for the
/// Web client ID, which is the client ID configured in Supabase.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;
  Future<void>? _googleInit;

  @override
  bool get isSignedIn => _client.auth.currentSession != null;

  @override
  Stream<bool> get signedInChanges =>
      _client.auth.onAuthStateChange.map((s) => s.session != null);

  @override
  Future<SignInResult> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    try {
      await (_googleInit ??= google.initialize(
        serverClientId: AppConfig.googleWebClientId,
      ));
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return SignInResult.failed;
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      return SignInResult.signedIn;
    } on GoogleSignInException catch (e) {
      return e.code == GoogleSignInExceptionCode.canceled
          ? SignInResult.cancelled
          : SignInResult.failed;
    } on AuthException {
      return SignInResult.failed;
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    // So the next sign-in offers the account picker again.
    if (_googleInit != null) await GoogleSignIn.instance.signOut();
  }
}
