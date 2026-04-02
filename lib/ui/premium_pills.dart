import 'package:flutter/material.dart';

import 'app_theme.dart';

const Color _premiumPillStart = Color(0xFF7C62D7);
const Color _premiumPillEnd = Color(0xFFC86B9A);
const Color _premiumPillSoft = Color(0xFFF8F5FF);
const Color _premiumPillSoftBorder = Color(0xFFEADFF5);

class PremiumPill extends StatelessWidget {
  const PremiumPill({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.badgeCount,
    this.showCheckWhenSelected = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    this.fontSize = 12.2,
    this.unselectedBackground = _premiumPillSoft,
    this.unselectedTextColor = AppTheme.ink,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final int? badgeCount;
  final bool showCheckWhenSelected;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final Color unselectedBackground;
  final Color unselectedTextColor;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.white : _premiumPillStart;
    final textColor = selected ? Colors.white : unselectedTextColor;

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [_premiumPillStart, _premiumPillEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: selected ? null : unselectedBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? Colors.white.withAlpha(110)
              : _premiumPillSoftBorder,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: _premiumPillStart.withAlpha(36),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : AppTheme.softShadows(0.05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCheckWhenSelected && selected) ...[
            const Icon(Icons.check_rounded, size: 15, color: Colors.white),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: fontSize,
              height: 1,
            ),
          ),
          if (badgeCount != null && badgeCount! > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withAlpha(210) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? Colors.white.withAlpha(110)
                      : AppTheme.outline,
                ),
              ),
              child: Text(
                '$badgeCount',
                style: TextStyle(
                  color: selected
                      ? _premiumPillStart
                      : AppTheme.ink.withAlpha(185),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  height: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class PremiumToneChip extends StatelessWidget {
  const PremiumToneChip({
    super.key,
    required this.label,
    this.icon,
    this.bg = _premiumPillSoft,
    this.fg = AppTheme.ink,
    this.iconColor,
    this.borderColor = _premiumPillSoftBorder,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    this.fontSize = 11.8,
  });

  final String label;
  final IconData? icon;
  final Color bg;
  final Color fg;
  final Color? iconColor;
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
            Icon(icon, size: 14, color: iconColor ?? fg),
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
