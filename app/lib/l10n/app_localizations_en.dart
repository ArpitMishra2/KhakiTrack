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

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get signInFailed =>
      'Could not sign in. Check your internet and try again.';

  @override
  String get adultsOnly => 'This app is only for people aged 18 or over.';

  @override
  String get signOut => 'Sign out';

  @override
  String get profileTitle => 'About you';

  @override
  String get profileIntro =>
      'We need this to show your exact physical standards.';

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
  String get saveFailed => 'Could not save. Check your internet and try again.';

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
      'Answer a few questions. AI builds a week-by-week plan from your current level, time and experience, so that by PET day you finish the run comfortably in time.';

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
  String get qWeeksUnknown => 'If the date is not announced, choose 12 weeks.';

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
  String get generatingTitle => 'AI is building your plan';

  @override
  String get generatingBody =>
      'This can take 1-2 minutes. Please keep the app open.';

  @override
  String get errRateLimited =>
      'You have reached today\'s limit for building plans. Try again tomorrow.';

  @override
  String get errAiNotConfigured =>
      'AI plans are not switched on yet. Try again later.';

  @override
  String get errGeneration => 'Could not build the plan. Please try again.';

  @override
  String errTooEarly(String date) {
    return 'The next week opens on $date.';
  }

  @override
  String get errNetwork =>
      'Could not connect. Check your internet and try again.';

  @override
  String get readinessOnTrack => 'On track';

  @override
  String get readinessNeedsWork => 'Needs work';

  @override
  String get readinessBigGap => 'Long way to go';

  @override
  String get seeDoctor => 'Please see a doctor before you start.';

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
    return 'Week $week opens on $date, so it can adapt to this week\'s training.';
  }

  @override
  String get planFinished => 'Plan complete. Best of luck at the PET!';

  @override
  String get fullPlan => 'Full plan';

  @override
  String get safetyNotes => 'Keep in mind';

  @override
  String get newPlan => 'Build a new plan';

  @override
  String get newPlanConfirm =>
      'Building a new plan closes the current one. Continue?';

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
      'If it hurts, go easier next time. If pain gets worse or lasts 2-3 days, see a doctor.';

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
  String get progressEmpty =>
      'No time trials yet. Record your time to see your progress here.';

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
    return '$time still to cut';
  }

  @override
  String underTarget(String time) {
    return 'You are $time inside the target. Keep it up!';
  }

  @override
  String get estimated => 'estimated';

  @override
  String estimateNote(String distance) {
    return 'Trials over other distances are converted to an estimated $distance time.';
  }

  @override
  String get trialSaveFailed => 'Could not save. Try again.';

  @override
  String get runTitle => 'Run';

  @override
  String get mockPetTitle => 'Mock PET';

  @override
  String get freeRunTitle => 'Free run';

  @override
  String mockPetIntro(String distance, String time) {
    return 'Run $distance like the real PET. The app times you by GPS and tells you whether you would qualify within $time.';
  }

  @override
  String get freeRunIntro => 'Record any run with GPS.';

  @override
  String get runTips =>
      'Run in the open with the phone in your pocket or hand. On Xiaomi/Redmi phones set the app\'s battery saver to \'No restrictions\' so GPS keeps running with the screen off.';

  @override
  String get gpsSearching => 'Looking for GPS signal…';

  @override
  String gpsAccuracy(int metres) {
    return 'GPS accuracy: $metres m';
  }

  @override
  String get gpsReady => 'GPS ready';

  @override
  String get gpsDenied => 'Location permission is needed to record runs.';

  @override
  String get gpsOff => 'Turn on your phone\'s location (GPS).';

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
  String get outcomeQualified => 'You would qualify!';

  @override
  String get outcomeBorderline => 'Borderline – run a little faster';

  @override
  String get outcomeNotQualified => 'Not qualifying yet';

  @override
  String get outcomeIncomplete => 'Distance not completed';

  @override
  String get borderlineNote =>
      'GPS can be off by 2-3%. To be sure, finish at least 3% inside the target.';

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
  String get uploading => 'Checking on the server…';

  @override
  String get savedOffline =>
      'No internet. The run is saved on the phone and will be sent when you are online.';

  @override
  String get uploadRefused =>
      'The server did not accept this run (daily limit or bad data).';

  @override
  String get serverChecked => 'Checked by the server';

  @override
  String get done => 'Done';

  @override
  String get mockPetCta => 'Run a mock PET';

  @override
  String get recordRun => 'Record a run';

  @override
  String get recentRuns => 'Recent GPS runs';

  @override
  String pendingRuns(int n) {
    return '$n runs waiting to upload';
  }

  @override
  String minPerKm(String pace) {
    return '$pace /km';
  }
}
