import 'package:flutter/material.dart';

import 'app_theme.dart';

class PremiumPageHeader extends StatelessWidget {
  const PremiumPageHeader({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badgeLabel,
    this.trailing,
    this.chips = const <Widget>[],
    this.padding = const EdgeInsets.fromLTRB(14, 14, 14, 14),
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badgeLabel;
  final Widget? trailing;
  final List<Widget> chips;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final showBadge = badgeLabel != null && badgeLabel!.trim().isNotEmpty;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [AppTheme.blush, AppTheme.lilac, AppTheme.sky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(225),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 27),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 16.2,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.muted.withAlpha(220),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.6,
                          height: 1.18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (showBadge) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(210),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Text(
                    badgeLabel!,
                    style: TextStyle(
                      color: AppTheme.ink.withAlpha(190),
                      fontWeight: FontWeight.w900,
                      fontSize: 11.3,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ],
      ),
    );
  }
}

class PremiumHeaderChip extends StatelessWidget {
  const PremiumHeaderChip({
    super.key,
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 11.4,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
