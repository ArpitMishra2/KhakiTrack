import 'package:supabase_flutter/supabase_flutter.dart';

/// Social categories stored in `profiles.category`. `ex_serviceman` is allowed
/// by the schema but not offered yet: its PST/PET rules are not sourced.
const socialCategories = ['general', 'obc', 'sc', 'st', 'ews'];

/// The user's row in `public.profiles`.
class Profile {
  const Profile({
    this.displayName,
    this.gender,
    this.dateOfBirth,
    this.category,
    this.examId,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    displayName: json['display_name'] as String?,
    gender: json['gender'] as String?,
    dateOfBirth: json['date_of_birth'] == null
        ? null
        : DateTime.parse(json['date_of_birth'] as String),
    category: json['category'] as String?,
    examId: json['exam_id'] as String?,
  );

  final String? displayName;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? category;
  final String? examId;

  bool get isComplete =>
      gender != null &&
      dateOfBirth != null &&
      category != null &&
      examId != null &&
      (displayName?.trim().isNotEmpty ?? false);

  Map<String, dynamic> toJson() => {
    'display_name': displayName?.trim(),
    'gender': gender,
    'date_of_birth': dateOfBirth == null ? null : _date(dateOfBirth!),
    'category': category,
    'exam_id': examId,
  };
}

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Latest date of birth that makes someone 18 on [today]. Matches the
/// database check `date_of_birth <= current_date - interval '18 years'`,
/// which maps 29 February to 28 February.
DateTime latestAllowedDateOfBirth(DateTime today) {
  final day = today.month == 2 && today.day == 29 ? 28 : today.day;
  return DateTime(today.year - 18, today.month, day);
}

bool isAdult(DateTime dateOfBirth, DateTime today) =>
    !dateOfBirth.isAfter(latestAllowedDateOfBirth(today));

abstract class ProfileRepository {
  /// The signed-in user's profile, or an empty one if the row is missing.
  Future<Profile> fetchMine();
  Future<void> saveMine(Profile profile);

  /// Name from the Google account, to pre-fill the form.
  String? get suggestedName;

  /// Remembers the app language on the profile, so plans are written in it.
  /// Best effort: never throws.
  Future<void> saveLocale(String code);
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  @override
  String? get suggestedName {
    final meta = _client.auth.currentUser?.userMetadata;
    return (meta?['full_name'] ?? meta?['name']) as String?;
  }

  @override
  Future<Profile> fetchMine() async {
    final row = await _client
        .from('profiles')
        .select('display_name, gender, date_of_birth, category, exam_id')
        .eq('id', _uid)
        .maybeSingle();
    return row == null ? const Profile() : Profile.fromJson(row);
  }

  @override
  Future<void> saveLocale(String code) async {
    try {
      if (_client.auth.currentUser == null) return;
      await _client.from('profiles').update({'locale': code}).eq('id', _uid);
    } on Object {
      // Not worth interrupting anything for.
    }
  }

  @override
  Future<void> saveMine(Profile profile) async {
    // Upsert: the sign-up trigger normally creates the row, but do not rely
    // on it having run.
    await _client.from('profiles').upsert({'id': _uid, ...profile.toJson()});
  }
}
