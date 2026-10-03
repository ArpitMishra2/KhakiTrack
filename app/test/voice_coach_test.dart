import 'package:flutter_test/flutter_test.dart';
import 'package:maidan/gps/voice_coach.dart';

void main() {
  final phrases = CoachPhrases(
    started: 'start',
    kmDone: (km, t) => 'km$km $t',
    halfway: 'half',
    lastStretch: (m) => 'last$m',
    ahead: (s) => 'ahead$s',
    behind: (s) => 'behind$s',
    cheers: const ['c1', 'c2'],
    finished: 'done',
  );
  String t(double s) => '${s.round()}s';

  test('each milestone is announced once', () {
    final a = Announcer(phrases: phrases, targetM: 1600, targetSeconds: 480);
    expect(a.update(10, 3, t), ['start']);
    expect(a.update(500, 150, t), isEmpty);
    // 800 m at 230 s: even pace would be 240 s, so 10 s ahead.
    expect(a.update(800, 230, t), ['half ahead10']);
    expect(a.update(900, 260, t), isEmpty);
    // 1000 m at 310 s: even pace 300 s, 10 s behind.
    expect(a.update(1000, 310, t), ['km1 310s behind10 c1']);
    expect(a.update(1450, 450, t), ['last150']);
    expect(a.update(1500, 470, t), isEmpty);
  });

  test('no halfway call for short targets, no pace without a target', () {
    final short = Announcer(phrases: phrases, targetM: 800, targetSeconds: 300);
    short.update(0, 0, t);
    expect(short.update(450, 160, t), isEmpty);
    final free = Announcer(phrases: phrases);
    free.update(0, 0, t);
    expect(free.update(1000, 330, t), ['km1 330s c1']);
    expect(free.update(2000, 660, t), ['km2 660s c2']);
    expect(free.update(3000, 990, t), ['km3 990s c1']);
  });

  test('spoken time', () {
    expect(
      Announcer.spokenTime(310.4, (m, s) => '$m min $s sec'),
      '5 min 10 sec',
    );
  });
}
