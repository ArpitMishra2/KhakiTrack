// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'मैदान';

  @override
  String get welcomeTitle => 'सरकारी भर्ती की शारीरिक परीक्षा की तैयारी';

  @override
  String get welcomeSubtitle => 'यूपी पुलिस कांस्टेबल और SSC GD';

  @override
  String get chooseExam => 'अपनी परीक्षा चुनें';

  @override
  String get loadError => 'डेटा लोड नहीं हो सका। इंटरनेट कनेक्शन जांचें।';

  @override
  String get retry => 'फिर कोशिश करें';

  @override
  String get gender => 'लिंग';

  @override
  String get male => 'पुरुष';

  @override
  String get female => 'महिला';

  @override
  String get category => 'श्रेणी';

  @override
  String get sectionPst => 'शारीरिक मानक परीक्षण (PST)';

  @override
  String get sectionPet => 'शारीरिक दक्षता परीक्षा (PET)';

  @override
  String get eventHeight => 'न्यूनतम लंबाई';

  @override
  String get eventWeight => 'न्यूनतम वज़न';

  @override
  String get eventChestUnexpanded => 'सीना (बिना फुलाए)';

  @override
  String get eventChestExpanded => 'सीना (फुलाकर)';

  @override
  String get eventChestExpansion => 'सीने का न्यूनतम फुलाव';

  @override
  String eventRun(String distance) {
    return '$distance दौड़';
  }

  @override
  String valueCm(String value) {
    return '$value सेमी';
  }

  @override
  String valueKg(String value) {
    return '$value किग्रा';
  }

  @override
  String distanceKm(String value) {
    return '$value किमी';
  }

  @override
  String distanceM(String value) {
    return '$value मीटर';
  }

  @override
  String timeMinutes(int minutes) {
    return '$minutes मिनट में';
  }

  @override
  String timeMinutesSeconds(int minutes, int seconds) {
    return '$minutes मिनट $seconds सेकंड में';
  }

  @override
  String get notConfirmed => 'पुष्टि बाकी';

  @override
  String get noStandards => 'इस चयन के लिए कोई मानक नहीं मिला।';

  @override
  String sourceNote(String version) {
    return 'स्रोत: आधिकारिक भर्ती सूचना (डेटा संस्करण $version)';
  }

  @override
  String get catGeneral => 'सामान्य / OBC / SC / EWS';

  @override
  String get catSt => 'अनुसूचित जनजाति (ST)';

  @override
  String get catStNeStates => 'ST – पूर्वोत्तर राज्य';

  @override
  String get catStLweDistricts => 'ST – वामपंथी उग्रवाद प्रभावित ज़िले';

  @override
  String get catHillGroups =>
      'गढ़वाली, कुमाऊँनी, डोगरा, मराठा, असम, हिमाचल, जम्मू-कश्मीर';

  @override
  String get catLadakh => 'लद्दाख क्षेत्र';

  @override
  String get catNeStates =>
      'पूर्वोत्तर राज्य (अरुणाचल, मणिपुर, मेघालय, मिज़ोरम, नागालैंड, सिक्किम, त्रिपुरा)';

  @override
  String get catGta => 'गोरखा क्षेत्रीय प्रशासन (दार्जिलिंग)';
}
