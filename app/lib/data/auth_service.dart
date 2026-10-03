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

  /// Erases the account and all its data on the server, then signs out.
  /// Throws if that fails (for example offline): nothing is removed then.
  Future<void> deleteAccount();
}

/// Native Google sign-in (Android Credential Manager) exchanged for a
/// Supabase session with signInWithIdToken. The ID token is issued for the
/// Web client ID, which is the client ID configured in Supabase.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client, {this.onDeleted});

  final SupabaseClient _client;

  /// Called with the user id once the account is gone, to wipe local copies.
  final Future<void> Function(String userId)? onDeleted;
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
  Future<void> deleteAccount() async {
    final id = _client.auth.currentUser?.id;
    // The server removes the account and, through cascades, all its data.
    await _client.rpc('delete_my_account');
    if (id != null) await onDeleted?.call(id);
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } on Object {
      // The session died with the account; the local sign-out still counts.
    }
    if (_googleInit != null) await GoogleSignIn.instance.signOut();
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    // So the next sign-in offers the account picker again.
    if (_googleInit != null) await GoogleSignIn.instance.signOut();
  }
}
