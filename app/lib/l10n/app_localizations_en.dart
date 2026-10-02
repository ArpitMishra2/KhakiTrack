// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Maidan';

  @override
  String get welcomeTitle => 'Prepare for government job physical tests';

  @override
  String get welcomeSubtitle => 'UP Police Constable and SSC GD';

  @override
  String get chooseExam => 'Choose your exam';

  @override
  String get examUpPolice => 'UP Police Constable';

  @override
  String get examSscGd => 'SSC GD';
}
