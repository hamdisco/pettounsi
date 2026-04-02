import 'dart:math';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class AnimatedPawsBackground extends StatefulWidget {
  const AnimatedPawsBackground({super.key, required this.child});
  final Widget child;

  @override
  State<AnimatedPawsBackground> createState() => _AnimatedPawsBackgroundState();
}

class _AnimatedPawsBackgroundState extends State<AnimatedPawsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 14))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return CustomPaint(
          painter: _PawPainter(t: _c.value),
          child: widget.child,
        );
      },
    );
  }
}

class _PawPainter extends CustomPainter {
  _PawPainter({required this.t});
  final double t;

  final _rng = Random(11);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Soft gradient base
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFBFD), AppTheme.bg, Color(0xFFF8FCFF)],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    _blob(
      canvas,
      rect,
      Offset(size.width * 0.18, size.height * 0.10),
      size.width * 0.34,
      AppTheme.blush.withAlpha(140),
    );
    _blob(
      canvas,
      rect,
      Offset(size.width * 0.86, size.height * 0.16),
      size.width * 0.25,
      AppTheme.lilac.withAlpha(135),
    );
    _blob(
      canvas,
      rect,
      Offset(size.width * 0.70, size.height * 0.86),
      size.width * 0.32,
      AppTheme.mint.withAlpha(125),
    );
    _blob(
      canvas,
      rect,
      Offset(size.width * (0.48 + sin(t * 2 * pi) * 0.03), size.height * 0.18),
      size.width * 0.42,
      AppTheme.softOrange.withAlpha(90),
    );

    // Floating subtle paws
    final pawPaint = Paint()..color = AppTheme.orange.withAlpha(10);

    for (int i = 0; i < 16; i++) {
      final x = (_rng.nextDouble() * size.width);
      final baseY = (_rng.nextDouble() * size.height);
      final phase = i * 0.55;
      final y =
          (baseY + sin((t * 2 * pi) + phase) * (10 + i % 4 * 3)) % size.height;

      final s = 9 + _rng.nextDouble() * 12;
      _drawPaw(canvas, Offset(x, y), s, pawPaint);
    }

    // Tiny sparkles
    final sparkle = Paint()..color = Colors.white.withAlpha(80);
    for (int i = 0; i < 10; i++) {
      final x = (_rng.nextDouble() * size.width);
      final y =
          ((_rng.nextDouble() * size.height) + t * 22 + i * 17) % size.height;
      canvas.drawCircle(Offset(x, y), 1.4 + (i % 3) * 0.3, sparkle);
    }
  }

  void _blob(
    Canvas canvas,
    Rect rect,
    Offset center,
    double radius,
    Color color,
  ) {
    final p = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withAlpha(0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(rect, p);
  }

  void _drawPaw(Canvas canvas, Offset c, double s, Paint paint) {
    canvas.drawOval(
      Rect.fromCenter(center: c, width: s * 1.2, height: s),
      paint,
    );
    canvas.drawCircle(c + Offset(-s * 0.5, -s * 0.75), s * 0.28, paint);
    canvas.drawCircle(c + Offset(0, -s * 0.9), s * 0.28, paint);
    canvas.drawCircle(c + Offset(s * 0.5, -s * 0.75), s * 0.28, paint);
  }

  @override
  bool shouldRepaint(covariant _PawPainter oldDelegate) => oldDelegate.t != t;
}
