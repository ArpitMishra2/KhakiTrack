import 'package:maidan/data/profile.dart';

/// In-memory profile store. Starts complete (male, general, UP Police) unless
/// given another profile.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository([Profile? initial])
    : stored =
          initial ??
          Profile(
            displayName: 'Test User',
            gender: 'male',
            dateOfBirth: DateTime(2000, 1, 1),
            category: 'general',
            examId: 'up_police_constable',
          );

  Profile stored;
  bool failSave = false;
  int saves = 0;

  @override
  String? get suggestedName => 'Ramesh Kumar';

  @override
  Future<Profile> fetchMine() async => stored;

  @override
  Future<void> saveMine(Profile profile) async {
    if (failSave) throw Exception('offline');
    saves++;
    stored = profile;
  }
}
