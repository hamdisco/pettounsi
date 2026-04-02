import 'package:flutter/material.dart';

import 'app_theme.dart';

class PremiumCardSurface extends StatelessWidget {
  const PremiumCardSurface({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.radius = const BorderRadius.all(Radius.circular(26)),
    this.gradient,
    this.backgroundColor = Colors.white,
    this.borderColor = AppTheme.outline,
    this.shadowOpacity = 0.12,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final Gradient? gradient;
  final Color backgroundColor;
  final Color borderColor;
  final double shadowOpacity;

  Widget _buildInk() {
    return Ink(
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(color: borderColor),
        boxShadow: AppTheme.softShadows(shadowOpacity),
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: _buildInk(),
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(borderRadius: radius, onTap: onTap, child: _buildInk()),
    );
  }
}

class PremiumCardBadge extends StatelessWidget {
  const PremiumCardBadge({
    super.key,
    required this.label,
    this.icon,
    this.bg = AppTheme.mist,
    this.fg = AppTheme.ink,
    this.borderColor = AppTheme.outline,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    this.fontSize = 11.6,
  });

  final String label;
  final IconData? icon;
  final Color bg;
  final Color fg;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: fontSize,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumMetaRow extends StatelessWidget {
  const PremiumMetaRow({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor = AppTheme.muted,
    this.textColor = AppTheme.muted,
    this.iconSize = 15,
    this.fontSize = 11.9,
    this.fontWeight = FontWeight.w800,
  });

  final IconData icon;
  final String text;
  final Color iconColor;
  final Color textColor;
  final double iconSize;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontWeight: fontWeight,
              fontSize: fontSize,
              height: 1.05,
            ),
          ),
        ),
      ],
    );
  }
}

class PremiumSoftPanel extends StatelessWidget {
  const PremiumSoftPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = const BorderRadius.all(Radius.circular(20)),
    this.color = AppTheme.bg,
    this.gradient,
    this.borderColor = AppTheme.outline,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final Color color;
  final Gradient? gradient;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}
