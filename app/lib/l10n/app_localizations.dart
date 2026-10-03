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

  /// No description provided for @profileTitle.
  ///
  /// In hi, this message translates to:
  /// **'आपकी जानकारी'**
  String get profileTitle;

  /// No description provided for @profileIntro.
  ///
  /// In hi, this message translates to:
  /// **'सही शारीरिक मानक दिखाने के लिए यह जानकारी चाहिए।'**
  String get profileIntro;

  /// No description provided for @name.
  ///
  /// In hi, this message translates to:
  /// **'नाम'**
  String get name;

  /// No description provided for @dateOfBirth.
  ///
  /// In hi, this message translates to:
  /// **'जन्म तिथि'**
  String get dateOfBirth;

  /// No description provided for @chooseDate.
  ///
  /// In hi, this message translates to:
  /// **'तारीख चुनें'**
  String get chooseDate;

  /// No description provided for @chooseCategory.
  ///
  /// In hi, this message translates to:
  /// **'श्रेणी चुनें'**
  String get chooseCategory;

  /// No description provided for @save.
  ///
  /// In hi, this message translates to:
  /// **'सेव करें'**
  String get save;

  /// No description provided for @saveFailed.
  ///
  /// In hi, this message translates to:
  /// **'सेव नहीं हो सका। इंटरनेट जांचकर फिर कोशिश करें।'**
  String get saveFailed;

  /// No description provided for @socialGeneral.
  ///
  /// In hi, this message translates to:
  /// **'सामान्य'**
  String get socialGeneral;

  /// No description provided for @socialObc.
  ///
  /// In hi, this message translates to:
  /// **'अन्य पिछड़ा वर्ग (OBC)'**
  String get socialObc;

  /// No description provided for @socialSc.
  ///
  /// In hi, this message translates to:
  /// **'अनुसूचित जाति (SC)'**
  String get socialSc;

  /// No description provided for @socialSt.
  ///
  /// In hi, this message translates to:
  /// **'अनुसूचित जनजाति (ST)'**
  String get socialSt;

  /// No description provided for @socialEws.
  ///
  /// In hi, this message translates to:
  /// **'आर्थिक रूप से कमज़ोर वर्ग (EWS)'**
  String get socialEws;

  /// No description provided for @tabTraining.
  ///
  /// In hi, this message translates to:
  /// **'ट्रेनिंग'**
  String get tabTraining;

  /// No description provided for @tabStandards.
  ///
  /// In hi, this message translates to:
  /// **'मानक'**
  String get tabStandards;

  /// No description provided for @tabProgress.
  ///
  /// In hi, this message translates to:
  /// **'प्रगति'**
  String get tabProgress;

  /// No description provided for @trainingIntroTitle.
  ///
  /// In hi, this message translates to:
  /// **'आपका अपना रनिंग प्लान'**
  String get trainingIntroTitle;

  /// No description provided for @trainingIntroBody.
  ///
  /// In hi, this message translates to:
  /// **'कुछ सवालों के जवाब दें। AI आपके अभी के स्तर, समय और अनुभव के हिसाब से हफ्ते-दर-हफ्ते प्लान बनाएगा, ताकि PET के दिन तक आप दौड़ आराम से समय में पूरी कर सकें।'**
  String get trainingIntroBody;

  /// No description provided for @startQuestionnaire.
  ///
  /// In hi, this message translates to:
  /// **'प्लान बनाना शुरू करें'**
  String get startQuestionnaire;

  /// No description provided for @qTitle.
  ///
  /// In hi, this message translates to:
  /// **'आपके बारे में'**
  String get qTitle;

  /// No description provided for @qStep.
  ///
  /// In hi, this message translates to:
  /// **'चरण {step} / {total}'**
  String qStep(int step, int total);

  /// No description provided for @qNext.
  ///
  /// In hi, this message translates to:
  /// **'आगे'**
  String get qNext;

  /// No description provided for @qBack.
  ///
  /// In hi, this message translates to:
  /// **'पीछे'**
  String get qBack;

  /// No description provided for @qCreate.
  ///
  /// In hi, this message translates to:
  /// **'मेरा प्लान बनाएं'**
  String get qCreate;

  /// No description provided for @qLevelTitle.
  ///
  /// In hi, this message translates to:
  /// **'अभी आपका स्तर'**
  String get qLevelTitle;

  /// No description provided for @qCanComplete.
  ///
  /// In hi, this message translates to:
  /// **'क्या आप अभी {distance} बिना रुके दौड़ सकते हैं?'**
  String qCanComplete(String distance);

  /// No description provided for @yes.
  ///
  /// In hi, this message translates to:
  /// **'हाँ'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In hi, this message translates to:
  /// **'नहीं'**
  String get no;

  /// No description provided for @qCurrentTime.
  ///
  /// In hi, this message translates to:
  /// **'{distance} में कितना समय लगता है? (मिनट:सेकंड)'**
  String qCurrentTime(String distance);

  /// No description provided for @qTimeHint.
  ///
  /// In hi, this message translates to:
  /// **'जैसे 27:30'**
  String get qTimeHint;

  /// No description provided for @qTimeInvalid.
  ///
  /// In hi, this message translates to:
  /// **'समय मिनट:सेकंड में लिखें, जैसे 27:30'**
  String get qTimeInvalid;

  /// No description provided for @qLongest.
  ///
  /// In hi, this message translates to:
  /// **'बिना रुके सबसे ज़्यादा कितना दौड़ लेते हैं?'**
  String get qLongest;

  /// No description provided for @qTarget.
  ///
  /// In hi, this message translates to:
  /// **'लक्ष्य: {distance} {time} में'**
  String qTarget(String distance, String time);

  /// No description provided for @qExperienceTitle.
  ///
  /// In hi, this message translates to:
  /// **'अनुभव'**
  String get qExperienceTitle;

  /// No description provided for @qExperience.
  ///
  /// In hi, this message translates to:
  /// **'आप कब से नियमित दौड़ रहे हैं?'**
  String get qExperience;

  /// No description provided for @expNone.
  ///
  /// In hi, this message translates to:
  /// **'अभी शुरू नहीं किया'**
  String get expNone;

  /// No description provided for @expLt3m.
  ///
  /// In hi, this message translates to:
  /// **'3 महीने से कम'**
  String get expLt3m;

  /// No description provided for @exp3to12m.
  ///
  /// In hi, this message translates to:
  /// **'3 से 12 महीने'**
  String get exp3to12m;

  /// No description provided for @expGt1y.
  ///
  /// In hi, this message translates to:
  /// **'1 साल से ज़्यादा'**
  String get expGt1y;

  /// No description provided for @qRunsPerWeek.
  ///
  /// In hi, this message translates to:
  /// **'अभी हफ्ते में कितनी बार दौड़ते हैं?'**
  String get qRunsPerWeek;

  /// No description provided for @qWeeklyKm.
  ///
  /// In hi, this message translates to:
  /// **'हफ्ते में कुल लगभग कितने किमी?'**
  String get qWeeklyKm;

  /// No description provided for @qBackground.
  ///
  /// In hi, this message translates to:
  /// **'और कौन-सा शारीरिक काम करते हैं?'**
  String get qBackground;

  /// No description provided for @bgFarm.
  ///
  /// In hi, this message translates to:
  /// **'खेती / मेहनत का काम'**
  String get bgFarm;

  /// No description provided for @bgSports.
  ///
  /// In hi, this message translates to:
  /// **'खेल (क्रिकेट, फुटबॉल, कबड्डी)'**
  String get bgSports;

  /// No description provided for @bgGym.
  ///
  /// In hi, this message translates to:
  /// **'जिम / कसरत'**
  String get bgGym;

  /// No description provided for @qScheduleTitle.
  ///
  /// In hi, this message translates to:
  /// **'समय और दिन'**
  String get qScheduleTitle;

  /// No description provided for @qWeeks.
  ///
  /// In hi, this message translates to:
  /// **'PET में लगभग कितने हफ्ते बचे हैं?'**
  String get qWeeks;

  /// No description provided for @qWeeksUnknown.
  ///
  /// In hi, this message translates to:
  /// **'तारीख पता नहीं हो तो 12 हफ्ते चुनें।'**
  String get qWeeksUnknown;

  /// No description provided for @weeksN.
  ///
  /// In hi, this message translates to:
  /// **'{n} हफ्ते'**
  String weeksN(int n);

  /// No description provided for @qDays.
  ///
  /// In hi, this message translates to:
  /// **'हफ्ते में कितने दिन ट्रेनिंग कर सकते हैं?'**
  String get qDays;

  /// No description provided for @daysN.
  ///
  /// In hi, this message translates to:
  /// **'{n} दिन'**
  String daysN(int n);

  /// No description provided for @qMinutes.
  ///
  /// In hi, this message translates to:
  /// **'एक बार में कितना समय दे सकते हैं?'**
  String get qMinutes;

  /// No description provided for @minutesN.
  ///
  /// In hi, this message translates to:
  /// **'{n} मिनट'**
  String minutesN(int n);

  /// No description provided for @qTrainingTime.
  ///
  /// In hi, this message translates to:
  /// **'कब दौड़ना पसंद है?'**
  String get qTrainingTime;

  /// No description provided for @timeMorning.
  ///
  /// In hi, this message translates to:
  /// **'सुबह'**
  String get timeMorning;

  /// No description provided for @timeEvening.
  ///
  /// In hi, this message translates to:
  /// **'शाम'**
  String get timeEvening;

  /// No description provided for @timeEither.
  ///
  /// In hi, this message translates to:
  /// **'कभी भी'**
  String get timeEither;

  /// No description provided for @qSurface.
  ///
  /// In hi, this message translates to:
  /// **'कहाँ दौड़ते हैं?'**
  String get qSurface;

  /// No description provided for @surfaceGround.
  ///
  /// In hi, this message translates to:
  /// **'मैदान'**
  String get surfaceGround;

  /// No description provided for @surfaceRoad.
  ///
  /// In hi, this message translates to:
  /// **'सड़क'**
  String get surfaceRoad;

  /// No description provided for @surfaceTrack.
  ///
  /// In hi, this message translates to:
  /// **'ट्रैक'**
  String get surfaceTrack;

  /// No description provided for @surfaceMixed.
  ///
  /// In hi, this message translates to:
  /// **'मिला-जुला'**
  String get surfaceMixed;

  /// No description provided for @qHealthTitle.
  ///
  /// In hi, this message translates to:
  /// **'सेहत'**
  String get qHealthTitle;

  /// No description provided for @qPain.
  ///
  /// In hi, this message translates to:
  /// **'क्या अभी कहीं दर्द या चोट है?'**
  String get qPain;

  /// No description provided for @painNone.
  ///
  /// In hi, this message translates to:
  /// **'कोई दर्द नहीं'**
  String get painNone;

  /// No description provided for @painKnee.
  ///
  /// In hi, this message translates to:
  /// **'घुटना'**
  String get painKnee;

  /// No description provided for @painShin.
  ///
  /// In hi, this message translates to:
  /// **'पिंडली'**
  String get painShin;

  /// No description provided for @painAnkle.
  ///
  /// In hi, this message translates to:
  /// **'टखना'**
  String get painAnkle;

  /// No description provided for @painBack.
  ///
  /// In hi, this message translates to:
  /// **'कमर / पीठ'**
  String get painBack;

  /// No description provided for @painOther.
  ///
  /// In hi, this message translates to:
  /// **'कुछ और'**
  String get painOther;

  /// No description provided for @qPainNote.
  ///
  /// In hi, this message translates to:
  /// **'दर्द के बारे में थोड़ा बताएं (वैकल्पिक)'**
  String get qPainNote;

  /// No description provided for @qMedical.
  ///
  /// In hi, this message translates to:
  /// **'कोई बीमारी?'**
  String get qMedical;

  /// No description provided for @medNone.
  ///
  /// In hi, this message translates to:
  /// **'कोई नहीं'**
  String get medNone;

  /// No description provided for @medAsthma.
  ///
  /// In hi, this message translates to:
  /// **'दमा / सांस'**
  String get medAsthma;

  /// No description provided for @medHeart.
  ///
  /// In hi, this message translates to:
  /// **'दिल की बीमारी'**
  String get medHeart;

  /// No description provided for @medBp.
  ///
  /// In hi, this message translates to:
  /// **'बीपी'**
  String get medBp;

  /// No description provided for @medDiabetes.
  ///
  /// In hi, this message translates to:
  /// **'शुगर'**
  String get medDiabetes;

  /// No description provided for @medOther.
  ///
  /// In hi, this message translates to:
  /// **'कुछ और'**
  String get medOther;

  /// No description provided for @qWeight.
  ///
  /// In hi, this message translates to:
  /// **'वज़न किग्रा (वैकल्पिक)'**
  String get qWeight;

  /// No description provided for @qHeight.
  ///
  /// In hi, this message translates to:
  /// **'लंबाई सेमी (वैकल्पिक)'**
  String get qHeight;

  /// No description provided for @generatingTitle.
  ///
  /// In hi, this message translates to:
  /// **'AI आपका प्लान बना रहा है'**
  String get generatingTitle;

  /// No description provided for @generatingBody.
  ///
  /// In hi, this message translates to:
  /// **'इसमें 1-2 मिनट लग सकते हैं। ऐप बंद न करें।'**
  String get generatingBody;

  /// No description provided for @errRateLimited.
  ///
  /// In hi, this message translates to:
  /// **'आज के लिए प्लान बनाने की सीमा पूरी हो गई। कल फिर कोशिश करें।'**
  String get errRateLimited;

  /// No description provided for @errAiNotConfigured.
  ///
  /// In hi, this message translates to:
  /// **'AI प्लान अभी चालू नहीं है। थोड़ी देर बाद कोशिश करें।'**
  String get errAiNotConfigured;

  /// No description provided for @errGeneration.
  ///
  /// In hi, this message translates to:
  /// **'प्लान नहीं बन पाया। फिर कोशिश करें।'**
  String get errGeneration;

  /// No description provided for @errTooEarly.
  ///
  /// In hi, this message translates to:
  /// **'अगला हफ्ता {date} से खुलेगा।'**
  String errTooEarly(String date);

  /// No description provided for @errNetwork.
  ///
  /// In hi, this message translates to:
  /// **'इंटरनेट से जुड़ नहीं पाए। कनेक्शन जांचकर फिर कोशिश करें।'**
  String get errNetwork;

  /// No description provided for @readinessOnTrack.
  ///
  /// In hi, this message translates to:
  /// **'सही रास्ते पर'**
  String get readinessOnTrack;

  /// No description provided for @readinessNeedsWork.
  ///
  /// In hi, this message translates to:
  /// **'मेहनत की ज़रूरत'**
  String get readinessNeedsWork;

  /// No description provided for @readinessBigGap.
  ///
  /// In hi, this message translates to:
  /// **'लंबा सफ़र'**
  String get readinessBigGap;

  /// No description provided for @seeDoctor.
  ///
  /// In hi, this message translates to:
  /// **'शुरू करने से पहले डॉक्टर से सलाह ज़रूर लें।'**
  String get seeDoctor;

  /// No description provided for @weekOf.
  ///
  /// In hi, this message translates to:
  /// **'हफ्ता {week} / {total}'**
  String weekOf(int week, int total);

  /// No description provided for @recoveryWeek.
  ///
  /// In hi, this message translates to:
  /// **'आराम वाला हफ्ता'**
  String get recoveryWeek;

  /// No description provided for @weekDone.
  ///
  /// In hi, this message translates to:
  /// **'{done} / {total} सेशन पूरे'**
  String weekDone(int done, int total);

  /// No description provided for @generateNextWeek.
  ///
  /// In hi, this message translates to:
  /// **'हफ्ता {week} का प्लान बनाएं'**
  String generateNextWeek(int week);

  /// No description provided for @nextWeekLocked.
  ///
  /// In hi, this message translates to:
  /// **'हफ्ता {week} का प्लान {date} को खुलेगा, ताकि वह आपकी इस हफ्ते की ट्रेनिंग के हिसाब से बने।'**
  String nextWeekLocked(int week, String date);

  /// No description provided for @planFinished.
  ///
  /// In hi, this message translates to:
  /// **'प्लान पूरा हुआ। PET के लिए शुभकामनाएं!'**
  String get planFinished;

  /// No description provided for @fullPlan.
  ///
  /// In hi, this message translates to:
  /// **'पूरा प्लान'**
  String get fullPlan;

  /// No description provided for @safetyNotes.
  ///
  /// In hi, this message translates to:
  /// **'ध्यान रखें'**
  String get safetyNotes;

  /// No description provided for @newPlan.
  ///
  /// In hi, this message translates to:
  /// **'नया प्लान बनाएं'**
  String get newPlan;

  /// No description provided for @newPlanConfirm.
  ///
  /// In hi, this message translates to:
  /// **'नया प्लान बनाने पर अभी वाला प्लान बंद हो जाएगा। आगे बढ़ें?'**
  String get newPlanConfirm;

  /// No description provided for @cancel.
  ///
  /// In hi, this message translates to:
  /// **'रद्द करें'**
  String get cancel;

  /// No description provided for @continueLabel.
  ///
  /// In hi, this message translates to:
  /// **'आगे बढ़ें'**
  String get continueLabel;

  /// No description provided for @sessionToday.
  ///
  /// In hi, this message translates to:
  /// **'आज'**
  String get sessionToday;

  /// No description provided for @statusDone.
  ///
  /// In hi, this message translates to:
  /// **'पूरा'**
  String get statusDone;

  /// No description provided for @statusPartial.
  ///
  /// In hi, this message translates to:
  /// **'आधा'**
  String get statusPartial;

  /// No description provided for @statusMissed.
  ///
  /// In hi, this message translates to:
  /// **'छूट गया'**
  String get statusMissed;

  /// No description provided for @logSession.
  ///
  /// In hi, this message translates to:
  /// **'सेशन दर्ज करें'**
  String get logSession;

  /// No description provided for @logDistance.
  ///
  /// In hi, this message translates to:
  /// **'कितना दौड़े (किमी)'**
  String get logDistance;

  /// No description provided for @logTime.
  ///
  /// In hi, this message translates to:
  /// **'कुल समय (मिनट:सेकंड)'**
  String get logTime;

  /// No description provided for @logEffort.
  ///
  /// In hi, this message translates to:
  /// **'कितना मुश्किल लगा? (1 आसान – 5 बहुत मुश्किल)'**
  String get logEffort;

  /// No description provided for @logPain.
  ///
  /// In hi, this message translates to:
  /// **'दौड़ते समय या बाद में दर्द हुआ'**
  String get logPain;

  /// No description provided for @logNote.
  ///
  /// In hi, this message translates to:
  /// **'नोट (वैकल्पिक)'**
  String get logNote;

  /// No description provided for @painWarning.
  ///
  /// In hi, this message translates to:
  /// **'दर्द हो तो अगले सेशन धीरे करें। दर्द बढ़े या 2-3 दिन में ठीक न हो तो डॉक्टर को दिखाएं।'**
  String get painWarning;

  /// No description provided for @km.
  ///
  /// In hi, this message translates to:
  /// **'{value} किमी'**
  String km(String value);

  /// No description provided for @minutesShort.
  ///
  /// In hi, this message translates to:
  /// **'{value} मिनट'**
  String minutesShort(String value);

  /// No description provided for @pacePerKm.
  ///
  /// In hi, this message translates to:
  /// **'{pace} प्रति किमी'**
  String pacePerKm(String pace);

  /// No description provided for @typeEasyRun.
  ///
  /// In hi, this message translates to:
  /// **'आसान दौड़'**
  String get typeEasyRun;

  /// No description provided for @typeRunWalk.
  ///
  /// In hi, this message translates to:
  /// **'दौड़-चाल'**
  String get typeRunWalk;

  /// No description provided for @typeLongRun.
  ///
  /// In hi, this message translates to:
  /// **'लंबी दौड़'**
  String get typeLongRun;

  /// No description provided for @typeTempo.
  ///
  /// In hi, this message translates to:
  /// **'टेम्पो रन'**
  String get typeTempo;

  /// No description provided for @typeIntervals.
  ///
  /// In hi, this message translates to:
  /// **'इंटरवल'**
  String get typeIntervals;

  /// No description provided for @typeTimeTrial.
  ///
  /// In hi, this message translates to:
  /// **'टाइम ट्रायल'**
  String get typeTimeTrial;

  /// No description provided for @typeStrength.
  ///
  /// In hi, this message translates to:
  /// **'ताकत की कसरत'**
  String get typeStrength;

  /// No description provided for @typeMobility.
  ///
  /// In hi, this message translates to:
  /// **'स्ट्रेचिंग'**
  String get typeMobility;

  /// No description provided for @progressTitle.
  ///
  /// In hi, this message translates to:
  /// **'{distance} का समय'**
  String progressTitle(String distance);

  /// No description provided for @progressEmpty.
  ///
  /// In hi, this message translates to:
  /// **'अभी कोई टाइम ट्रायल नहीं। अपना समय दर्ज करें और यहाँ अपनी प्रगति देखें।'**
  String get progressEmpty;

  /// No description provided for @addTrial.
  ///
  /// In hi, this message translates to:
  /// **'टाइम ट्रायल जोड़ें'**
  String get addTrial;

  /// No description provided for @trialDistance.
  ///
  /// In hi, this message translates to:
  /// **'दूरी (मीटर)'**
  String get trialDistance;

  /// No description provided for @trialTime.
  ///
  /// In hi, this message translates to:
  /// **'समय (मिनट:सेकंड)'**
  String get trialTime;

  /// No description provided for @trialDate.
  ///
  /// In hi, this message translates to:
  /// **'तारीख'**
  String get trialDate;

  /// No description provided for @latestTime.
  ///
  /// In hi, this message translates to:
  /// **'ताज़ा समय: {time}'**
  String latestTime(String time);

  /// No description provided for @targetTime.
  ///
  /// In hi, this message translates to:
  /// **'लक्ष्य: {time}'**
  String targetTime(String time);

  /// No description provided for @gapToCut.
  ///
  /// In hi, this message translates to:
  /// **'अभी {time} और कम करना है'**
  String gapToCut(String time);

  /// No description provided for @underTarget.
  ///
  /// In hi, this message translates to:
  /// **'आप लक्ष्य से {time} तेज़ हैं। इसे बनाए रखें!'**
  String underTarget(String time);

  /// No description provided for @estimated.
  ///
  /// In hi, this message translates to:
  /// **'अनुमानित'**
  String get estimated;

  /// No description provided for @estimateNote.
  ///
  /// In hi, this message translates to:
  /// **'दूसरी दूरी के ट्रायल से {distance} का समय अनुमान से निकाला गया है।'**
  String estimateNote(String distance);

  /// No description provided for @trialSaveFailed.
  ///
  /// In hi, this message translates to:
  /// **'सेव नहीं हो सका। फिर कोशिश करें।'**
  String get trialSaveFailed;

  /// No description provided for @runTitle.
  ///
  /// In hi, this message translates to:
  /// **'दौड़'**
  String get runTitle;

  /// No description provided for @mockPetTitle.
  ///
  /// In hi, this message translates to:
  /// **'मॉक PET'**
  String get mockPetTitle;

  /// No description provided for @freeRunTitle.
  ///
  /// In hi, this message translates to:
  /// **'खुली दौड़'**
  String get freeRunTitle;

  /// No description provided for @mockPetIntro.
  ///
  /// In hi, this message translates to:
  /// **'असली PET की तरह {distance} दौड़ें। ऐप GPS से समय नापेगा और बताएगा कि आप {time} के लक्ष्य में क्वालीफाई करते या नहीं।'**
  String mockPetIntro(String distance, String time);

  /// No description provided for @freeRunIntro.
  ///
  /// In hi, this message translates to:
  /// **'अपनी किसी भी दौड़ को GPS से रिकॉर्ड करें।'**
  String get freeRunIntro;

  /// No description provided for @runTips.
  ///
  /// In hi, this message translates to:
  /// **'खुले मैदान में दौड़ें, फोन जेब या हाथ में रखें। Xiaomi/Redmi फोन में ऐप की बैटरी सेटिंग \'No restrictions\' रखें ताकि स्क्रीन बंद होने पर भी GPS चलता रहे।'**
  String get runTips;

  /// No description provided for @gpsSearching.
  ///
  /// In hi, this message translates to:
  /// **'GPS सिग्नल ढूंढ रहे हैं…'**
  String get gpsSearching;

  /// No description provided for @gpsAccuracy.
  ///
  /// In hi, this message translates to:
  /// **'GPS सटीकता: {metres} मीटर'**
  String gpsAccuracy(int metres);

  /// No description provided for @gpsReady.
  ///
  /// In hi, this message translates to:
  /// **'GPS तैयार है'**
  String get gpsReady;

  /// No description provided for @gpsDenied.
  ///
  /// In hi, this message translates to:
  /// **'दौड़ रिकॉर्ड करने के लिए लोकेशन की अनुमति चाहिए।'**
  String get gpsDenied;

  /// No description provided for @gpsOff.
  ///
  /// In hi, this message translates to:
  /// **'फोन की लोकेशन (GPS) चालू करें।'**
  String get gpsOff;

  /// No description provided for @openSettings.
  ///
  /// In hi, this message translates to:
  /// **'सेटिंग खोलें'**
  String get openSettings;

  /// No description provided for @startRun.
  ///
  /// In hi, this message translates to:
  /// **'शुरू करें'**
  String get startRun;

  /// No description provided for @startAnyway.
  ///
  /// In hi, this message translates to:
  /// **'फिर भी शुरू करें'**
  String get startAnyway;

  /// No description provided for @holdToStop.
  ///
  /// In hi, this message translates to:
  /// **'रोकने के लिए दबाकर रखें'**
  String get holdToStop;

  /// No description provided for @elapsed.
  ///
  /// In hi, this message translates to:
  /// **'समय'**
  String get elapsed;

  /// No description provided for @distanceLabel.
  ///
  /// In hi, this message translates to:
  /// **'दूरी'**
  String get distanceLabel;

  /// No description provided for @paceLabel.
  ///
  /// In hi, this message translates to:
  /// **'गति'**
  String get paceLabel;

  /// No description provided for @aheadBy.
  ///
  /// In hi, this message translates to:
  /// **'लक्ष्य से {time} आगे'**
  String aheadBy(String time);

  /// No description provided for @behindBy.
  ///
  /// In hi, this message translates to:
  /// **'लक्ष्य से {time} पीछे'**
  String behindBy(String time);

  /// No description provided for @remaining.
  ///
  /// In hi, this message translates to:
  /// **'{distance} बाकी'**
  String remaining(String distance);

  /// No description provided for @trackingNotificationTitle.
  ///
  /// In hi, this message translates to:
  /// **'मैदान: दौड़ रिकॉर्ड हो रही है'**
  String get trackingNotificationTitle;

  /// No description provided for @trackingNotificationText.
  ///
  /// In hi, this message translates to:
  /// **'GPS से दूरी और समय नापा जा रहा है'**
  String get trackingNotificationText;

  /// No description provided for @resultTitle.
  ///
  /// In hi, this message translates to:
  /// **'नतीजा'**
  String get resultTitle;

  /// No description provided for @outcomeQualified.
  ///
  /// In hi, this message translates to:
  /// **'आप क्वालीफाई करते!'**
  String get outcomeQualified;

  /// No description provided for @outcomeBorderline.
  ///
  /// In hi, this message translates to:
  /// **'सीमा पर – थोड़ा और तेज़ दौड़ें'**
  String get outcomeBorderline;

  /// No description provided for @outcomeNotQualified.
  ///
  /// In hi, this message translates to:
  /// **'अभी क्वालीफाई नहीं'**
  String get outcomeNotQualified;

  /// No description provided for @outcomeIncomplete.
  ///
  /// In hi, this message translates to:
  /// **'दूरी पूरी नहीं हुई'**
  String get outcomeIncomplete;

  /// No description provided for @borderlineNote.
  ///
  /// In hi, this message translates to:
  /// **'GPS में 2-3% तक का फर्क हो सकता है। पक्का क्वालीफाई के लिए लक्ष्य से कम से कम 3% तेज़ दौड़ें।'**
  String get borderlineNote;

  /// No description provided for @finishTime.
  ///
  /// In hi, this message translates to:
  /// **'{distance} का समय: {time}'**
  String finishTime(String distance, String time);

  /// No description provided for @targetLine.
  ///
  /// In hi, this message translates to:
  /// **'लक्ष्य: {time}'**
  String targetLine(String time);

  /// No description provided for @marginAhead.
  ///
  /// In hi, this message translates to:
  /// **'लक्ष्य से {time} कम'**
  String marginAhead(String time);

  /// No description provided for @marginBehind.
  ///
  /// In hi, this message translates to:
  /// **'लक्ष्य से {time} ज़्यादा'**
  String marginBehind(String time);

  /// No description provided for @totalDistance.
  ///
  /// In hi, this message translates to:
  /// **'कुल दूरी: {distance}'**
  String totalDistance(String distance);

  /// No description provided for @totalTime.
  ///
  /// In hi, this message translates to:
  /// **'कुल समय: {time}'**
  String totalTime(String time);

  /// No description provided for @verdictVerified.
  ///
  /// In hi, this message translates to:
  /// **'GPS जांच: सही'**
  String get verdictVerified;

  /// No description provided for @verdictSuspicious.
  ///
  /// In hi, this message translates to:
  /// **'GPS जांच: पक्का नहीं'**
  String get verdictSuspicious;

  /// No description provided for @verdictRejected.
  ///
  /// In hi, this message translates to:
  /// **'GPS जांच: अमान्य'**
  String get verdictRejected;

  /// No description provided for @verdictNotCounted.
  ///
  /// In hi, this message translates to:
  /// **'यह दौड़ प्रगति और रैंकिंग में नहीं गिनी जाएगी।'**
  String get verdictNotCounted;

  /// No description provided for @flagMock.
  ///
  /// In hi, this message translates to:
  /// **'नकली लोकेशन (mock location) मिली।'**
  String get flagMock;

  /// No description provided for @flagTeleport.
  ///
  /// In hi, this message translates to:
  /// **'लोकेशन अचानक बहुत दूर कूद गई।'**
  String get flagTeleport;

  /// No description provided for @flagImpossibleSpeed.
  ///
  /// In hi, this message translates to:
  /// **'कुछ हिस्से में गति इंसान के लिए असंभव थी।'**
  String get flagImpossibleSpeed;

  /// No description provided for @flagVehicle.
  ///
  /// In hi, this message translates to:
  /// **'कुछ हिस्सा गाड़ी/साइकिल जैसी गति से था।'**
  String get flagVehicle;

  /// No description provided for @flagAverage.
  ///
  /// In hi, this message translates to:
  /// **'पूरी दौड़ की औसत गति असंभव थी।'**
  String get flagAverage;

  /// No description provided for @flagPoorSignal.
  ///
  /// In hi, this message translates to:
  /// **'GPS सिग्नल कमज़ोर था।'**
  String get flagPoorSignal;

  /// No description provided for @flagGap.
  ///
  /// In hi, this message translates to:
  /// **'बीच में GPS सिग्नल टूट गया।'**
  String get flagGap;

  /// No description provided for @flagSparse.
  ///
  /// In hi, this message translates to:
  /// **'GPS से बहुत कम जानकारी मिली।'**
  String get flagSparse;

  /// No description provided for @flagTooShort.
  ///
  /// In hi, this message translates to:
  /// **'दौड़ बहुत छोटी थी।'**
  String get flagTooShort;

  /// No description provided for @uploading.
  ///
  /// In hi, this message translates to:
  /// **'सर्वर पर जांच हो रही है…'**
  String get uploading;

  /// No description provided for @savedOffline.
  ///
  /// In hi, this message translates to:
  /// **'इंटरनेट नहीं है। दौड़ फोन में सेव है और इंटरनेट मिलने पर भेज दी जाएगी।'**
  String get savedOffline;

  /// No description provided for @uploadRefused.
  ///
  /// In hi, this message translates to:
  /// **'सर्वर ने यह दौड़ नहीं ली (आज की सीमा पूरी या गलत डेटा)।'**
  String get uploadRefused;

  /// No description provided for @serverChecked.
  ///
  /// In hi, this message translates to:
  /// **'सर्वर जांच पूरी'**
  String get serverChecked;

  /// No description provided for @done.
  ///
  /// In hi, this message translates to:
  /// **'ठीक है'**
  String get done;

  /// No description provided for @mockPetCta.
  ///
  /// In hi, this message translates to:
  /// **'मॉक PET दौड़ें'**
  String get mockPetCta;

  /// No description provided for @recordRun.
  ///
  /// In hi, this message translates to:
  /// **'दौड़ रिकॉर्ड करें'**
  String get recordRun;

  /// No description provided for @recentRuns.
  ///
  /// In hi, this message translates to:
  /// **'हाल की GPS दौड़ें'**
  String get recentRuns;

  /// No description provided for @pendingRuns.
  ///
  /// In hi, this message translates to:
  /// **'{n} दौड़ भेजनी बाकी'**
  String pendingRuns(int n);

  /// No description provided for @minPerKm.
  ///
  /// In hi, this message translates to:
  /// **'{pace} /किमी'**
  String minPerKm(String pace);

  /// No description provided for @tabRanking.
  ///
  /// In hi, this message translates to:
  /// **'रैंकिंग'**
  String get tabRanking;

  /// No description provided for @areaVisible.
  ///
  /// In hi, this message translates to:
  /// **'दूसरों की रैंकिंग में मेरा नाम दिखाएं'**
  String get areaVisible;

  /// No description provided for @areaVisibleNote.
  ///
  /// In hi, this message translates to:
  /// **'केवल पहला नाम और उपनाम का पहला अक्षर दिखता है।'**
  String get areaVisibleNote;

  /// No description provided for @metricPet.
  ///
  /// In hi, this message translates to:
  /// **'PET समय'**
  String get metricPet;

  /// No description provided for @metricDistance.
  ///
  /// In hi, this message translates to:
  /// **'इस हफ्ते की दूरी'**
  String get metricDistance;

  /// No description provided for @thisWeek.
  ///
  /// In hi, this message translates to:
  /// **'इस हफ्ते'**
  String get thisWeek;

  /// No description provided for @lastWeek.
  ///
  /// In hi, this message translates to:
  /// **'पिछला हफ्ता'**
  String get lastWeek;

  /// No description provided for @rankingRules.
  ///
  /// In hi, this message translates to:
  /// **'केवल GPS से जाँची गई दौड़ें गिनी जाती हैं। PET समय के लिए असली दूरी पर मॉक PET दौड़ें। रैंकिंग हर सोमवार नई शुरू होती है।'**
  String get rankingRules;

  /// No description provided for @rankingEmpty.
  ///
  /// In hi, this message translates to:
  /// **'इस हफ्ते यहाँ अभी कोई नहीं है। मॉक PET दौड़कर पहले नंबर पर आएं!'**
  String get rankingEmpty;

  /// No description provided for @youLabel.
  ///
  /// In hi, this message translates to:
  /// **'आप'**
  String get youLabel;

  /// No description provided for @errAiBusy.
  ///
  /// In hi, this message translates to:
  /// **'AI कोच अभी बहुत लोगों का प्लान बना रहा है। 1 मिनट बाद फिर कोशिश करें।'**
  String get errAiBusy;

  /// No description provided for @boardEveryone.
  ///
  /// In hi, this message translates to:
  /// **'सभी'**
  String get boardEveryone;

  /// No description provided for @communitiesTitle.
  ///
  /// In hi, this message translates to:
  /// **'मेरे इलाके और ग्रुप'**
  String get communitiesTitle;

  /// No description provided for @communitiesIntro.
  ///
  /// In hi, this message translates to:
  /// **'अपने गाँव, मैदान या दोस्तों के ग्रुप से जुड़ें और उन्हीं से मुकाबला करें। न मिले तो खुद बना लें!'**
  String get communitiesIntro;

  /// No description provided for @manageCommunities.
  ///
  /// In hi, this message translates to:
  /// **'इलाके / ग्रुप'**
  String get manageCommunities;

  /// No description provided for @searchCommunities.
  ///
  /// In hi, this message translates to:
  /// **'गाँव, मैदान या ग्रुप ढूंढें'**
  String get searchCommunities;

  /// No description provided for @noCommunitiesFound.
  ///
  /// In hi, this message translates to:
  /// **'कुछ नहीं मिला। नीचे से नया बना लें।'**
  String get noCommunitiesFound;

  /// No description provided for @joinLabel.
  ///
  /// In hi, this message translates to:
  /// **'जुड़ें'**
  String get joinLabel;

  /// No description provided for @leaveLabel.
  ///
  /// In hi, this message translates to:
  /// **'छोड़ें'**
  String get leaveLabel;

  /// No description provided for @joinedLabel.
  ///
  /// In hi, this message translates to:
  /// **'जुड़े हुए'**
  String get joinedLabel;

  /// No description provided for @membersCount.
  ///
  /// In hi, this message translates to:
  /// **'{n} सदस्य'**
  String membersCount(int n);

  /// No description provided for @kindRegion.
  ///
  /// In hi, this message translates to:
  /// **'इलाका'**
  String get kindRegion;

  /// No description provided for @kindGroup.
  ///
  /// In hi, this message translates to:
  /// **'ग्रुप'**
  String get kindGroup;

  /// No description provided for @privateLabel.
  ///
  /// In hi, this message translates to:
  /// **'प्राइवेट'**
  String get privateLabel;

  /// No description provided for @createCommunity.
  ///
  /// In hi, this message translates to:
  /// **'नया बनाएं'**
  String get createCommunity;

  /// No description provided for @communityName.
  ///
  /// In hi, this message translates to:
  /// **'नाम'**
  String get communityName;

  /// No description provided for @communityKindRegion.
  ///
  /// In hi, this message translates to:
  /// **'इलाका (गाँव, मोहल्ला, मैदान) – सबके लिए खुला'**
  String get communityKindRegion;

  /// No description provided for @communityKindGroup.
  ///
  /// In hi, this message translates to:
  /// **'ग्रुप (दोस्त, बैच, अकादमी)'**
  String get communityKindGroup;

  /// No description provided for @communityPrivate.
  ///
  /// In hi, this message translates to:
  /// **'प्राइवेट – सिर्फ कोड से जुड़ सकते हैं'**
  String get communityPrivate;

  /// No description provided for @createLabel.
  ///
  /// In hi, this message translates to:
  /// **'बनाएं'**
  String get createLabel;

  /// No description provided for @joinByCode.
  ///
  /// In hi, this message translates to:
  /// **'कोड से जुड़ें'**
  String get joinByCode;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In hi, this message translates to:
  /// **'ग्रुप कोड'**
  String get inviteCodeLabel;

  /// No description provided for @inviteCodeShare.
  ///
  /// In hi, this message translates to:
  /// **'दोस्तों को यह कोड भेजें: {code}'**
  String inviteCodeShare(String code);

  /// No description provided for @codeCopied.
  ///
  /// In hi, this message translates to:
  /// **'कोड कॉपी हो गया'**
  String get codeCopied;

  /// No description provided for @errNameTaken.
  ///
  /// In hi, this message translates to:
  /// **'इस नाम का इलाका/ग्रुप पहले से है। ऊपर ढूंढकर उसमें जुड़ जाएं।'**
  String get errNameTaken;

  /// No description provided for @errCreateLimit.
  ///
  /// In hi, this message translates to:
  /// **'आज के लिए आप 3 बना चुके हैं। कल फिर बनाएं।'**
  String get errCreateLimit;

  /// No description provided for @errMemberLimit.
  ///
  /// In hi, this message translates to:
  /// **'आप 15 इलाकों/ग्रुप में हैं। नया जोड़ने के लिए कोई एक छोड़ें।'**
  String get errMemberLimit;

  /// No description provided for @errCodeNotFound.
  ///
  /// In hi, this message translates to:
  /// **'यह कोड नहीं मिला। दोबारा जांचें।'**
  String get errCodeNotFound;

  /// No description provided for @errCommunity.
  ///
  /// In hi, this message translates to:
  /// **'कुछ गड़बड़ हुई। फिर कोशिश करें।'**
  String get errCommunity;

  /// No description provided for @noCommunitiesYet.
  ///
  /// In hi, this message translates to:
  /// **'आप अभी किसी इलाके या ग्रुप में नहीं हैं। \'सभी\' की रैंकिंग देखें या अपना इलाका जोड़ें।'**
  String get noCommunitiesYet;

  /// No description provided for @catScSt.
  ///
  /// In hi, this message translates to:
  /// **'अनुसूचित जाति / जनजाति (SC/ST)'**
  String get catScSt;

  /// No description provided for @catHillAreas.
  ///
  /// In hi, this message translates to:
  /// **'पहाड़ी क्षेत्र (गढ़वाली, कुमाऊँनी, गोरखा आदि – प्रमाणपत्र के साथ)'**
  String get catHillAreas;

  /// No description provided for @catPoliceWard.
  ///
  /// In hi, this message translates to:
  /// **'दिल्ली पुलिस कर्मी के बेटे/बेटी'**
  String get catPoliceWard;

  /// No description provided for @eventLongJump.
  ///
  /// In hi, this message translates to:
  /// **'लंबी कूद'**
  String get eventLongJump;

  /// No description provided for @eventHighJump.
  ///
  /// In hi, this message translates to:
  /// **'ऊँची कूद'**
  String get eventHighJump;

  /// No description provided for @eventPullUps.
  ///
  /// In hi, this message translates to:
  /// **'पुल-अप (बीम)'**
  String get eventPullUps;

  /// No description provided for @eventDitch.
  ///
  /// In hi, this message translates to:
  /// **'9 फीट गड्ढा कूद'**
  String get eventDitch;

  /// No description provided for @eventZigzag.
  ///
  /// In hi, this message translates to:
  /// **'ज़िग-ज़ैग बैलेंस'**
  String get eventZigzag;

  /// No description provided for @mustPass.
  ///
  /// In hi, this message translates to:
  /// **'पास होना ज़रूरी'**
  String get mustPass;

  /// No description provided for @countAtLeast.
  ///
  /// In hi, this message translates to:
  /// **'कम से कम {n}'**
  String countAtLeast(int n);

  /// No description provided for @standardsForAge.
  ///
  /// In hi, this message translates to:
  /// **'आपकी उम्र ({age} साल) के हिसाब से मानक'**
  String standardsForAge(int age);

  /// No description provided for @examUnconfirmed.
  ///
  /// In hi, this message translates to:
  /// **'इस परीक्षा के मानक अभी आधिकारिक सूचना से पुष्ट नहीं हुए हैं। पुष्टि होते ही यहाँ दिखेंगे, और तभी AI प्लान, मॉक PET और रैंकिंग चालू होंगी।'**
  String get examUnconfirmed;

  /// No description provided for @voiceStarted.
  ///
  /// In hi, this message translates to:
  /// **'चलो शुरू! आराम से शुरुआत करो, पहला किलोमीटर रेस नहीं, वार्म-अप है।'**
  String get voiceStarted;

  /// No description provided for @voiceKmDone.
  ///
  /// In hi, this message translates to:
  /// **'{km} किलोमीटर पूरा। समय {time}।'**
  String voiceKmDone(int km, String time);

  /// No description provided for @voiceHalfway.
  ///
  /// In hi, this message translates to:
  /// **'आधा रास्ता पूरा!'**
  String get voiceHalfway;

  /// No description provided for @voiceLastStretch.
  ///
  /// In hi, this message translates to:
  /// **'बस {metres} मीटर बाकी! अब पूरी ताकत लगाओ!'**
  String voiceLastStretch(int metres);

  /// No description provided for @voiceAhead.
  ///
  /// In hi, this message translates to:
  /// **'लक्ष्य से {seconds} सेकंड आगे।'**
  String voiceAhead(int seconds);

  /// No description provided for @voiceBehind.
  ///
  /// In hi, this message translates to:
  /// **'लक्ष्य से {seconds} सेकंड पीछे, थोड़ा तेज़!'**
  String voiceBehind(int seconds);

  /// No description provided for @voiceCheer1.
  ///
  /// In hi, this message translates to:
  /// **'शाबाश शेर!'**
  String get voiceCheer1;

  /// No description provided for @voiceCheer2.
  ///
  /// In hi, this message translates to:
  /// **'टांगें बोल रही हैं थक गए, दिल बोल रहा है चलते रहो!'**
  String get voiceCheer2;

  /// No description provided for @voiceCheer3.
  ///
  /// In hi, this message translates to:
  /// **'वर्दी इंतज़ार कर रही है!'**
  String get voiceCheer3;

  /// No description provided for @voiceCheer4.
  ///
  /// In hi, this message translates to:
  /// **'साँस पर ध्यान, कदम छोटे और तेज़।'**
  String get voiceCheer4;

  /// No description provided for @voiceFinished.
  ///
  /// In hi, this message translates to:
  /// **'दौड़ पूरी! पानी पियो और थोड़ा टहल लो।'**
  String get voiceFinished;

  /// No description provided for @voiceTime.
  ///
  /// In hi, this message translates to:
  /// **'{minutes} मिनट {seconds} सेकंड'**
  String voiceTime(int minutes, int seconds);

  /// No description provided for @voiceOn.
  ///
  /// In hi, this message translates to:
  /// **'आवाज़ चालू'**
  String get voiceOn;

  /// No description provided for @voiceOff.
  ///
  /// In hi, this message translates to:
  /// **'आवाज़ बंद'**
  String get voiceOff;

  /// No description provided for @shareButton.
  ///
  /// In hi, this message translates to:
  /// **'WhatsApp पर शेयर करें'**
  String get shareButton;

  /// No description provided for @sharePetText.
  ///
  /// In hi, this message translates to:
  /// **'मैंने मैदान ऐप में {distance} की मॉक दौड़ {time} में पूरी की ({margin})! {outcome} तुम भी अपनी भर्ती की तैयारी जाँचो।'**
  String sharePetText(
    String distance,
    String time,
    String margin,
    String outcome,
  );

  /// No description provided for @shareRankText.
  ///
  /// In hi, this message translates to:
  /// **'मैदान ऐप की इस हफ़्ते की लीडरबोर्ड ({board}) में मेरी रैंक #{rank} है, {value}! क्या तुम मुझे हरा सकते हो?'**
  String shareRankText(String board, int rank, String value);
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
