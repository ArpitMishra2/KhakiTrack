import 'package:flutter_tts/flutter_tts.dart';

/// Speaks short updates during a run, so the phone can stay in a pocket.
abstract class VoiceCoach {
  Future<void> say(String text);
  Future<void> stop();
}

class TtsVoiceCoach implements VoiceCoach {
  TtsVoiceCoach(this.languageCode);

  final String languageCode;
  final _tts = FlutterTts();
  Future<void>? _ready;

  Future<void> _setUp() async {
    final preferred = languageCode == 'hi' ? 'hi-IN' : 'en-IN';
    final ok = await _tts.isLanguageAvailable(preferred);
    await _tts.setLanguage(ok == true ? preferred : 'en-IN');
    await _tts.setSpeechRate(0.5);
    await _tts.setQueueMode(1); // queue, never cut off the previous line
  }

  @override
  Future<void> say(String text) async {
    await (_ready ??= _setUp());
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async => _tts.stop();
}

/// Words the announcer needs, so it stays testable without localisation.
class CoachPhrases {
  const CoachPhrases({
    required this.started,
    required this.kmDone,
    required this.halfway,
    required this.lastStretch,
    required this.ahead,
    required this.behind,
    required this.cheers,
    required this.finished,
  });

  final String started;

  /// (km, "m min s sec") -> sentence.
  final String Function(int km, String time) kmDone;
  final String halfway;

  /// metres left -> sentence.
  final String Function(int metres) lastStretch;

  /// seconds -> "x seconds ahead of target".
  final String Function(int seconds) ahead;
  final String Function(int seconds) behind;
  final List<String> cheers;
  final String finished;
}

/// Decides what to say as a run progresses. Pure: feed it numbers, it
/// returns the lines to speak (each milestone once).
class Announcer {
  Announcer({required this.phrases, this.targetM, this.targetSeconds});

  final CoachPhrases phrases;
  final int? targetM;
  final num? targetSeconds;

  bool _started = false;
  int _lastKm = 0;
  bool _halfway = false;
  bool _lastStretch = false;
  int _cheer = 0;

  static String spokenTime(double seconds, String Function(int m, int s) f) {
    final t = seconds.round();
    return f(t ~/ 60, t % 60);
  }

  String? _pace(double distanceM, double elapsedS) {
    final tm = targetM, ts = targetSeconds;
    if (tm == null || ts == null || distanceM < 100) return null;
    final delta = (distanceM / tm * ts - elapsedS).round();
    if (delta.abs() < 3) return null;
    return delta > 0 ? phrases.ahead(delta) : phrases.behind(-delta);
  }

  /// Lines to say now, given progress so far. [time] formats seconds.
  List<String> update(
    double distanceM,
    double elapsedS,
    String Function(double seconds) time,
  ) {
    final out = <String>[];
    if (!_started) {
      _started = true;
      out.add(phrases.started);
    }
    final km = distanceM ~/ 1000;
    if (km > _lastKm) {
      _lastKm = km;
      final line = StringBuffer(phrases.kmDone(km, time(elapsedS)));
      final pace = _pace(distanceM, elapsedS);
      if (pace != null) line.write(' $pace');
      if (phrases.cheers.isNotEmpty) {
        line.write(' ${phrases.cheers[_cheer++ % phrases.cheers.length]}');
      }
      out.add(line.toString());
    }
    final tm = targetM;
    if (tm != null) {
      if (!_halfway && distanceM >= tm / 2 && tm >= 1500) {
        _halfway = true;
        final pace = _pace(distanceM, elapsedS);
        out.add(pace == null ? phrases.halfway : '${phrases.halfway} $pace');
      }
      if (!_lastStretch && distanceM >= tm - 200 && distanceM < tm) {
        _lastStretch = true;
        out.add(phrases.lastStretch((tm - distanceM).round()));
      }
    }
    return out;
  }
}
