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
