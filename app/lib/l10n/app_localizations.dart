import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In hi, this message translates to:
  /// **'मैदान'**
  String get appName;

  /// No description provided for @welcomeTitle.
  ///
  /// In hi, this message translates to:
  /// **'सरकारी भर्ती की शारीरिक परीक्षा की तैयारी'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'यूपी पुलिस कांस्टेबल और SSC GD'**
  String get welcomeSubtitle;

  /// No description provided for @chooseExam.
  ///
  /// In hi, this message translates to:
  /// **'अपनी परीक्षा चुनें'**
  String get chooseExam;

  /// No description provided for @loadError.
  ///
  /// In hi, this message translates to:
  /// **'डेटा लोड नहीं हो सका। इंटरनेट कनेक्शन जांचें।'**
  String get loadError;

  /// No description provided for @retry.
  ///
  /// In hi, this message translates to:
  /// **'फिर कोशिश करें'**
  String get retry;

  /// No description provided for @gender.
  ///
  /// In hi, this message translates to:
  /// **'लिंग'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In hi, this message translates to:
  /// **'पुरुष'**
  String get male;

  /// No description provided for @female.
  ///
  /// In hi, this message translates to:
  /// **'महिला'**
  String get female;

  /// No description provided for @category.
  ///
  /// In hi, this message translates to:
  /// **'श्रेणी'**
  String get category;

  /// No description provided for @sectionPst.
  ///
  /// In hi, this message translates to:
  /// **'शारीरिक मानक परीक्षण (PST)'**
  String get sectionPst;

  /// No description provided for @sectionPet.
  ///
  /// In hi, this message translates to:
  /// **'शारीरिक दक्षता परीक्षा (PET)'**
  String get sectionPet;

  /// No description provided for @eventHeight.
  ///
  /// In hi, this message translates to:
  /// **'न्यूनतम लंबाई'**
  String get eventHeight;

  /// No description provided for @eventWeight.
  ///
  /// In hi, this message translates to:
  /// **'न्यूनतम वज़न'**
  String get eventWeight;

  /// No description provided for @eventChestUnexpanded.
  ///
  /// In hi, this message translates to:
  /// **'सीना (बिना फुलाए)'**
  String get eventChestUnexpanded;

  /// No description provided for @eventChestExpanded.
  ///
  /// In hi, this message translates to:
  /// **'सीना (फुलाकर)'**
  String get eventChestExpanded;

  /// No description provided for @eventChestExpansion.
  ///
  /// In hi, this message translates to:
  /// **'सीने का न्यूनतम फुलाव'**
  String get eventChestExpansion;

  /// No description provided for @eventRun.
  ///
  /// In hi, this message translates to:
  /// **'{distance} दौड़'**
  String eventRun(String distance);

  /// No description provided for @valueCm.
  ///
  /// In hi, this message translates to:
  /// **'{value} सेमी'**
  String valueCm(String value);

  /// No description provided for @valueKg.
  ///
  /// In hi, this message translates to:
  /// **'{value} किग्रा'**
  String valueKg(String value);

  /// No description provided for @distanceKm.
  ///
  /// In hi, this message translates to:
  /// **'{value} किमी'**
  String distanceKm(String value);

  /// No description provided for @distanceM.
  ///
  /// In hi, this message translates to:
  /// **'{value} मीटर'**
  String distanceM(String value);

  /// No description provided for @timeMinutes.
  ///
  /// In hi, this message translates to:
  /// **'{minutes} मिनट में'**
  String timeMinutes(int minutes);

  /// No description provided for @timeMinutesSeconds.
  ///
  /// In hi, this message translates to:
  /// **'{minutes} मिनट {seconds} सेकंड में'**
  String timeMinutesSeconds(int minutes, int seconds);

  /// No description provided for @notConfirmed.
  ///
  /// In hi, this message translates to:
  /// **'पुष्टि बाकी'**
  String get notConfirmed;

  /// No description provided for @noStandards.
  ///
  /// In hi, this message translates to:
  /// **'इस चयन के लिए कोई मानक नहीं मिला।'**
  String get noStandards;

  /// No description provided for @sourceNote.
  ///
  /// In hi, this message translates to:
  /// **'स्रोत: आधिकारिक भर्ती सूचना (डेटा संस्करण {version})'**
  String sourceNote(String version);

  /// No description provided for @catGeneral.
  ///
  /// In hi, this message translates to:
  /// **'सामान्य / OBC / SC / EWS'**
  String get catGeneral;

  /// No description provided for @catSt.
  ///
  /// In hi, this message translates to:
  /// **'अनुसूचित जनजाति (ST)'**
  String get catSt;

  /// No description provided for @catStNeStates.
  ///
  /// In hi, this message translates to:
  /// **'ST – पूर्वोत्तर राज्य'**
  String get catStNeStates;

  /// No description provided for @catStLweDistricts.
  ///
  /// In hi, this message translates to:
  /// **'ST – वामपंथी उग्रवाद प्रभावित ज़िले'**
  String get catStLweDistricts;

  /// No description provided for @catHillGroups.
  ///
  /// In hi, this message translates to:
  /// **'गढ़वाली, कुमाऊँनी, डोगरा, मराठा, असम, हिमाचल, जम्मू-कश्मीर'**
  String get catHillGroups;

  /// No description provided for @catLadakh.
  ///
  /// In hi, this message translates to:
  /// **'लद्दाख क्षेत्र'**
  String get catLadakh;

  /// No description provided for @catNeStates.
  ///
  /// In hi, this message translates to:
  /// **'पूर्वोत्तर राज्य (अरुणाचल, मणिपुर, मेघालय, मिज़ोरम, नागालैंड, सिक्किम, त्रिपुरा)'**
  String get catNeStates;

  /// No description provided for @catGta.
  ///
  /// In hi, this message translates to:
  /// **'गोरखा क्षेत्रीय प्रशासन (दार्जिलिंग)'**
  String get catGta;

  /// No description provided for @signInWithGoogle.
  ///
  /// In hi, this message translates to:
  /// **'Google से जारी रखें'**
  String get signInWithGoogle;

  /// No description provided for @signInFailed.
  ///
  /// In hi, this message translates to:
  /// **'साइन इन नहीं हो सका। इंटरनेट जांचकर फिर कोशिश करें।'**
  String get signInFailed;

  /// No description provided for @adultsOnly.
  ///
  /// In hi, this message translates to:
  /// **'यह ऐप केवल 18 वर्ष या उससे अधिक उम्र के लोगों के लिए है।'**
  String get adultsOnly;

  /// No description provided for @signOut.
  ///
  /// In hi, this message translates to:
  /// **'साइन आउट'**
  String get signOut;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
