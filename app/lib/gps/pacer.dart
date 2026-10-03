import 'package:vibration/vibration.dart';

/// Buzzes the phone, so a runner with it in a pocket feels the warning.
abstract class Buzzer {
  Future<void> buzz();
}

class PhoneBuzzer implements Buzzer {
  @override
  Future<void> buzz() async {
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(pattern: [0, 350, 150, 350]);
      }
    } on Object {
      // No vibration motor or the plugin failed: the voice still speaks.
    }
  }
}

/// Decides when to buzz during a mock PET: whenever the runner is more than
/// [behindSeconds] behind the pace the target needs, at most once per
/// [cooldownSeconds]. Pure: feed it distance and time.
class Pacer {
  Pacer({
    required this.targetM,
    required this.targetSeconds,
    this.behindSeconds = 15,
    this.cooldownSeconds = 45,
    this.minDistanceM = 200,
  });

  final int targetM;
  final num targetSeconds;
  final int behindSeconds;
  final int cooldownSeconds;
  final double minDistanceM;

  double? _lastBuzzAt;

  bool shouldBuzz(double distanceM, double elapsedS) {
    if (distanceM < minDistanceM || distanceM >= targetM) return false;
    final behind = elapsedS - distanceM / targetM * targetSeconds;
    if (behind <= behindSeconds) return false;
    final last = _lastBuzzAt;
    if (last != null && elapsedS - last < cooldownSeconds) return false;
    _lastBuzzAt = elapsedS;
    return true;
  }
}
