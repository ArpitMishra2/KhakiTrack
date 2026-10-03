import 'dart:convert';
import 'dart:io';

import 'profile.dart';

/// Wraps the profile store so a sign-out, a flaky network or a briefly empty
/// answer from the server can never send a returning user back to the empty
/// "About you" form.
///
/// Every complete profile is also written to a file named after the user. When
/// the server answers with an empty or incomplete profile (or fails) and that
/// file holds a complete one, the saved copy is used and written back to the
/// server. An empty answer is asked for once more first, since the session may
/// not have been attached yet right after signing in.
class CachedProfileRepository implements ProfileRepository {
  CachedProfileRepository(
    this._inner,
    this._dir,
    this._userId, {
    this.retryDelay = const Duration(milliseconds: 800),
  });

  final ProfileRepository _inner;
  final Future<Directory> Function() _dir;
  final String? Function() _userId;
  final Duration retryDelay;

  Future<File?> _file() async {
    final id = _userId();
    if (id == null) return null;
    return File('${(await _dir()).path}/profile_$id.json');
  }

  Future<Profile?> _read() async {
    try {
      final f = await _file();
      if (f == null || !await f.exists()) return null;
      return Profile.fromJson(
        jsonDecode(await f.readAsString()) as Map<String, dynamic>,
      );
    } on Object {
      return null; // A damaged copy is as good as none.
    }
  }

  Future<void> _write(Profile p) async {
    try {
      final f = await _file();
      if (f != null) await f.writeAsString(jsonEncode(p.toJson()));
    } on Object {
      // Best effort: the server copy is the main one.
    }
  }

  @override
  String? get suggestedName => _inner.suggestedName;

  @override
  Future<Profile> fetchMine() async {
    Profile? remote;
    Object? failure;
    try {
      remote = await _inner.fetchMine();
      if (!remote.isComplete) {
        await Future<void>.delayed(retryDelay);
        remote = await _inner.fetchMine();
      }
    } on Object catch (e) {
      failure = e;
    }
    if (remote != null && remote.isComplete) {
      await _write(remote);
      return remote;
    }
    final saved = await _read();
    if (saved != null && saved.isComplete) {
      try {
        await _inner.saveMine(saved); // Put the server copy back.
      } on Object {
        // Offline: still use the saved copy.
      }
      return saved;
    }
    if (failure != null) throw failure;
    return remote!;
  }

  @override
  Future<void> saveMine(Profile profile) async {
    await _inner.saveMine(profile);
    await _write(profile);
  }

  @override
  Future<void> saveLocale(String code) => _inner.saveLocale(code);
}
