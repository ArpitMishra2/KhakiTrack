import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:path_provider/path_provider.dart';

import 'config.dart';
import 'data/cached_exam_repository.dart';
import 'data/app_settings.dart';
import 'data/auth_service.dart';
import 'data/exam_repository.dart';
import 'data/leaderboard_repository.dart';
import 'data/profile.dart';
import 'data/training_repository.dart';
import 'gps/location_source.dart';
import 'gps/run_repository.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    // ignore: deprecated_member_use  (legacy JWT anon key is what we have)
    anonKey: AppConfig.supabaseAnonKey,
  );
  final settings = await AppSettings.load(
    () async => File(
      '${(await getApplicationDocumentsDirectory()).path}/settings.json',
    ),
  );
  runApp(
    MaidanApp(
      settings: settings,
      repository: CachedExamRepository(
        SupabaseExamRepository(Supabase.instance.client),
        getApplicationDocumentsDirectory,
      ),
      auth: SupabaseAuthService(Supabase.instance.client),
      profiles: SupabaseProfileRepository(Supabase.instance.client),
      training: SupabaseTrainingRepository(Supabase.instance.client),
      runs: SupabaseRunRepository(Supabase.instance.client),
      boards: SupabaseLeaderboardRepository(Supabase.instance.client),
      location: (l10n) => GeolocatorSource(
        notificationTitle: l10n.trackingNotificationTitle,
        notificationText: l10n.trackingNotificationText,
      ),
    ),
  );
}

class MaidanApp extends StatefulWidget {
  const MaidanApp({
    super.key,
    this.settings,
    required this.repository,
    required this.auth,
    required this.profiles,
    required this.training,
    required this.runs,
    required this.location,
    required this.boards,
  });

  /// Language and low-data mode; defaults to Hindi, normal data.
  final AppSettings? settings;
  final ExamRepository repository;
  final AuthService auth;
  final ProfileRepository profiles;
  final TrainingRepository training;
  final RunRepository runs;
  final LeaderboardRepository boards;
  final LocationSource Function(AppLocalizations) location;

  @override
  State<MaidanApp> createState() => _MaidanAppState();
}

class _MaidanAppState extends State<MaidanApp> {
  late final AppSettings _settings = widget.settings ?? AppSettings();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => SettingsScope(
        settings: _settings,
        child: MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          theme: AppTheme.light(),
          // Hindi is the default; the user can switch to English in settings.
          locale: _settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: AuthGate(
            auth: widget.auth,
            repository: widget.repository,
            profiles: widget.profiles,
            training: widget.training,
            runs: widget.runs,
            location: widget.location,
            boards: widget.boards,
          ),
        ),
      ),
    );
  }
}
