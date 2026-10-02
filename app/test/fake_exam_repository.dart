import 'dart:convert';
import 'dart:io';

import 'package:maidan/data/exam_models.dart';
import 'package:maidan/data/exam_repository.dart';

/// Standards straight from `data/exams/<id>.json` (tests run from app/).
List<Standard> loadDataFile(String examId) {
  final json =
      jsonDecode(File('../data/exams/$examId.json').readAsStringSync())
          as Map<String, dynamic>;
  return (json['standards'] as List)
      .cast<Map<String, dynamic>>()
      .map(Standard.fromJson)
      .toList();
}

const testExams = [
  Exam(
    id: 'ssc_gd',
    nameHi: 'SSC GD कांस्टेबल',
    nameEn: 'SSC GD Constable',
    dataVersion: '1.0',
  ),
  Exam(
    id: 'up_police_constable',
    nameHi: 'यूपी पुलिस कांस्टेबल',
    nameEn: 'UP Police Constable',
    dataVersion: '1.0',
  ),
];

/// Serves the repo's data files; fails while [failing] is true.
class FakeExamRepository implements ExamRepository {
  bool failing = false;

  @override
  Future<List<Exam>> fetchExams() async {
    if (failing) throw Exception('offline');
    return testExams;
  }

  @override
  Future<List<Standard>> fetchStandards(String examId) async {
    if (failing) throw Exception('offline');
    return loadDataFile(examId);
  }
}
