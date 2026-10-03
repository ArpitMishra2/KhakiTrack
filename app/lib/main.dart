import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:path_provider/path_provider.dart';

import 'config.dart';
import 'data/cached_exam_repository.dart';
import 'data/cached_profile_repository.dart';
import 'data/app_settings.dart';
import 'data/auth_service.dart';
import 'data/exam_repository.dart';
import 'data/demo_leaderboard.dart';
import 'data/demo_repositories.dart';
import 'data/leaderboard_repository.dart';
import 'data/profile.dart';
import 'data/training_repository.dart';
import 'gps/location_source.dart';
import 'gps/run_repository.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth_gate.dart';
import 'weather/weather_service.dart';
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
  final runs = SupabaseRunRepository(Supabase.instance.client);
  runApp(
    MaidanApp(
      settings: settings,
      repository: CachedExamRepository(
        SupabaseExamRepository(Supabase.instance.client),
        getApplicationDocumentsDirectory,
      ),
      auth: SupabaseAuthService(
        Supabase.instance.client,
        onDeleted: (id) async {
          await runs.forgetUser(id);
          // Wipe this user's saved profile and plan draft from the phone.
          final dir = await getApplicationDocumentsDirectory();
          for (final name in ['profile_$id.json', 'plan_draft_$id.json']) {
            final f = File('${dir.path}/$name');
            if (await f.exists()) await f.delete();
          }
        },
      ),
      profiles: CachedProfileRepository(
        SupabaseProfileRepository(Supabase.instance.client),
        getApplicationDocumentsDirectory,
        () => Supabase.instance.client.auth.currentUser?.id,
      ),
      training: SupabaseTrainingRepository(
        Supabase.instance.client,
        getApplicationDocumentsDirectory,
      ),
      runs: runs,
      boards: SupabaseLeaderboardRepository(Supabase.instance.client),
      location: (l10n) => GeolocatorSource(
        notificationTitle: l10n.trackingNotificationTitle,
        notificationText: l10n.trackingNotificationText,
      ),
      weather: OpenMeteoWeatherService(
        const GeolocatorSource(notificationTitle: '', notificationText: ''),
      ),
    ),
  );
}

class MaidanApp extends StatefulWidget {
  const MaidanApp({
    super.key,
    this.settings,
    this.weather,
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

  /// Live weather for the weather cards; without it they show the clock-based
  /// hot-hours nudge.
  final WeatherService? weather;
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
  late final LeaderboardRepository _boards = SwitchableLeaderboards(
    real: widget.boards,
    demo: DemoLeaderboardRepository(
      myName: () async {
        try {
          return shortName((await widget.profiles.fetchMine()).displayName);
        } on Object {
          return 'You';
        }
      },
    ),
    isDemo: () => _settings.demoData,
  );

  late final TrainingRepository _training = SwitchableTraining(
    real: widget.training,
    demo: DemoTrainingRepository(language: () => _settings.locale.languageCode),
    isDemo: () => _settings.demoData,
  );

  late final RunRepository _runs = SwitchableRuns(
    real: widget.runs,
    demo: DemoRunRepository(),
    isDemo: () => _settings.demoData,
  );

  late final AppSettings _settings = (widget.settings ?? AppSettings())
    ..onLanguageChanged = (code) => widget.profiles.saveLocale(code);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => _withWeather(
        SettingsScope(
          settings: _settings,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
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
              training: _training,
              runs: _runs,
              location: widget.location,
              boards: _boards,
            ),
          ),
        ),
      ),
    );
  }

  Widget _withWeather(Widget child) {
    final w = widget.weather;
    return w == null ? child : WeatherScope(service: w, child: child);
  }
}
