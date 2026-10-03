import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/gps/run_queue.dart';

void main() {
  late Directory dir;
  late RunQueue queue;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('maidan_queue');
    queue = RunQueue(() async => dir);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Map<String, dynamic> run(String id) => {'id': id, 'points': <Object>[]};

  test('a run is only ever sent by the account that recorded it', () async {
    await queue.add(run('a1'), 'alice');
    await queue.add(run('b1'), 'bob');
    expect(await queue.count('alice'), 1);
    expect(await queue.count('bob'), 1);

    final sentBy = <String>[];
    // Bob signs in on the same phone and flushes.
    final n = await queue.flush('bob', (r) async {
      sentBy.add('bob:${r['id']}');
      return SendOutcome.sent;
    });
    expect(n, 1);
    expect(sentBy, ['bob:b1']); // Alice's run was not touched
    expect(await queue.count('alice'), 1);
    expect(await queue.count('bob'), 0);

    // Alice signs back in and gets her own run sent.
    await queue.flush('alice', (r) async {
      sentBy.add('alice:${r['id']}');
      return SendOutcome.sent;
    });
    expect(sentBy, ['bob:b1', 'alice:a1']);
  });

  test(
    'kept runs stay, refused runs are forgotten, sent runs are counted',
    () async {
      for (final id in ['keep', 'drop', 'ok']) {
        await queue.add(run(id), 'alice');
      }
      final n = await queue.flush(
        'alice',
        (r) async => switch (r['id']) {
          'keep' => SendOutcome.keep,
          'drop' => SendOutcome.dropped,
          _ => SendOutcome.sent,
        },
      );
      expect(n, 1);
      expect(await queue.count('alice'), 1);
      final left = <String>[];
      await queue.flush('alice', (r) async {
        left.add(r['id'] as String);
        return SendOutcome.keep;
      });
      expect(left, ['keep']);
    },
  );

  test('the owner label is stored with the run', () async {
    await queue.add(run('x'), 'alice');
    final text = File('${dir.path}/pending_runs.json').readAsStringSync();
    expect(text, contains('"queued_for":"alice"'));
  });

  test(
    'runs queued before owners were recorded go to the first account that asks',
    () async {
      File('${dir.path}/pending_runs.json').writeAsStringSync('[{"id":"old"}]');
      expect(await queue.count('alice'), 1);
      final sent = <String>[];
      await queue.flush('alice', (r) async {
        sent.add(r['id'] as String);
        return SendOutcome.sent;
      });
      expect(sent, ['old']);
      expect(await queue.count('bob'), 0);
    },
  );

  test('deleting an account erases its queued runs and only those', () async {
    await queue.add(run('a1'), 'alice');
    await queue.add(run('b1'), 'bob');
    await queue.forget('alice');
    expect(await queue.count('alice'), 0);
    expect(await queue.count('bob'), 1);
    final text = File('${dir.path}/pending_runs.json').readAsStringSync();
    expect(text, isNot(contains('alice')));
  });

  test('a damaged file is treated as empty, not a crash', () async {
    File('${dir.path}/pending_runs.json').writeAsStringSync('not json');
    expect(await queue.count('alice'), 0);
    await queue.add(run('new'), 'alice');
    expect(await queue.count('alice'), 1);
  });

  test('flushing an empty queue does nothing', () async {
    expect(await queue.flush('alice', (_) async => SendOutcome.sent), 0);
    expect(File('${dir.path}/pending_runs.json').existsSync(), isFalse);
  });
}
