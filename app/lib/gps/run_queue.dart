import 'dart:convert';
import 'dart:io';

/// What happened to one queued run when it was sent.
enum SendOutcome {
  /// The server took it.
  sent,

  /// The server refused it for good (bad data, duplicate): forget it.
  dropped,

  /// Not sent (offline, signed out, busy): try again later.
  keep,
}

/// Runs recorded without a connection, kept in a file until they can be sent.
///
/// Each run remembers which account recorded it and is only ever sent by that
/// account, so signing out and in as someone else cannot hand one person's run
/// to another. Runs queued by an older version carry no owner and are taken
/// by whoever is signed in first.
class RunQueue {
  RunQueue(this._dir);

  final Future<Directory> Function() _dir;

  Future<File> get _file async =>
      File('${(await _dir()).path}/pending_runs.json');

  Future<List<Map<String, dynamic>>> _read() async {
    final f = await _file;
    if (!await f.exists()) return [];
    try {
      return (jsonDecode(await f.readAsString()) as List)
          .cast<Map<String, dynamic>>();
    } on Object {
      return []; // A damaged queue is as good as an empty one.
    }
  }

  Future<void> _write(List<Map<String, dynamic>> runs) async =>
      (await _file).writeAsString(jsonEncode(runs));

  bool _mine(Map<String, dynamic> e, String userId) =>
      (e['queued_for'] as String? ?? userId) == userId;

  Future<void> add(Map<String, dynamic> run, String userId) async => _write([
    ...await _read(),
    {...run, 'queued_for': userId},
  ]);

  Future<int> count(String userId) async =>
      (await _read()).where((e) => _mine(e, userId)).length;

  /// Sends [userId]'s runs through [send]; other accounts' runs stay queued.
  /// Returns how many were sent.
  Future<int> flush(
    String userId,
    Future<SendOutcome> Function(Map<String, dynamic> run) send,
  ) async {
    final all = await _read();
    if (all.isEmpty) return 0;
    final left = <Map<String, dynamic>>[];
    var sent = 0;
    for (final e in all) {
      if (!_mine(e, userId)) {
        left.add(e);
        continue;
      }
      switch (await send(e)) {
        case SendOutcome.sent:
          sent++;
        case SendOutcome.dropped:
          break;
        case SendOutcome.keep:
          left.add(e);
      }
    }
    await _write(left);
    return sent;
  }

  /// Erases everything queued by [userId] (account deleted).
  Future<void> forget(String userId) async {
    final all = await _read();
    final left = all.where((e) => e['queued_for'] != userId).toList();
    if (left.length != all.length) await _write(left);
  }
}
