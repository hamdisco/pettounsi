import 'package:flutter/material.dart';

import 'app_theme.dart';

class PremiumSectionHeader extends StatelessWidget {
  const PremiumSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 15.2 : 16.4,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.muted.withAlpha(220),
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 12.0 : 12.4,
                  height: 1.16,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

class PremiumCardActionRow extends StatelessWidget {
  const PremiumCardActionRow({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor = AppTheme.muted,
    this.textColor = AppTheme.muted,
    this.trailing,
    this.bg = AppTheme.mist,
    this.borderColor = AppTheme.outline,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final Widget? trailing;
  final Color bg;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 11.9,
                height: 1.05,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
