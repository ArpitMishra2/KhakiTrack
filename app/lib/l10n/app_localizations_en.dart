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
  String get welcomeTitle => 'Physical test prep';

  @override
  String get welcomeSubtitle => 'UP Police · SSC GD · Delhi Police';

  @override
  String get chooseExam => 'Choose your exam';

  @override
  String get loadError => 'Couldn\'t load. Check your internet.';

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
    return 'Source: official notice · $version';
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

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get signInFailed => 'Sign-in failed. Try again.';

  @override
  String get adultsOnly => '18+ only';

  @override
  String get signOut => 'Sign out';

  @override
  String get profileTitle => 'About you';

  @override
  String get profileIntro => 'So we can show the right standards.';

  @override
  String get name => 'Name';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get chooseDate => 'Choose date';

  @override
  String get chooseCategory => 'Choose category';

  @override
  String get save => 'Save';

  @override
  String get saveFailed => 'Couldn\'t save. Try again.';

  @override
  String get socialGeneral => 'General';

  @override
  String get socialObc => 'Other Backward Class (OBC)';

  @override
  String get socialSc => 'Scheduled Caste (SC)';

  @override
  String get socialSt => 'Scheduled Tribe (ST)';

  @override
  String get socialEws => 'Economically Weaker Section (EWS)';

  @override
  String get tabTraining => 'Training';

  @override
  String get tabStandards => 'Standards';

  @override
  String get tabProgress => 'Progress';

  @override
  String get trainingIntroTitle => 'Your own running plan';

  @override
  String get trainingIntroBody =>
      'Four short questions, then a week-by-week plan built around your level and schedule.';

  @override
  String get startQuestionnaire => 'Start building my plan';

  @override
  String get qTitle => 'About your running';

  @override
  String qStep(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get qNext => 'Next';

  @override
  String get qBack => 'Back';

  @override
  String get qCreate => 'Build my plan';

  @override
  String get qLevelTitle => 'Where you are now';

  @override
  String qCanComplete(String distance) {
    return 'Can you run $distance without stopping today?';
  }

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String qCurrentTime(String distance) {
    return 'How long does $distance take you? (min:sec)';
  }

  @override
  String get qTimeHint => 'e.g. 27:30';

  @override
  String get qTimeInvalid => 'Enter time as min:sec, e.g. 27:30';

  @override
  String get qLongest => 'What is the longest you can run without stopping?';

  @override
  String qTarget(String distance, String time) {
    return 'Target: $distance within $time';
  }

  @override
  String get qExperienceTitle => 'Experience';

  @override
  String get qExperience => 'How long have you been running regularly?';

  @override
  String get expNone => 'Not started yet';

  @override
  String get expLt3m => 'Less than 3 months';

  @override
  String get exp3to12m => '3 to 12 months';

  @override
  String get expGt1y => 'More than a year';

  @override
  String get qRunsPerWeek => 'How many times a week do you run now?';

  @override
  String get qWeeklyKm => 'About how many km a week in total?';

  @override
  String get qBackground => 'What other physical work do you do?';

  @override
  String get bgFarm => 'Farm or manual work';

  @override
  String get bgSports => 'Sports (cricket, football, kabaddi)';

  @override
  String get bgGym => 'Gym or workouts';

  @override
  String get qScheduleTitle => 'Time and days';

  @override
  String get qWeeks => 'About how many weeks until your PET?';

  @override
  String get qWeeksUnknown => 'Not announced? Pick 12 weeks.';

  @override
  String weeksN(int n) {
    return '$n weeks';
  }

  @override
  String get qDays => 'How many days a week can you train?';

  @override
  String daysN(int n) {
    return '$n days';
  }

  @override
  String get qMinutes => 'How much time can you give each session?';

  @override
  String minutesN(int n) {
    return '$n min';
  }

  @override
  String get qTrainingTime => 'When do you prefer to train?';

  @override
  String get timeMorning => 'Morning';

  @override
  String get timeEvening => 'Evening';

  @override
  String get timeEither => 'Either';

  @override
  String get qSurface => 'Where do you run?';

  @override
  String get surfaceGround => 'Ground';

  @override
  String get surfaceRoad => 'Road';

  @override
  String get surfaceTrack => 'Track';

  @override
  String get surfaceMixed => 'Mixed';

  @override
  String get qHealthTitle => 'Health';

  @override
  String get qPain => 'Any pain or injury right now?';

  @override
  String get painNone => 'No pain';

  @override
  String get painKnee => 'Knee';

  @override
  String get painShin => 'Shin';

  @override
  String get painAnkle => 'Ankle';

  @override
  String get painBack => 'Back';

  @override
  String get painOther => 'Other';

  @override
  String get qPainNote => 'Tell us a little about the pain (optional)';

  @override
  String get qMedical => 'Any medical condition?';

  @override
  String get medNone => 'None';

  @override
  String get medAsthma => 'Asthma / breathing';

  @override
  String get medHeart => 'Heart condition';

  @override
  String get medBp => 'Blood pressure';

  @override
  String get medDiabetes => 'Diabetes';

  @override
  String get medOther => 'Other';

  @override
  String get qWeight => 'Weight kg (optional)';

  @override
  String get qHeight => 'Height cm (optional)';

  @override
  String get generatingTitle => 'Building your plan';

  @override
  String get generatingBody => 'Takes 1-2 minutes. Keep the app open.';

  @override
  String get errRateLimited => 'Daily limit reached. Try again tomorrow.';

  @override
  String get errAiNotConfigured => 'Plan service is off for now. Try later.';

  @override
  String get errGeneration => 'Couldn\'t build the plan. Try again.';

  @override
  String errTooEarly(String date) {
    return 'Next week opens $date.';
  }

  @override
  String get errNetwork => 'No connection. Check your internet.';

  @override
  String get readinessOnTrack => 'On track';

  @override
  String get readinessNeedsWork => 'Needs work';

  @override
  String get readinessBigGap => 'Long way to go';

  @override
  String get seeDoctor => 'See a doctor before you start.';

  @override
  String weekOf(int week, int total) {
    return 'Week $week of $total';
  }

  @override
  String get recoveryWeek => 'Recovery week';

  @override
  String weekDone(int done, int total) {
    return '$done of $total sessions done';
  }

  @override
  String generateNextWeek(int week) {
    return 'Build week $week';
  }

  @override
  String nextWeekLocked(int week, String date) {
    return 'Week $week opens $date.';
  }

  @override
  String get planFinished => 'Plan complete. Good luck at the PET.';

  @override
  String get fullPlan => 'Full plan';

  @override
  String get safetyNotes => 'Keep in mind';

  @override
  String get newPlan => 'Build a new plan';

  @override
  String get newPlanConfirm => 'A new plan replaces the current one.';

  @override
  String get cancel => 'Cancel';

  @override
  String get continueLabel => 'Continue';

  @override
  String get sessionToday => 'Today';

  @override
  String get statusDone => 'Done';

  @override
  String get statusPartial => 'Partly';

  @override
  String get statusMissed => 'Missed';

  @override
  String get logSession => 'Log session';

  @override
  String get logDistance => 'Distance run (km)';

  @override
  String get logTime => 'Total time (min:sec)';

  @override
  String get logEffort => 'How hard did it feel? (1 easy – 5 very hard)';

  @override
  String get logPain => 'Felt pain during or after';

  @override
  String get logNote => 'Note (optional)';

  @override
  String get painWarning =>
      'If it hurts, go lighter next session. See a doctor if it gets worse or lasts 2-3 days.';

  @override
  String km(String value) {
    return '$value km';
  }

  @override
  String minutesShort(String value) {
    return '$value min';
  }

  @override
  String pacePerKm(String pace) {
    return '$pace per km';
  }

  @override
  String get typeEasyRun => 'Easy run';

  @override
  String get typeRunWalk => 'Run-walk';

  @override
  String get typeLongRun => 'Long run';

  @override
  String get typeTempo => 'Tempo run';

  @override
  String get typeIntervals => 'Intervals';

  @override
  String get typeTimeTrial => 'Time trial';

  @override
  String get typeStrength => 'Strength';

  @override
  String get typeMobility => 'Mobility';

  @override
  String progressTitle(String distance) {
    return 'Your $distance time';
  }

  @override
  String get progressEmpty => 'No time trials yet. Add your first time.';

  @override
  String get addTrial => 'Add time trial';

  @override
  String get trialDistance => 'Distance (m)';

  @override
  String get trialTime => 'Time (min:sec)';

  @override
  String get trialDate => 'Date';

  @override
  String latestTime(String time) {
    return 'Latest: $time';
  }

  @override
  String targetTime(String time) {
    return 'Target: $time';
  }

  @override
  String gapToCut(String time) {
    return '$time to cut';
  }

  @override
  String underTarget(String time) {
    return '$time inside the target';
  }

  @override
  String get estimated => 'estimated';

  @override
  String estimateNote(String distance) {
    return '$distance time estimated from other distances.';
  }

  @override
  String get trialSaveFailed => 'Couldn\'t save. Try again.';

  @override
  String get runTitle => 'Run';

  @override
  String get mockPetTitle => 'Mock PET';

  @override
  String get freeRunTitle => 'Free run';

  @override
  String mockPetIntro(String distance, String time) {
    return 'A $distance run like the real PET. Target $time.';
  }

  @override
  String get freeRunIntro => 'Record any run with GPS.';

  @override
  String get runTips =>
      'Run in the open with your phone on you. On Xiaomi/Redmi set battery to \'No restrictions\' or GPS may stop.';

  @override
  String get gpsSearching => 'Finding GPS…';

  @override
  String gpsAccuracy(int metres) {
    return 'GPS accuracy: $metres m';
  }

  @override
  String get gpsReady => 'GPS ready';

  @override
  String get gpsDenied => 'Allow location to record runs.';

  @override
  String get gpsOff => 'Turn on location (GPS).';

  @override
  String get openSettings => 'Open settings';

  @override
  String get startRun => 'Start';

  @override
  String get startAnyway => 'Start anyway';

  @override
  String get holdToStop => 'Hold to stop';

  @override
  String get elapsed => 'Time';

  @override
  String get distanceLabel => 'Distance';

  @override
  String get paceLabel => 'Pace';

  @override
  String aheadBy(String time) {
    return '$time ahead of target';
  }

  @override
  String behindBy(String time) {
    return '$time behind target';
  }

  @override
  String remaining(String distance) {
    return '$distance to go';
  }

  @override
  String get trackingNotificationTitle => 'Maidan: recording your run';

  @override
  String get trackingNotificationText => 'Measuring distance and time by GPS';

  @override
  String get resultTitle => 'Result';

  @override
  String get outcomeQualified => 'You\'d qualify!';

  @override
  String get outcomeBorderline => 'Borderline – run a little faster';

  @override
  String get outcomeNotQualified => 'Not qualifying yet';

  @override
  String get outcomeIncomplete => 'Distance not completed';

  @override
  String get borderlineNote =>
      'GPS can be off by 2-3%. Aim to finish 3% inside the target.';

  @override
  String finishTime(String distance, String time) {
    return '$distance time: $time';
  }

  @override
  String targetLine(String time) {
    return 'Target: $time';
  }

  @override
  String marginAhead(String time) {
    return '$time inside the target';
  }

  @override
  String marginBehind(String time) {
    return '$time over the target';
  }

  @override
  String totalDistance(String distance) {
    return 'Total distance: $distance';
  }

  @override
  String totalTime(String time) {
    return 'Total time: $time';
  }

  @override
  String get verdictVerified => 'GPS check: passed';

  @override
  String get verdictSuspicious => 'GPS check: uncertain';

  @override
  String get verdictRejected => 'GPS check: rejected';

  @override
  String get verdictNotCounted =>
      'This run will not count for progress or rankings.';

  @override
  String get flagMock => 'A fake (mock) location was detected.';

  @override
  String get flagTeleport => 'The location jumped a long way at once.';

  @override
  String get flagImpossibleSpeed =>
      'Part of the run was faster than humanly possible.';

  @override
  String get flagVehicle => 'Part of the run was at vehicle or bicycle speed.';

  @override
  String get flagAverage => 'The average speed was not possible on foot.';

  @override
  String get flagPoorSignal => 'The GPS signal was weak.';

  @override
  String get flagGap => 'GPS signal was lost during the run.';

  @override
  String get flagSparse => 'Too few GPS readings were received.';

  @override
  String get flagTooShort => 'The run was too short.';

  @override
  String get uploading => 'Checking…';

  @override
  String get savedOffline =>
      'No internet. Run saved on your phone and sent once you\'re online.';

  @override
  String get uploadRefused =>
      'Server rejected the run (daily limit or bad data).';

  @override
  String get serverChecked => 'Checked by server';

  @override
  String get done => 'Done';

  @override
  String get mockPetCta => 'Run a mock PET';

  @override
  String get recordRun => 'Record a run';

  @override
  String get recentRuns => 'Recent runs';

  @override
  String pendingRuns(int n) {
    return '$n runs waiting to send';
  }

  @override
  String minPerKm(String pace) {
    return '$pace /km';
  }

  @override
  String get tabRanking => 'Rankings';

  @override
  String get areaVisible => 'Show my name in rankings';

  @override
  String get areaVisibleNote => 'First name and surname initial only.';

  @override
  String get metricPet => 'PET time';

  @override
  String get metricDistance => 'Distance this week';

  @override
  String get thisWeek => 'This week';

  @override
  String get lastWeek => 'Last week';

  @override
  String get rankingRules =>
      'Only GPS-verified runs count. Resets every Monday.';

  @override
  String get rankingEmpty => 'No runs yet this week. Be the first.';

  @override
  String get youLabel => 'You';

  @override
  String get errAiBusy => 'Busy right now. Try again in a minute.';

  @override
  String get boardEveryone => 'Everyone';

  @override
  String get communitiesTitle => 'My areas and groups';

  @override
  String get communitiesIntro =>
      'Join your village, ground or a group of friends.';

  @override
  String get manageCommunities => 'Areas / groups';

  @override
  String get searchCommunities => 'Search a village, ground or group';

  @override
  String get noCommunitiesFound => 'Nothing found. Create one.';

  @override
  String get joinLabel => 'Join';

  @override
  String get leaveLabel => 'Leave';

  @override
  String get joinedLabel => 'Joined';

  @override
  String membersCount(int n) {
    return '$n members';
  }

  @override
  String get kindRegion => 'Area';

  @override
  String get kindGroup => 'Group';

  @override
  String get privateLabel => 'Private';

  @override
  String get createCommunity => 'Create new';

  @override
  String get communityName => 'Name';

  @override
  String get communityKindRegion =>
      'Area (village, locality, ground) – open to all';

  @override
  String get communityKindGroup => 'Group (friends, batch, academy)';

  @override
  String get communityPrivate => 'Private – join with the code only';

  @override
  String get createLabel => 'Create';

  @override
  String get joinByCode => 'Join with a code';

  @override
  String get inviteCodeLabel => 'Group code';

  @override
  String inviteCodeShare(String code) {
    return 'Send your friends this code: $code';
  }

  @override
  String get codeCopied => 'Code copied';

  @override
  String get errNameTaken => 'That name exists. Search above and join.';

  @override
  String get errCreateLimit => 'You\'ve made 3 today. Try tomorrow.';

  @override
  String get errMemberLimit =>
      '15 areas/groups is the limit. Leave one to join another.';

  @override
  String get errCodeNotFound => 'That code was not found. Check it again.';

  @override
  String get errCommunity => 'Something went wrong. Try again.';

  @override
  String get noCommunitiesYet =>
      'You\'re not in any area or group yet. See Everyone or add your area.';

  @override
  String get catScSt => 'Scheduled Caste / Tribe (SC/ST)';

  @override
  String get catHillAreas =>
      'Hill areas (Garhwali, Kumaoni, Gorkha etc. – with certificate)';

  @override
  String get catPoliceWard => 'Son/daughter of Delhi Police personnel';

  @override
  String get eventLongJump => 'Long jump';

  @override
  String get eventHighJump => 'High jump';

  @override
  String get eventPullUps => 'Pull-ups (beam)';

  @override
  String get eventDitch => '9 ft ditch jump';

  @override
  String get eventZigzag => 'Zig-zag balance';

  @override
  String get mustPass => 'Must pass';

  @override
  String countAtLeast(int n) {
    return 'At least $n';
  }

  @override
  String standardsForAge(int age) {
    return 'Standards for your age ($age years)';
  }

  @override
  String get examUnconfirmed =>
      'This exam\'s standards aren\'t confirmed yet. Plans, mock PET and rankings open once they are.';

  @override
  String get voiceStarted =>
      'Off we go! Start easy, the first kilometre is a warm-up, not a race.';

  @override
  String voiceKmDone(int km, String time) {
    return '$km kilometre done. Time $time.';
  }

  @override
  String get voiceHalfway => 'Halfway there!';

  @override
  String voiceLastStretch(int metres) {
    return 'Only $metres metres left! Give it everything!';
  }

  @override
  String voiceAhead(int seconds) {
    return '$seconds seconds ahead of target.';
  }

  @override
  String voiceBehind(int seconds) {
    return '$seconds seconds behind target, pick it up!';
  }

  @override
  String get voiceCheer1 => 'Well done, tiger!';

  @override
  String get voiceCheer2 => 'Your legs say stop, your heart says keep going!';

  @override
  String get voiceCheer3 => 'The uniform is waiting for you!';

  @override
  String get voiceCheer4 => 'Watch your breathing, short quick steps.';

  @override
  String get voiceFinished => 'Run complete! Drink water and walk a little.';

  @override
  String voiceTime(int minutes, int seconds) {
    return '$minutes minutes $seconds seconds';
  }

  @override
  String get voiceOn => 'Voice on';

  @override
  String get voiceOff => 'Voice off';

  @override
  String get shareButton => 'Share on WhatsApp';

  @override
  String sharePetText(
    String distance,
    String time,
    String margin,
    String outcome,
  ) {
    return '$distance mock run on Maidan: $time ($margin). $outcome';
  }

  @override
  String shareRankText(String board, int rank, String value) {
    return 'I\'m #$rank on Maidan this week ($board): $value. Beat that.';
  }

  @override
  String streakDays(int n) {
    return '$n-day streak';
  }

  @override
  String get streakStart => 'Run today to start a streak';

  @override
  String streakBest(int n) {
    return 'Longest streak: $n days';
  }

  @override
  String get weekdayInitials => 'M,T,W,T,F,S,S';

  @override
  String get badgesTitle => 'Badges';

  @override
  String get badgeEarlyBird => 'Morning Lion';

  @override
  String get badgeEarlyBirdHint => 'Finish a GPS run between 4 and 7 am';

  @override
  String get badgeComeback => 'Laziness Slayer';

  @override
  String get badgeComebackHint => 'Come back to training after 4+ days off';

  @override
  String get badgeStreak3 => 'Three-Day Storm';

  @override
  String get badgeStreak3Hint => 'Train 3 days in a row';

  @override
  String get badgeStreak7 => 'Hero of the Week';

  @override
  String get badgeStreak7Hint => 'Train 7 days in a row';

  @override
  String get badgeStreak30 => 'Champion of the Month';

  @override
  String get badgeStreak30Hint => 'Train 30 days in a row';

  @override
  String get badgeQualified => 'Almost in Uniform';

  @override
  String get badgeQualifiedHint => 'Finish a mock PET inside the target time';

  @override
  String get badgeKm50 => '50 km Club';

  @override
  String get badgeKm50Hint => 'Run 50 km of verified GPS distance in total';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get lowDataTitle => 'Low-data mode';

  @override
  String get lowDataNote => 'Rankings and fresh stats load only when you ask.';

  @override
  String get lowDataRanking => 'Low-data mode is on.';

  @override
  String get loadRanking => 'Load rankings';

  @override
  String get heatWarning =>
      'Hot hours. Run before 8 am or after 6 pm. Carry water.';

  @override
  String get readMore => 'Read more';

  @override
  String get readLess => 'Show less';

  @override
  String get switchLanguage => 'हिन्दी';

  @override
  String get switchLanguageShort => 'हि';

  @override
  String get featPlan => 'Plan';

  @override
  String get featTrack => 'GPS runs';

  @override
  String get featRank => 'Rankings';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmBody =>
      'Your data stays saved. Sign in again and everything is back.';

  @override
  String weatherFeels(String t) {
    return 'Feels $t°';
  }

  @override
  String weatherHumidity(int n) {
    return 'Humidity $n%';
  }

  @override
  String weatherAqi(int n) {
    return 'AQI $n';
  }

  @override
  String get condClear => 'Clear';

  @override
  String get condClearNight => 'Clear night';

  @override
  String get condCloudy => 'Cloudy';

  @override
  String get condFog => 'Fog';

  @override
  String get condRain => 'Rain';

  @override
  String get condStorm => 'Thunderstorm';

  @override
  String get condOther => 'Weather';

  @override
  String get verdictGood => 'Good conditions to run';

  @override
  String get verdictCaution => 'Run with care';

  @override
  String get verdictAvoid => 'Skip the outdoor run now';

  @override
  String get reasonFine => 'Air and temperature are fine';

  @override
  String get reasonHeat => 'Hot and humid';

  @override
  String get reasonStorm => 'Lightning risk';

  @override
  String get reasonRain => 'Rain, slippery ground';

  @override
  String reasonSmog(int n) {
    return 'Poor air (AQI $n)';
  }

  @override
  String get reasonCold => 'It is cold';

  @override
  String get reasonFog => 'Low visibility in fog';

  @override
  String get reasonSun => 'Strong sun (high UV)';

  @override
  String get tipWater => 'Carry water';

  @override
  String get tipOrs => 'ORS or lemon water';

  @override
  String get tipCap => 'Wear a cap';

  @override
  String get tipLight => 'Light cotton clothes';

  @override
  String get tipWarm => 'Warm layer on top';

  @override
  String get tipWarmup => 'Warm up longer';

  @override
  String get tipGrip => 'Shoes with grip';

  @override
  String get tipBright => 'Wear bright clothes';

  @override
  String get tipEasy => 'Keep it easy';

  @override
  String get tipIndoors => 'Train indoors instead';

  @override
  String get bestNow => 'Now is about the best time';

  @override
  String bestAt(String day, String time) {
    return 'Best time: $day $time';
  }

  @override
  String get dayToday => 'today';

  @override
  String get dayTomorrow => 'tomorrow';

  @override
  String hourMorning(int h) {
    return '$h am';
  }

  @override
  String hourDay(int h) {
    return '$h pm';
  }

  @override
  String hourEvening(int h) {
    return '$h pm';
  }

  @override
  String get weatherAsk => 'See the weather where you are';

  @override
  String get weatherAllow => 'Show weather';

  @override
  String get weatherFailed => 'Couldn\'t get the weather';

  @override
  String get weatherLoad => 'Load weather';

  @override
  String get demoTitle => 'Demo data (for pitch)';

  @override
  String get demoNote =>
      'Shows sample rankings, plan, progress and runs. Your real data is untouched.';

  @override
  String get demoBadge => 'Demo data';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteTitle => 'Delete your account for good?';

  @override
  String get deleteBody =>
      'Your profile, plans, runs and rankings are erased. This cannot be undone.';

  @override
  String get deleteConfirm => 'Delete for good';

  @override
  String get deleteFailed =>
      'Couldn\'t delete the account. Check your internet and try again.';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutIndependentTitle => 'Independent app';

  @override
  String get aboutIndependent =>
      'Maidan is not connected to any government department or recruitment board. Always check the official notice before you apply.';

  @override
  String get aboutSourcesTitle => 'Where the standards come from';

  @override
  String get aboutSources =>
      'Every standard is read from the official recruitment notice, with page and paragraph. Anything unconfirmed shows as \'Not yet confirmed\'.';

  @override
  String get aboutDataTitle => 'Your data';

  @override
  String get aboutData =>
      'Name, date of birth, gender, category, your runs (GPS routes), plans and logs. Weather uses a rough location that is not saved. Deleting your account erases it all.';

  @override
  String get aboutSafetyTitle => 'Health';

  @override
  String get aboutSafety =>
      'Plans and weather tips are general guidance, not medical advice. See a doctor if you have pain or a health condition.';
}
