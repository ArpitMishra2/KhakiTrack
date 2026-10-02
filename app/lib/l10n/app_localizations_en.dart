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
  String get loadError =>
      'Could not load data. Check your internet connection.';

  @override
  String get retry => 'Try again';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get category => 'Category';

  @override
  String get sectionPst => 'Physical Standard Test (PST)';

  @override
  String get sectionPet => 'Physical Efficiency Test (PET)';

  @override
  String get eventHeight => 'Minimum height';

  @override
  String get eventWeight => 'Minimum weight';

  @override
  String get eventChestUnexpanded => 'Chest (unexpanded)';

  @override
  String get eventChestExpanded => 'Chest (expanded)';

  @override
  String get eventChestExpansion => 'Minimum chest expansion';

  @override
  String eventRun(String distance) {
    return '$distance run';
  }

  @override
  String valueCm(String value) {
    return '$value cm';
  }

  @override
  String valueKg(String value) {
    return '$value kg';
  }

  @override
  String distanceKm(String value) {
    return '$value km';
  }

  @override
  String distanceM(String value) {
    return '$value m';
  }

  @override
  String timeMinutes(int minutes) {
    return 'within $minutes min';
  }

  @override
  String timeMinutesSeconds(int minutes, int seconds) {
    return 'within $minutes min $seconds s';
  }

  @override
  String get notConfirmed => 'Not yet confirmed';

  @override
  String get noStandards => 'No standards found for this selection.';

  @override
  String sourceNote(String version) {
    return 'Source: official recruitment notice (data version $version)';
  }

  @override
  String get catGeneral => 'General / OBC / SC / EWS';

  @override
  String get catSt => 'Scheduled Tribe (ST)';

  @override
  String get catStNeStates => 'ST – North Eastern states';

  @override
  String get catStLweDistricts => 'ST – Left-Wing Extremism affected districts';

  @override
  String get catHillGroups =>
      'Garhwali, Kumaoni, Dogra, Maratha, Assam, Himachal, J&K';

  @override
  String get catLadakh => 'Ladakh region';

  @override
  String get catNeStates =>
      'North Eastern states (Arunachal, Manipur, Meghalaya, Mizoram, Nagaland, Sikkim, Tripura)';

  @override
  String get catGta => 'Gorkha Territorial Administration (Darjeeling)';
}
