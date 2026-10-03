import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/data/cached_profile_repository.dart';
import 'package:maidan/data/profile.dart';
import 'package:maidan/data/training_models.dart';
import 'package:maidan/l10n/app_localizations.dart';
import 'package:maidan/main.dart';
import 'package:maidan/screens/language_button.dart';
import 'package:maidan/screens/questionnaire_screen.dart';

import 'fake_auth_service.dart';
import 'fake_exam_repository.dart';
import 'fake_gps.dart';
import 'fake_leaderboard_repository.dart';
import 'fake_profile_repository.dart';
import 'fake_training_repository.dart';

final _complete = Profile(
  displayName: 'Ramesh Kumar',
  gender: 'male',
  dateOfBirth: DateTime(2000, 1, 1),
  category: 'general',
  examId: 'up_police_constable',
);

/// A server that can answer empty, fail, or answer properly.
class _Server implements ProfileRepository {
  Profile answer = const Profile();
  bool failing = false;
  int fetches = 0;
  final List<Profile> saved = [];

  @override
  String? get suggestedName => null;

  @override
  Future<Profile> fetchMine() async {
    fetches++;
    if (failing) throw Exception('offline');
    return answer;
  }

  @override
  Future<void> saveMine(Profile profile) async {
    if (failing) throw Exception('offline');
    saved.add(profile);
    answer = profile;
  }

  @override
  Future<void> saveLocale(String code) async {}
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('maidan_profile'));
  tearDown(() => dir.deleteSync(recursive: true));

  CachedProfileRepository repo(_Server s, {String? uid = 'user-1'}) =>
      CachedProfileRepository(
        s,
        () async => dir,
        () => uid,
        retryDelay: Duration.zero,
      );

  group('profile survives an empty or failed answer', () {
    test(
      'a complete profile is remembered and served when the server is empty',
      () async {
        final server = _Server()..answer = _complete;
        final r = repo(server);
        expect((await r.fetchMine()).isComplete, isTrue);

        // After sign-out and sign-in the server answers with nothing.
        server.answer = const Profile();
        final back = await r.fetchMine();
        expect(back.isComplete, isTrue);
        expect(back.examId, 'up_police_constable');
        // And the server copy is put back.
        expect(server.saved.last.examId, 'up_police_constable');
      },
    );

    test('works offline with a saved copy', () async {
      final server = _Server()..answer = _complete;
      final r = repo(server);
      await r.fetchMine();
      server.failing = true;
      expect((await r.fetchMine()).displayName, 'Ramesh Kumar');
    });

    test('an empty answer is asked for twice before it is believed', () async {
      final server = _Server();
      final p = await repo(server).fetchMine();
      expect(p.isComplete, isFalse);
      expect(server.fetches, 2);
    });

    test('offline with nothing saved still fails loudly', () async {
      final server = _Server()..failing = true;
      expect(repo(server).fetchMine(), throwsException);
    });

    test('each user has their own copy', () async {
      final server = _Server()..answer = _complete;
      await repo(server, uid: 'user-1').fetchMine();
      server.answer = const Profile();
      final other = await repo(server, uid: 'user-2').fetchMine();
      expect(other.isComplete, isFalse);
    });

    test('saving writes the copy too', () async {
      final server = _Server();
      final r = repo(server);
      await r.saveMine(_complete);
      server.answer = const Profile();
      expect((await r.fetchMine()).isComplete, isTrue);
    });
  });

  test('questionnaire answers survive a round trip', () {
    final a = TrainingAnswers()
      ..canCompleteDistance = true
      ..currentTimeSeconds = 1750
      ..runningExperience = '3to12m'
      ..runsPerWeek = 3
      ..weeklyKm = 12
      ..background = {'farm'}
      ..daysPerWeek = 5
      ..weeksToPet = 10
      ..pain = {'knee'}
      ..painNote = 'left'
      ..weightKg = 62;
    final b = TrainingAnswers.fromJson(a.toJson());
    expect(b.toJson(), a.toJson());
    expect(TrainingAnswers.fromJson(const {}).pain, {'none'});
  });

  Widget localized(Widget home) => MaterialApp(
    locale: const Locale('hi'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );

  testWidgets('the questionnaire comes back with the saved answers', (
    tester,
  ) async {
    final training = FakeTrainingRepository()
      ..draft = (TrainingAnswers()
        ..canCompleteDistance = true
        ..currentTimeSeconds = 1750);
    await tester.pumpWidget(
      localized(
        QuestionnaireScreen(
          runMetres: 4800,
          targetSeconds: 1500,
          training: training,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('29:10'), findsOneWidget);
    // The step is already valid: Next is enabled without retyping.
    final next = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'आगे'),
    );
    expect(next.onPressed, isNotNull);
  });

  testWidgets('answers are kept when going to the next step', (tester) async {
    final training = FakeTrainingRepository();
    await tester.pumpWidget(
      localized(
        QuestionnaireScreen(
          runMetres: 4800,
          targetSeconds: 1500,
          training: training,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('नहीं'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 किमी'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'आगे'));
    await tester.pumpAndSettle();
    expect(training.draft?.canCompleteDistance, isFalse);
    expect(training.draft?.longestContinuousKm, 2);
  });

  testWidgets('switching language also updates the profile language', (
    tester,
  ) async {
    final profiles = FakeProfileRepository();
    await tester.pumpWidget(
      MaidanApp(
        boards: FakeLeaderboardRepository(),
        runs: FakeRunRepository(),
        location: (_) => FakeLocationSource(),
        repository: FakeExamRepository(),
        auth: FakeAuthService(),
        profiles: profiles,
        training: FakeTrainingRepository(),
      ),
    );
    await tester.pumpAndSettle();
    // Signing in already told the server the current language.
    expect(profiles.lastLocale, 'hi');
    await tester.tap(find.byType(LanguageButton).first);
    await tester.pumpAndSettle();
    expect(profiles.lastLocale, 'en');
    expect(find.text('Training'), findsWidgets);
  });
}
