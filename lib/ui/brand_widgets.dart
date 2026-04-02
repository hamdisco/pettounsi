import 'dart:math';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.heroTag});
  final double size;

  /// Optional: if provided, the logo is wrapped with Hero
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.softOrange, AppTheme.blush],
        ),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.6),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.pets_rounded,
        size: size * 0.52,
        color: AppTheme.orangeDark,
      ),
    );

    final img = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        "assets/logo.png",
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );

    if (heroTag == null || heroTag!.isEmpty) return img;
    return Hero(tag: heroTag!, child: img);
  }
}

class BrandAuthBackground extends StatefulWidget {
  const BrandAuthBackground({super.key, required this.child});
  final Widget child;

  @override
  State<BrandAuthBackground> createState() => _BrandAuthBackgroundState();
}

class _BrandAuthBackgroundState extends State<BrandAuthBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 12))
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
        final t = _c.value;
        final dx = (sin(t * pi * 2) * 0.18);
        final dy = (cos(t * pi * 2) * 0.10);

        return Stack(
          children: [
            Container(color: AppTheme.bg),
            Positioned.fill(
              child: CustomPaint(
                painter: _GlowPainter(dx: dx, dy: dy, t: t),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.dx, required this.dy, required this.t});
  final double dx;
  final double dy;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF8FB), AppTheme.bg, Color(0xFFF7FBFF)],
      ).createShader(rect);

    canvas.drawRect(rect, base);

    final blobs = <_Blob>[
      _Blob(
        center: Offset(size.width * (0.16 + dx * 0.45), size.height * 0.15),
        radius: size.width * 0.28,
        color: AppTheme.blush.withAlpha(180),
      ),
      _Blob(
        center: Offset(size.width * 0.86, size.height * (0.13 + dy * 0.35)),
        radius: size.width * 0.22,
        color: AppTheme.lilac.withAlpha(175),
      ),
      _Blob(
        center: Offset(size.width * 0.55, size.height * (0.86 - dy * 0.35)),
        radius: size.width * 0.30,
        color: AppTheme.mint.withAlpha(165),
      ),
      _Blob(
        center: Offset(size.width * (0.42 - dx * 0.30), size.height * 0.28),
        radius: size.width * 0.38,
        color: AppTheme.softOrange.withAlpha(120),
      ),
    ];

    for (final b in blobs) {
      final p = Paint()
        ..shader = RadialGradient(
          colors: [b.color, b.color.withAlpha(0)],
        ).createShader(Rect.fromCircle(center: b.center, radius: b.radius));
      canvas.drawCircle(b.center, b.radius, p);
    }

    _drawMiniPaws(canvas, size, t);
  }

  void _drawMiniPaws(Canvas canvas, Size size, double t) {
    final pawPaint = Paint()
      ..color = AppTheme.orange.withAlpha(18)
      ..style = PaintingStyle.fill;

    final points = [
      Offset(size.width * 0.10, size.height * (0.25 + sin(t * 2 * pi) * 0.01)),
      Offset(size.width * 0.84, size.height * (0.30 + cos(t * 2 * pi) * 0.01)),
      Offset(size.width * 0.17, size.height * 0.70),
      Offset(size.width * 0.76, size.height * 0.78),
    ];

    for (int i = 0; i < points.length; i++) {
      final s = 10.0 + (i % 2) * 3.0;
      _drawPaw(canvas, points[i], s, pawPaint);
    }
  }

  void _drawPaw(Canvas canvas, Offset c, double s, Paint paint) {
    canvas.drawOval(
      Rect.fromCenter(center: c, width: s * 1.25, height: s),
      paint,
    );
    canvas.drawCircle(c + Offset(-s * 0.52, -s * 0.78), s * 0.25, paint);
    canvas.drawCircle(c + Offset(0, -s * 0.92), s * 0.25, paint);
    canvas.drawCircle(c + Offset(s * 0.52, -s * 0.78), s * 0.25, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) {
    return oldDelegate.dx != dx || oldDelegate.dy != dy || oldDelegate.t != t;
  }
}

class _Blob {
  const _Blob({
    required this.center,
    required this.radius,
    required this.color,
  });

  final Offset center;
  final double radius;
  final Color color;
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.7),
      ),
      child: child,
    );

    if (margin == null) return card;
    return Padding(padding: margin!, child: card);
  }
}
