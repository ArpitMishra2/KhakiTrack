import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/data/cached_exam_repository.dart';

import 'fake_exam_repository.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('maidan_cache'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('serves the last good copy when offline', () async {
    final inner = FakeExamRepository();
    final repo = CachedExamRepository(inner, () async => dir);

    final online = await repo.fetchStandards('ssc_gd');
    final exams = await repo.fetchExams();

    inner.failing = true;
    final offline = await repo.fetchStandards('ssc_gd');
    expect(offline.length, online.length);
    expect(offline.first.value, online.first.value);
    expect(offline.first.sourceUrl, online.first.sourceUrl);
    expect(offline.every((s) => s.isConfirmed), isTrue);
    expect(
      (await repo.fetchExams()).map((e) => e.nameHi),
      exams.map((e) => e.nameHi),
    );
  });

  test('fails when offline with nothing cached', () async {
    final inner = FakeExamRepository()..failing = true;
    final repo = CachedExamRepository(inner, () async => dir);
    expect(repo.fetchStandards('ssc_gd'), throwsException);
  });

  test('a corrupt cache file does not crash', () async {
    final inner = FakeExamRepository();
    final repo = CachedExamRepository(inner, () async => dir);
    await repo.fetchExams();
    File('${dir.path}/cache_exams.json').writeAsStringSync('{not json');
    inner.failing = true;
    expect(repo.fetchExams(), throwsException);
  });
}
