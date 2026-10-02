import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'data/auth_service.dart';
import 'data/exam_repository.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    // ignore: deprecated_member_use  (legacy JWT anon key is what we have)
    anonKey: AppConfig.supabaseAnonKey,
  );
  runApp(
    MaidanApp(
      repository: SupabaseExamRepository(Supabase.instance.client),
      auth: SupabaseAuthService(Supabase.instance.client),
    ),
  );
}

class MaidanApp extends StatelessWidget {
  const MaidanApp({super.key, required this.repository, required this.auth});

  final ExamRepository repository;
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B7B4B)),
        useMaterial3: true,
      ),
      // Hindi is the default; English is the fallback second language.
      locale: const Locale('hi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AuthGate(auth: auth, repository: repository),
    );
  }
}
