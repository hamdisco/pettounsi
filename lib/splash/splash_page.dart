import 'package:flutter/material.dart';
import '../ui/app_theme.dart';
import '../ui/brand_widgets.dart';
import '../auth/auth_gate.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.autoNavigate = true,
    this.duration = const Duration(milliseconds: 1400),
  });

  static const String route = "/splash";

  /// When true, the splash moves to [AuthGate.route] after [duration].
  ///
  /// The bootstrap app uses the same splash with [autoNavigate] set to false
  /// so the user sees the real branded splash while Firebase initializes,
  /// without trying to navigate before the main route table is ready.
  final bool autoNavigate;
  final Duration duration;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);

    _c.forward();

    if (widget.autoNavigate) {
      Future.delayed(widget.duration, () {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AuthGate.route);
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.orangeDark, AppTheme.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 128),
                  const SizedBox(height: 10),
                  Text(
                    'Powered by M.E.R.I.T',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "PetTounsi",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
