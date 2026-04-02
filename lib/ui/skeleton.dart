import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Lightweight skeletons for loading states (no plugins).
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({
    super.key,
    required this.child,
    this.minOpacity = 0.45,
    this.maxOpacity = 0.78,
    this.period = const Duration(milliseconds: 1200),
  });

  final Widget child;
  final double minOpacity;
  final double maxOpacity;
  final Duration period;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat(reverse: true);

  late final Animation<double> _a = Tween<double>(
    begin: widget.minOpacity,
    end: widget.maxOpacity,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) => Opacity(opacity: _a.value, child: child),
      child: widget.child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height, this.radius = 14});

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.outline.withAlpha(170),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.outline.withAlpha(170),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A feed-style skeleton card that matches the post layout.
/// Use it when the feed/profile posts are still loading.
class SkeletonPostCard extends StatelessWidget {
  const SkeletonPostCard({super.key, this.showImage = true});

  final bool showImage;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.outline),
          boxShadow: AppTheme.softShadows(0.14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  SkeletonCircle(size: 40),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 138, height: 12, radius: 10),
                        SizedBox(height: 8),
                        SkeletonBox(width: 110, height: 10, radius: 10),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  SkeletonCircle(size: 28),
                ],
              ),
              const SizedBox(height: 12),
              const SkeletonBox(width: double.infinity, height: 12, radius: 10),
              const SizedBox(height: 8),
              const SkeletonBox(width: 240, height: 12, radius: 10),
              if (showImage) ...[
                const SizedBox(height: 12),
                const SkeletonBox(
                  width: double.infinity,
                  height: 226,
                  radius: 24,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: const [
                  SkeletonBox(width: 108, height: 28, radius: 999),
                  SizedBox(width: 8),
                  SkeletonBox(width: 96, height: 28, radius: 999),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(child: SkeletonBox(height: 50, radius: 18)),
                  SizedBox(width: 8),
                  Expanded(child: SkeletonBox(height: 50, radius: 18)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
