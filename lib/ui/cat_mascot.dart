import 'dart:math';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class CatMascot extends StatefulWidget {
  const CatMascot({
    super.key,
    required this.look, // -1..1
    required this.eyesClosed,
  });

  final double look;
  final bool eyesClosed;

  @override
  State<CatMascot> createState() => _CatMascotState();
}

class _CatMascotState extends State<CatMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _bob;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _bob = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = widget.look.clamp(-1.0, 1.0);

    return AnimatedBuilder(
      animation: _bob,
      builder: (_, __) {
        final dy = (sin(_bob.value * pi) * 4);
        final tilt = look * 0.08;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: tilt,
            child: SizedBox(
              width: 150,
              height: 128,
              child: CustomPaint(
                painter: _CatPainter(
                  look: look,
                  eyesClosed: widget.eyesClosed,
                  blinkT: _bob.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CatPainter extends CustomPainter {
  _CatPainter({
    required this.look,
    required this.eyesClosed,
    required this.blinkT,
  });

  final double look;
  final bool eyesClosed;
  final double blinkT;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 6);

    final headPaint = Paint()..color = AppTheme.orange.withAlpha(245);
    final earPaint = Paint()..color = AppTheme.orangeDark;
    final snoutPaint = Paint()..color = const Color(0xFFFFF3E6);

    final linePaint = Paint()
      ..color = Colors.black.withAlpha(170)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, 46, headPaint);

    final leftEar = Path()
      ..moveTo(center.dx - 30, center.dy - 28)
      ..lineTo(center.dx - 50, center.dy - 60)
      ..lineTo(center.dx - 10, center.dy - 54)
      ..close();
    final rightEar = Path()
      ..moveTo(center.dx + 30, center.dy - 28)
      ..lineTo(center.dx + 50, center.dy - 60)
      ..lineTo(center.dx + 10, center.dy - 54)
      ..close();

    canvas.drawPath(leftEar, earPaint);
    canvas.drawPath(rightEar, earPaint);

    final snout = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center + const Offset(0, 12),
        width: 70,
        height: 44,
      ),
      const Radius.circular(22),
    );
    canvas.drawRRect(snout, snoutPaint);

    final nose = Path()
      ..moveTo(center.dx, center.dy + 8)
      ..lineTo(center.dx - 6, center.dy + 16)
      ..lineTo(center.dx + 6, center.dy + 16)
      ..close();
    canvas.drawPath(nose, Paint()..color = Colors.black.withAlpha(170));

    // whiskers
    final whisk = Paint()
      ..color = Colors.black.withAlpha(150)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center + const Offset(-10, 26),
      center + const Offset(-46, 20),
      whisk,
    );
    canvas.drawLine(
      center + const Offset(-10, 30),
      center + const Offset(-48, 34),
      whisk,
    );
    canvas.drawLine(
      center + const Offset(10, 26),
      center + const Offset(46, 20),
      whisk,
    );
    canvas.drawLine(
      center + const Offset(10, 30),
      center + const Offset(48, 34),
      whisk,
    );

    final leftEyeCenter = center + const Offset(-18, -8);
    final rightEyeCenter = center + const Offset(18, -8);

    final blink = (sin(blinkT * pi) * 0.06).abs();
    final eyeOpen = (1.0 - blink).clamp(0.82, 1.0);

    if (eyesClosed) {
      canvas.drawLine(
        leftEyeCenter + const Offset(-10, 0),
        leftEyeCenter + const Offset(10, 0),
        linePaint,
      );
      canvas.drawLine(
        rightEyeCenter + const Offset(-10, 0),
        rightEyeCenter + const Offset(10, 0),
        linePaint,
      );
    } else {
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawOval(
        Rect.fromCenter(center: leftEyeCenter, width: 24, height: 18 * eyeOpen),
        whitePaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: rightEyeCenter,
          width: 24,
          height: 18 * eyeOpen,
        ),
        whitePaint,
      );

      final pupilDx = look * 6;
      final pupilPaint = Paint()..color = Colors.black.withAlpha(190);
      canvas.drawCircle(leftEyeCenter + Offset(pupilDx, 0), 5.2, pupilPaint);
      canvas.drawCircle(rightEyeCenter + Offset(pupilDx, 0), 5.2, pupilPaint);

      final hPaint = Paint()..color = Colors.white.withAlpha(220);
      canvas.drawCircle(leftEyeCenter + Offset(pupilDx - 2, -2), 1.6, hPaint);
      canvas.drawCircle(rightEyeCenter + Offset(pupilDx - 2, -2), 1.6, hPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CatPainter old) {
    return old.look != look ||
        old.eyesClosed != eyesClosed ||
        old.blinkT != blinkT;
  }
}
