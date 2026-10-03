import 'dart:math';

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// A sunrise over a running track, drawn in code (no image files, so it adds
/// nothing to the download). The sun climbs, a runner jogs in along the
/// lanes. Plays once, about two seconds.
class SunriseScene extends StatefulWidget {
  const SunriseScene({super.key, this.height = 260, this.runner = true});

  final double height;
  final bool runner;

  @override
  State<SunriseScene> createState() => _SunriseSceneState();
}

class _SunriseSceneState extends State<SunriseScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: CustomPaint(painter: _SunrisePainter(_c, widget.runner)),
    );
  }
}

class _SunrisePainter extends CustomPainter {
  _SunrisePainter(this.t, this.runner) : super(repaint: t);

  final Animation<double> t;
  final bool runner;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final horizon = h * 0.58;
    final rise = Curves.easeOutCubic.transform(min(1, t.value / 0.8));

    // Sky.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Brand.oliveDeep, Brand.olive, Color(0xFF8A6A2A)],
          stops: [0, 0.55, 1],
        ).createShader(Offset.zero & size),
    );

    // Sun and glow.
    final sun = Offset(w * 0.5, horizon + 70 - rise * 120);
    canvas.drawCircle(
      sun,
      170,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Brand.saffron.withValues(alpha: 0.55 * rise),
            Brand.saffron.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: sun, radius: 170)),
    );
    canvas.drawCircle(sun, 44, Paint()..color = Brand.saffron);

    // Hills.
    Path hill(double base, double amp, double phase) {
      final p = Path()..moveTo(0, h);
      for (double x = 0; x <= w; x += 6) {
        p.lineTo(
          x,
          base -
              amp * sin(x / w * pi * 2 + phase) -
              amp * 0.4 * sin(x / w * pi * 5 + phase),
        );
      }
      return p
        ..lineTo(w, h)
        ..close();
    }

    canvas.drawPath(
      hill(horizon - 4, 16, 0.6),
      Paint()..color = const Color(0xFF2F3819),
    );
    canvas.drawPath(
      hill(horizon + 8, 10, 2.2),
      Paint()..color = Brand.oliveDeep,
    );

    // Track: lanes converging on the horizon.
    final vp = Offset(w * 0.5, horizon + 6);
    final track = Path()
      ..moveTo(vp.dx - 8, vp.dy)
      ..lineTo(vp.dx + 8, vp.dy)
      ..lineTo(w * 0.98, h)
      ..lineTo(w * 0.02, h)
      ..close();
    canvas.drawPath(
      track,
      Paint()..color = Brand.khaki.withValues(alpha: 0.28),
    );
    final lane = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 2;
    for (final f in [0.02, 0.26, 0.5, 0.74, 0.98]) {
      canvas.drawLine(
        Offset(vp.dx + (f - 0.5) * 16, vp.dy),
        Offset(w * f, h),
        lane,
      );
    }

    // Runner jogging in along the middle lane.
    if (runner) {
      final p = Curves.easeOutCubic.transform(
        ((t.value - 0.25) / 0.75).clamp(0.0, 1.0),
      );
      final bob = sin(t.value * pi * 10) * 3 * (1 - p);
      final x = -60 + (w * 0.5 - 14) * p;
      final icon = Icons.directions_run;
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            fontSize: 72,
            color: Colors.white.withValues(alpha: p),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2 + 36, h - tp.height - 8 + bob));
    }
  }

  @override
  bool shouldRepaint(_SunrisePainter old) => false;
}
