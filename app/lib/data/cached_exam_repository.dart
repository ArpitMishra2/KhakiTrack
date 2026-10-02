import 'dart:convert';
import 'dart:io';

import 'exam_models.dart';
import 'exam_repository.dart';

/// Wraps another [ExamRepository]: every successful fetch is saved to a
/// file, and when the network fails the last saved copy is returned, so
/// standards still open on a ground with no signal. Throws only if there
/// is neither network nor a saved copy.
class CachedExamRepository implements ExamRepository {
  CachedExamRepository(this._inner, this._dir);

  final ExamRepository _inner;
  final Future<Directory> Function() _dir;

  Future<File> _file(String name) async =>
      File('${(await _dir()).path}/cache_$name.json');

  Future<T> _cached<T>(
    String name,
    Future<T> Function() fetch,
    Object Function(T) encode,
    T Function(Object?) decode,
  ) async {
    try {
      final fresh = await fetch();
      try {
        await (await _file(name)).writeAsString(jsonEncode(encode(fresh)));
      } on FileSystemException {
        // Caching is best effort.
      }
      return fresh;
    } catch (e) {
      final f = await _file(name);
      if (await f.exists()) {
        try {
          return decode(jsonDecode(await f.readAsString()));
        } on FormatException {
          // Corrupt cache: fall through to the original error.
        }
      }
      rethrow;
    }
  }

  @override
  Future<List<Exam>> fetchExams() => _cached(
    'exams',
    _inner.fetchExams,
    (list) => [
      for (final e in list)
        {
          'id': e.id,
          'name_hi': e.nameHi,
          'name_en': e.nameEn,
          'data_version': e.dataVersion,
        },
    ],
    (j) =>
        (j! as List).cast<Map<String, dynamic>>().map(Exam.fromJson).toList(),
  );

  @override
  Future<List<Standard>> fetchStandards(String examId) => _cached(
    'standards_$examId',
    () => _inner.fetchStandards(examId),
    (list) => [
      for (final s in list)
        {
          'gender': s.gender,
          'category': s.category,
          'event': s.event,
          'kind': s.kind,
          'value': s.value,
          'source_url': s.sourceUrl,
          'verified': s.verified,
        },
    ],
    (j) => (j! as List)
        .cast<Map<String, dynamic>>()
        .map(Standard.fromJson)
        .toList(),
  );
}
