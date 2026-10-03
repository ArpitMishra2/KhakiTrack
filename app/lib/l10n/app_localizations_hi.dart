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

  @override
  String get signInWithGoogle => 'Google से जारी रखें';

  @override
  String get signInFailed =>
      'साइन इन नहीं हो सका। इंटरनेट जांचकर फिर कोशिश करें।';

  @override
  String get adultsOnly =>
      'यह ऐप केवल 18 वर्ष या उससे अधिक उम्र के लोगों के लिए है।';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get profileTitle => 'आपकी जानकारी';

  @override
  String get profileIntro => 'सही शारीरिक मानक दिखाने के लिए यह जानकारी चाहिए।';

  @override
  String get name => 'नाम';

  @override
  String get dateOfBirth => 'जन्म तिथि';

  @override
  String get chooseDate => 'तारीख चुनें';

  @override
  String get chooseCategory => 'श्रेणी चुनें';

  @override
  String get save => 'सेव करें';

  @override
  String get saveFailed => 'सेव नहीं हो सका। इंटरनेट जांचकर फिर कोशिश करें।';

  @override
  String get socialGeneral => 'सामान्य';

  @override
  String get socialObc => 'अन्य पिछड़ा वर्ग (OBC)';

  @override
  String get socialSc => 'अनुसूचित जाति (SC)';

  @override
  String get socialSt => 'अनुसूचित जनजाति (ST)';

  @override
  String get socialEws => 'आर्थिक रूप से कमज़ोर वर्ग (EWS)';

  @override
  String get tabTraining => 'ट्रेनिंग';

  @override
  String get tabStandards => 'मानक';

  @override
  String get tabProgress => 'प्रगति';

  @override
  String get trainingIntroTitle => 'आपका अपना रनिंग प्लान';

  @override
  String get trainingIntroBody =>
      'कुछ सवालों के जवाब दें। AI आपके अभी के स्तर, समय और अनुभव के हिसाब से हफ्ते-दर-हफ्ते प्लान बनाएगा, ताकि PET के दिन तक आप दौड़ आराम से समय में पूरी कर सकें।';

  @override
  String get startQuestionnaire => 'प्लान बनाना शुरू करें';

  @override
  String get qTitle => 'आपके बारे में';

  @override
  String qStep(int step, int total) {
    return 'चरण $step / $total';
  }

  @override
  String get qNext => 'आगे';

  @override
  String get qBack => 'पीछे';

  @override
  String get qCreate => 'मेरा प्लान बनाएं';

  @override
  String get qLevelTitle => 'अभी आपका स्तर';

  @override
  String qCanComplete(String distance) {
    return 'क्या आप अभी $distance बिना रुके दौड़ सकते हैं?';
  }

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String qCurrentTime(String distance) {
    return '$distance में कितना समय लगता है? (मिनट:सेकंड)';
  }

  @override
  String get qTimeHint => 'जैसे 27:30';

  @override
  String get qTimeInvalid => 'समय मिनट:सेकंड में लिखें, जैसे 27:30';

  @override
  String get qLongest => 'बिना रुके सबसे ज़्यादा कितना दौड़ लेते हैं?';

  @override
  String qTarget(String distance, String time) {
    return 'लक्ष्य: $distance $time में';
  }

  @override
  String get qExperienceTitle => 'अनुभव';

  @override
  String get qExperience => 'आप कब से नियमित दौड़ रहे हैं?';

  @override
  String get expNone => 'अभी शुरू नहीं किया';

  @override
  String get expLt3m => '3 महीने से कम';

  @override
  String get exp3to12m => '3 से 12 महीने';

  @override
  String get expGt1y => '1 साल से ज़्यादा';

  @override
  String get qRunsPerWeek => 'अभी हफ्ते में कितनी बार दौड़ते हैं?';

  @override
  String get qWeeklyKm => 'हफ्ते में कुल लगभग कितने किमी?';

  @override
  String get qBackground => 'और कौन-सा शारीरिक काम करते हैं?';

  @override
  String get bgFarm => 'खेती / मेहनत का काम';

  @override
  String get bgSports => 'खेल (क्रिकेट, फुटबॉल, कबड्डी)';

  @override
  String get bgGym => 'जिम / कसरत';

  @override
  String get qScheduleTitle => 'समय और दिन';

  @override
  String get qWeeks => 'PET में लगभग कितने हफ्ते बचे हैं?';

  @override
  String get qWeeksUnknown => 'तारीख पता नहीं हो तो 12 हफ्ते चुनें।';

  @override
  String weeksN(int n) {
    return '$n हफ्ते';
  }

  @override
  String get qDays => 'हफ्ते में कितने दिन ट्रेनिंग कर सकते हैं?';

  @override
  String daysN(int n) {
    return '$n दिन';
  }

  @override
  String get qMinutes => 'एक बार में कितना समय दे सकते हैं?';

  @override
  String minutesN(int n) {
    return '$n मिनट';
  }

  @override
  String get qTrainingTime => 'कब दौड़ना पसंद है?';

  @override
  String get timeMorning => 'सुबह';

  @override
  String get timeEvening => 'शाम';

  @override
  String get timeEither => 'कभी भी';

  @override
  String get qSurface => 'कहाँ दौड़ते हैं?';

  @override
  String get surfaceGround => 'मैदान';

  @override
  String get surfaceRoad => 'सड़क';

  @override
  String get surfaceTrack => 'ट्रैक';

  @override
  String get surfaceMixed => 'मिला-जुला';

  @override
  String get qHealthTitle => 'सेहत';

  @override
  String get qPain => 'क्या अभी कहीं दर्द या चोट है?';

  @override
  String get painNone => 'कोई दर्द नहीं';

  @override
  String get painKnee => 'घुटना';

  @override
  String get painShin => 'पिंडली';

  @override
  String get painAnkle => 'टखना';

  @override
  String get painBack => 'कमर / पीठ';

  @override
  String get painOther => 'कुछ और';

  @override
  String get qPainNote => 'दर्द के बारे में थोड़ा बताएं (वैकल्पिक)';

  @override
  String get qMedical => 'कोई बीमारी?';

  @override
  String get medNone => 'कोई नहीं';

  @override
  String get medAsthma => 'दमा / सांस';

  @override
  String get medHeart => 'दिल की बीमारी';

  @override
  String get medBp => 'बीपी';

  @override
  String get medDiabetes => 'शुगर';

  @override
  String get medOther => 'कुछ और';

  @override
  String get qWeight => 'वज़न किग्रा (वैकल्पिक)';

  @override
  String get qHeight => 'लंबाई सेमी (वैकल्पिक)';

  @override
  String get generatingTitle => 'AI आपका प्लान बना रहा है';

  @override
  String get generatingBody => 'इसमें 1-2 मिनट लग सकते हैं। ऐप बंद न करें।';

  @override
  String get errRateLimited =>
      'आज के लिए प्लान बनाने की सीमा पूरी हो गई। कल फिर कोशिश करें।';

  @override
  String get errAiNotConfigured =>
      'AI प्लान अभी चालू नहीं है। थोड़ी देर बाद कोशिश करें।';

  @override
  String get errGeneration => 'प्लान नहीं बन पाया। फिर कोशिश करें।';

  @override
  String errTooEarly(String date) {
    return 'अगला हफ्ता $date से खुलेगा।';
  }

  @override
  String get errNetwork =>
      'इंटरनेट से जुड़ नहीं पाए। कनेक्शन जांचकर फिर कोशिश करें।';

  @override
  String get readinessOnTrack => 'सही रास्ते पर';

  @override
  String get readinessNeedsWork => 'मेहनत की ज़रूरत';

  @override
  String get readinessBigGap => 'लंबा सफ़र';

  @override
  String get seeDoctor => 'शुरू करने से पहले डॉक्टर से सलाह ज़रूर लें।';

  @override
  String weekOf(int week, int total) {
    return 'हफ्ता $week / $total';
  }

  @override
  String get recoveryWeek => 'आराम वाला हफ्ता';

  @override
  String weekDone(int done, int total) {
    return '$done / $total सेशन पूरे';
  }

  @override
  String generateNextWeek(int week) {
    return 'हफ्ता $week का प्लान बनाएं';
  }

  @override
  String nextWeekLocked(int week, String date) {
    return 'हफ्ता $week का प्लान $date को खुलेगा, ताकि वह आपकी इस हफ्ते की ट्रेनिंग के हिसाब से बने।';
  }

  @override
  String get planFinished => 'प्लान पूरा हुआ। PET के लिए शुभकामनाएं!';

  @override
  String get fullPlan => 'पूरा प्लान';

  @override
  String get safetyNotes => 'ध्यान रखें';

  @override
  String get newPlan => 'नया प्लान बनाएं';

  @override
  String get newPlanConfirm =>
      'नया प्लान बनाने पर अभी वाला प्लान बंद हो जाएगा। आगे बढ़ें?';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get continueLabel => 'आगे बढ़ें';

  @override
  String get sessionToday => 'आज';

  @override
  String get statusDone => 'पूरा';

  @override
  String get statusPartial => 'आधा';

  @override
  String get statusMissed => 'छूट गया';

  @override
  String get logSession => 'सेशन दर्ज करें';

  @override
  String get logDistance => 'कितना दौड़े (किमी)';

  @override
  String get logTime => 'कुल समय (मिनट:सेकंड)';

  @override
  String get logEffort => 'कितना मुश्किल लगा? (1 आसान – 5 बहुत मुश्किल)';

  @override
  String get logPain => 'दौड़ते समय या बाद में दर्द हुआ';

  @override
  String get logNote => 'नोट (वैकल्पिक)';

  @override
  String get painWarning =>
      'दर्द हो तो अगले सेशन धीरे करें। दर्द बढ़े या 2-3 दिन में ठीक न हो तो डॉक्टर को दिखाएं।';

  @override
  String km(String value) {
    return '$value किमी';
  }

  @override
  String minutesShort(String value) {
    return '$value मिनट';
  }

  @override
  String pacePerKm(String pace) {
    return '$pace प्रति किमी';
  }

  @override
  String get typeEasyRun => 'आसान दौड़';

  @override
  String get typeRunWalk => 'दौड़-चाल';

  @override
  String get typeLongRun => 'लंबी दौड़';

  @override
  String get typeTempo => 'टेम्पो रन';

  @override
  String get typeIntervals => 'इंटरवल';

  @override
  String get typeTimeTrial => 'टाइम ट्रायल';

  @override
  String get typeStrength => 'ताकत की कसरत';

  @override
  String get typeMobility => 'स्ट्रेचिंग';

  @override
  String progressTitle(String distance) {
    return '$distance का समय';
  }

  @override
  String get progressEmpty =>
      'अभी कोई टाइम ट्रायल नहीं। अपना समय दर्ज करें और यहाँ अपनी प्रगति देखें।';

  @override
  String get addTrial => 'टाइम ट्रायल जोड़ें';

  @override
  String get trialDistance => 'दूरी (मीटर)';

  @override
  String get trialTime => 'समय (मिनट:सेकंड)';

  @override
  String get trialDate => 'तारीख';

  @override
  String latestTime(String time) {
    return 'ताज़ा समय: $time';
  }

  @override
  String targetTime(String time) {
    return 'लक्ष्य: $time';
  }

  @override
  String gapToCut(String time) {
    return 'अभी $time और कम करना है';
  }

  @override
  String underTarget(String time) {
    return 'आप लक्ष्य से $time तेज़ हैं। इसे बनाए रखें!';
  }

  @override
  String get estimated => 'अनुमानित';

  @override
  String estimateNote(String distance) {
    return 'दूसरी दूरी के ट्रायल से $distance का समय अनुमान से निकाला गया है।';
  }

  @override
  String get trialSaveFailed => 'सेव नहीं हो सका। फिर कोशिश करें।';

  @override
  String get runTitle => 'दौड़';

  @override
  String get mockPetTitle => 'मॉक PET';

  @override
  String get freeRunTitle => 'खुली दौड़';

  @override
  String mockPetIntro(String distance, String time) {
    return 'असली PET की तरह $distance दौड़ें। ऐप GPS से समय नापेगा और बताएगा कि आप $time के लक्ष्य में क्वालीफाई करते या नहीं।';
  }

  @override
  String get freeRunIntro => 'अपनी किसी भी दौड़ को GPS से रिकॉर्ड करें।';

  @override
  String get runTips =>
      'खुले मैदान में दौड़ें, फोन जेब या हाथ में रखें। Xiaomi/Redmi फोन में ऐप की बैटरी सेटिंग \'No restrictions\' रखें ताकि स्क्रीन बंद होने पर भी GPS चलता रहे।';

  @override
  String get gpsSearching => 'GPS सिग्नल ढूंढ रहे हैं…';

  @override
  String gpsAccuracy(int metres) {
    return 'GPS सटीकता: $metres मीटर';
  }

  @override
  String get gpsReady => 'GPS तैयार है';

  @override
  String get gpsDenied => 'दौड़ रिकॉर्ड करने के लिए लोकेशन की अनुमति चाहिए।';

  @override
  String get gpsOff => 'फोन की लोकेशन (GPS) चालू करें।';

  @override
  String get openSettings => 'सेटिंग खोलें';

  @override
  String get startRun => 'शुरू करें';

  @override
  String get startAnyway => 'फिर भी शुरू करें';

  @override
  String get holdToStop => 'रोकने के लिए दबाकर रखें';

  @override
  String get elapsed => 'समय';

  @override
  String get distanceLabel => 'दूरी';

  @override
  String get paceLabel => 'गति';

  @override
  String aheadBy(String time) {
    return 'लक्ष्य से $time आगे';
  }

  @override
  String behindBy(String time) {
    return 'लक्ष्य से $time पीछे';
  }

  @override
  String remaining(String distance) {
    return '$distance बाकी';
  }

  @override
  String get trackingNotificationTitle => 'मैदान: दौड़ रिकॉर्ड हो रही है';

  @override
  String get trackingNotificationText => 'GPS से दूरी और समय नापा जा रहा है';

  @override
  String get resultTitle => 'नतीजा';

  @override
  String get outcomeQualified => 'आप क्वालीफाई करते!';

  @override
  String get outcomeBorderline => 'सीमा पर – थोड़ा और तेज़ दौड़ें';

  @override
  String get outcomeNotQualified => 'अभी क्वालीफाई नहीं';

  @override
  String get outcomeIncomplete => 'दूरी पूरी नहीं हुई';

  @override
  String get borderlineNote =>
      'GPS में 2-3% तक का फर्क हो सकता है। पक्का क्वालीफाई के लिए लक्ष्य से कम से कम 3% तेज़ दौड़ें।';

  @override
  String finishTime(String distance, String time) {
    return '$distance का समय: $time';
  }

  @override
  String targetLine(String time) {
    return 'लक्ष्य: $time';
  }

  @override
  String marginAhead(String time) {
    return 'लक्ष्य से $time कम';
  }

  @override
  String marginBehind(String time) {
    return 'लक्ष्य से $time ज़्यादा';
  }

  @override
  String totalDistance(String distance) {
    return 'कुल दूरी: $distance';
  }

  @override
  String totalTime(String time) {
    return 'कुल समय: $time';
  }

  @override
  String get verdictVerified => 'GPS जांच: सही';

  @override
  String get verdictSuspicious => 'GPS जांच: पक्का नहीं';

  @override
  String get verdictRejected => 'GPS जांच: अमान्य';

  @override
  String get verdictNotCounted =>
      'यह दौड़ प्रगति और रैंकिंग में नहीं गिनी जाएगी।';

  @override
  String get flagMock => 'नकली लोकेशन (mock location) मिली।';

  @override
  String get flagTeleport => 'लोकेशन अचानक बहुत दूर कूद गई।';

  @override
  String get flagImpossibleSpeed => 'कुछ हिस्से में गति इंसान के लिए असंभव थी।';

  @override
  String get flagVehicle => 'कुछ हिस्सा गाड़ी/साइकिल जैसी गति से था।';

  @override
  String get flagAverage => 'पूरी दौड़ की औसत गति असंभव थी।';

  @override
  String get flagPoorSignal => 'GPS सिग्नल कमज़ोर था।';

  @override
  String get flagGap => 'बीच में GPS सिग्नल टूट गया।';

  @override
  String get flagSparse => 'GPS से बहुत कम जानकारी मिली।';

  @override
  String get flagTooShort => 'दौड़ बहुत छोटी थी।';

  @override
  String get uploading => 'सर्वर पर जांच हो रही है…';

  @override
  String get savedOffline =>
      'इंटरनेट नहीं है। दौड़ फोन में सेव है और इंटरनेट मिलने पर भेज दी जाएगी।';

  @override
  String get uploadRefused =>
      'सर्वर ने यह दौड़ नहीं ली (आज की सीमा पूरी या गलत डेटा)।';

  @override
  String get serverChecked => 'सर्वर जांच पूरी';

  @override
  String get done => 'ठीक है';

  @override
  String get mockPetCta => 'मॉक PET दौड़ें';

  @override
  String get recordRun => 'दौड़ रिकॉर्ड करें';

  @override
  String get recentRuns => 'हाल की GPS दौड़ें';

  @override
  String pendingRuns(int n) {
    return '$n दौड़ भेजनी बाकी';
  }

  @override
  String minPerKm(String pace) {
    return '$pace /किमी';
  }

  @override
  String get tabRanking => 'रैंकिंग';

  @override
  String get areaVisible => 'दूसरों की रैंकिंग में मेरा नाम दिखाएं';

  @override
  String get areaVisibleNote =>
      'केवल पहला नाम और उपनाम का पहला अक्षर दिखता है।';

  @override
  String get metricPet => 'PET समय';

  @override
  String get metricDistance => 'इस हफ्ते की दूरी';

  @override
  String get thisWeek => 'इस हफ्ते';

  @override
  String get lastWeek => 'पिछला हफ्ता';

  @override
  String get rankingRules =>
      'केवल GPS से जाँची गई दौड़ें गिनी जाती हैं। PET समय के लिए असली दूरी पर मॉक PET दौड़ें। रैंकिंग हर सोमवार नई शुरू होती है।';

  @override
  String get rankingEmpty =>
      'इस हफ्ते यहाँ अभी कोई नहीं है। मॉक PET दौड़कर पहले नंबर पर आएं!';

  @override
  String get youLabel => 'आप';

  @override
  String get errAiBusy =>
      'AI कोच अभी बहुत लोगों का प्लान बना रहा है। 1 मिनट बाद फिर कोशिश करें।';

  @override
  String get boardEveryone => 'सभी';

  @override
  String get communitiesTitle => 'मेरे इलाके और ग्रुप';

  @override
  String get communitiesIntro =>
      'अपने गाँव, मैदान या दोस्तों के ग्रुप से जुड़ें और उन्हीं से मुकाबला करें। न मिले तो खुद बना लें!';

  @override
  String get manageCommunities => 'इलाके / ग्रुप';

  @override
  String get searchCommunities => 'गाँव, मैदान या ग्रुप ढूंढें';

  @override
  String get noCommunitiesFound => 'कुछ नहीं मिला। नीचे से नया बना लें।';

  @override
  String get joinLabel => 'जुड़ें';

  @override
  String get leaveLabel => 'छोड़ें';

  @override
  String get joinedLabel => 'जुड़े हुए';

  @override
  String membersCount(int n) {
    return '$n सदस्य';
  }

  @override
  String get kindRegion => 'इलाका';

  @override
  String get kindGroup => 'ग्रुप';

  @override
  String get privateLabel => 'प्राइवेट';

  @override
  String get createCommunity => 'नया बनाएं';

  @override
  String get communityName => 'नाम';

  @override
  String get communityKindRegion =>
      'इलाका (गाँव, मोहल्ला, मैदान) – सबके लिए खुला';

  @override
  String get communityKindGroup => 'ग्रुप (दोस्त, बैच, अकादमी)';

  @override
  String get communityPrivate => 'प्राइवेट – सिर्फ कोड से जुड़ सकते हैं';

  @override
  String get createLabel => 'बनाएं';

  @override
  String get joinByCode => 'कोड से जुड़ें';

  @override
  String get inviteCodeLabel => 'ग्रुप कोड';

  @override
  String inviteCodeShare(String code) {
    return 'दोस्तों को यह कोड भेजें: $code';
  }

  @override
  String get codeCopied => 'कोड कॉपी हो गया';

  @override
  String get errNameTaken =>
      'इस नाम का इलाका/ग्रुप पहले से है। ऊपर ढूंढकर उसमें जुड़ जाएं।';

  @override
  String get errCreateLimit => 'आज के लिए आप 3 बना चुके हैं। कल फिर बनाएं।';

  @override
  String get errMemberLimit =>
      'आप 15 इलाकों/ग्रुप में हैं। नया जोड़ने के लिए कोई एक छोड़ें।';

  @override
  String get errCodeNotFound => 'यह कोड नहीं मिला। दोबारा जांचें।';

  @override
  String get errCommunity => 'कुछ गड़बड़ हुई। फिर कोशिश करें।';

  @override
  String get noCommunitiesYet =>
      'आप अभी किसी इलाके या ग्रुप में नहीं हैं। \'सभी\' की रैंकिंग देखें या अपना इलाका जोड़ें।';

  @override
  String get catScSt => 'अनुसूचित जाति / जनजाति (SC/ST)';

  @override
  String get catHillAreas =>
      'पहाड़ी क्षेत्र (गढ़वाली, कुमाऊँनी, गोरखा आदि – प्रमाणपत्र के साथ)';

  @override
  String get catPoliceWard => 'दिल्ली पुलिस कर्मी के बेटे/बेटी';

  @override
  String get eventLongJump => 'लंबी कूद';

  @override
  String get eventHighJump => 'ऊँची कूद';

  @override
  String get eventPullUps => 'पुल-अप (बीम)';

  @override
  String get eventDitch => '9 फीट गड्ढा कूद';

  @override
  String get eventZigzag => 'ज़िग-ज़ैग बैलेंस';

  @override
  String get mustPass => 'पास होना ज़रूरी';

  @override
  String countAtLeast(int n) {
    return 'कम से कम $n';
  }

  @override
  String standardsForAge(int age) {
    return 'आपकी उम्र ($age साल) के हिसाब से मानक';
  }

  @override
  String get examUnconfirmed =>
      'इस परीक्षा के मानक अभी आधिकारिक सूचना से पुष्ट नहीं हुए हैं। पुष्टि होते ही यहाँ दिखेंगे, और तभी AI प्लान, मॉक PET और रैंकिंग चालू होंगी।';

  @override
  String get voiceStarted =>
      'चलो शुरू! आराम से शुरुआत करो, पहला किलोमीटर रेस नहीं, वार्म-अप है।';

  @override
  String voiceKmDone(int km, String time) {
    return '$km किलोमीटर पूरा। समय $time।';
  }

  @override
  String get voiceHalfway => 'आधा रास्ता पूरा!';

  @override
  String voiceLastStretch(int metres) {
    return 'बस $metres मीटर बाकी! अब पूरी ताकत लगाओ!';
  }

  @override
  String voiceAhead(int seconds) {
    return 'लक्ष्य से $seconds सेकंड आगे।';
  }

  @override
  String voiceBehind(int seconds) {
    return 'लक्ष्य से $seconds सेकंड पीछे, थोड़ा तेज़!';
  }

  @override
  String get voiceCheer1 => 'शाबाश शेर!';

  @override
  String get voiceCheer2 =>
      'टांगें बोल रही हैं थक गए, दिल बोल रहा है चलते रहो!';

  @override
  String get voiceCheer3 => 'वर्दी इंतज़ार कर रही है!';

  @override
  String get voiceCheer4 => 'साँस पर ध्यान, कदम छोटे और तेज़।';

  @override
  String get voiceFinished => 'दौड़ पूरी! पानी पियो और थोड़ा टहल लो।';

  @override
  String voiceTime(int minutes, int seconds) {
    return '$minutes मिनट $seconds सेकंड';
  }

  @override
  String get voiceOn => 'आवाज़ चालू';

  @override
  String get voiceOff => 'आवाज़ बंद';

  @override
  String get shareButton => 'WhatsApp पर शेयर करें';

  @override
  String sharePetText(
    String distance,
    String time,
    String margin,
    String outcome,
  ) {
    return 'मैंने मैदान ऐप में $distance की मॉक दौड़ $time में पूरी की ($margin)! $outcome तुम भी अपनी भर्ती की तैयारी जाँचो।';
  }

  @override
  String shareRankText(String board, int rank, String value) {
    return 'मैदान ऐप की इस हफ़्ते की लीडरबोर्ड ($board) में मेरी रैंक #$rank है, $value! क्या तुम मुझे हरा सकते हो?';
  }
}
