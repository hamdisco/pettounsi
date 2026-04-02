import 'package:flutter/material.dart';

import 'app_theme.dart';

class PremiumEmptyStateCard extends StatelessWidget {
  const PremiumEmptyStateCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.primaryLabel,
    this.primaryIcon,
    this.onPrimary,
    this.secondaryLabel,
    this.secondaryIcon,
    this.onSecondary,
    this.compact = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;

  final String? primaryLabel;
  final IconData? primaryIcon;
  final VoidCallback? onPrimary;

  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondary;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasPrimary =
        primaryLabel != null &&
        primaryLabel!.trim().isNotEmpty &&
        onPrimary != null;

    final hasSecondary =
        secondaryLabel != null &&
        secondaryLabel!.trim().isNotEmpty &&
        onSecondary != null;

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 22 : 26),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 58 : 64,
            height: compact ? 58 : 64,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(compact ? 18 : 20),
              border: Border.all(color: Colors.white),
            ),
            child: Icon(icon, color: iconColor, size: compact ? 28 : 30),
          ),
          SizedBox(height: compact ? 12 : 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 15 : 16,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.muted.withAlpha(220),
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12.2 : 12.6,
              height: 1.22,
            ),
          ),
          if (hasPrimary || hasSecondary) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (hasSecondary)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSecondary,
                      icon: Icon(secondaryIcon ?? Icons.tune_rounded, size: 18),
                      label: Text(secondaryLabel!),
                    ),
                  ),
                if (hasPrimary && hasSecondary) const SizedBox(width: 10),
                if (hasPrimary)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onPrimary,
                      icon: Icon(
                        primaryIcon ?? Icons.refresh_rounded,
                        size: 18,
                      ),
                      label: Text(primaryLabel!),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class PremiumMiniEmptyCard extends StatelessWidget {
  const PremiumMiniEmptyCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return PremiumEmptyStateCard(
      icon: icon,
      iconColor: iconColor,
      iconBg: iconBg,
      title: title,
      subtitle: subtitle,
      compact: true,
    );
  }
}

class PremiumSkeletonCard extends StatelessWidget {
  const PremiumSkeletonCard({
    super.key,
    this.height = 150,
    this.radius = 24,
    this.padding = const EdgeInsets.all(14),
    this.child,
  });

  final double height;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.86, end: 1),
      duration: const Duration(milliseconds: 950),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Container(
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: AppTheme.outline),
              boxShadow: AppTheme.softShadows(0.08),
            ),
            child:
                child ??
                ClipRRect(
                  borderRadius: BorderRadius.circular(radius - 2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.bg,
                          AppTheme.lilac.withAlpha(130),
                          AppTheme.sky.withAlpha(100),
                          AppTheme.bg,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
          ),
        );
      },
    );
  }
}

class PremiumSkeletonLine extends StatelessWidget {
  const PremiumSkeletonLine({
    super.key,
    required this.width,
    this.height = 12,
    this.radius = 999,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.ink.withAlpha(10),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
