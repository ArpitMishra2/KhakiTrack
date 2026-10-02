import 'package:supabase_flutter/supabase_flutter.dart';

import 'exam_models.dart';

abstract class ExamRepository {
  Future<List<Exam>> fetchExams();
  Future<List<Standard>> fetchStandards(String examId);
}

/// Reads exams and standards from Supabase. Both tables are public-read under
/// row-level security, so this works before sign-in.
class SupabaseExamRepository implements ExamRepository {
  SupabaseExamRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Exam>> fetchExams() async {
    final rows = await _client
        .from('exams')
        .select('id, name_hi, name_en, data_version')
        .order('id');
    return rows.map(Exam.fromJson).toList();
  }

  @override
  Future<List<Standard>> fetchStandards(String examId) async {
    final rows = await _client
        .from('standards')
        .select('gender, category, event, kind, value, source_url, verified')
        .eq('exam_id', examId);
    return rows.map(Standard.fromJson).toList();
  }
}
