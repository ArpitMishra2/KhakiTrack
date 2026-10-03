import 'dart:math';

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Fades and lifts its child into place once. [index] staggers a list: later
/// items start a little after earlier ones. Finite and timer-free, so tests
/// can settle.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    final int delay = 70 * min<int>(widget.index, 8);
    final total = 380 + delay;
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    );
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _t,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(_t),
        child: widget.child,
      ),
    );
  }
}

/// Pops its child in with a springy scale, once.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 750),
      curve: Curves.elasticOut,
      builder: (_, v, c) => Transform.scale(scale: v, child: c),
      child: child,
    );
  }
}

/// Confetti that rains down once, over whatever it is stacked on.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(_c),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t) : super(repaint: t);

  final Animation<double> t;

  static const _colors = [
    Brand.saffron,
    Brand.khaki,
    Colors.white,
    Brand.good,
    Color(0xFFFFC857),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(7);
    final p = t.value;
    for (var i = 0; i < 80; i++) {
      final x0 = size.width * (0.1 + 0.8 * rnd.nextDouble());
      final drift = (rnd.nextDouble() - 0.5) * size.width * 0.5;
      final speed = 0.7 + rnd.nextDouble() * 0.6;
      final spin = rnd.nextDouble() * 8;
      final w = 6.0 + rnd.nextDouble() * 6;
      final color = _colors[i % _colors.length];
      // Burst up a little, then fall.
      final q = (p * speed).clamp(0.0, 1.0);
      final y =
          -20 +
          size.height * 0.2 * sin(q * pi * 0.5) +
          size.height * 0.9 * q * q;
      final x = x0 + drift * q;
      final fade = p < 0.8 ? 1.0 : (1 - (p - 0.8) / 0.2);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(spin * p)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: w * 0.5),
            const Radius.circular(2),
          ),
          Paint()..color = color.withValues(alpha: fade.clamp(0.0, 1.0)),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}

/// Three soft rings expanding from a dot, like a GPS ping. Plays once.
class PingDot extends StatefulWidget {
  const PingDot({super.key, required this.child, this.active = true});

  final Widget child;
  final bool active;

  @override
  State<PingDot> createState() => _PingDotState();
}

class _PingDotState extends State<PingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.forward();
  }

  @override
  void didUpdateWidget(PingDot old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PingPainter(_c, Brand.saffron),
      child: widget.child,
    );
  }
}

class _PingPainter extends CustomPainter {
  _PingPainter(this.t, this.color) : super(repaint: t);

  final Animation<double> t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var k = 0; k < 3; k++) {
      final local = ((t.value * 3) - k).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      canvas.drawCircle(
        c,
        size.shortestSide / 2 + local * 22,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = color.withValues(alpha: (1 - local) * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(_PingPainter old) => false;
}
