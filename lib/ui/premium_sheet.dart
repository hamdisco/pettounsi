import 'package:flutter/material.dart';

import 'app_theme.dart';

class PremiumBottomSheetFrame extends StatelessWidget {
  const PremiumBottomSheetFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon,
    this.iconColor,
    this.iconBg,
    this.trailing,
    this.scrollable = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBg;
  final Widget? trailing;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 5,
          decoration: BoxDecoration(
            color: AppTheme.ink.withAlpha(18),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg ?? AppTheme.lilac,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? const Color(0xFF7C62D7),
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16.4,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.muted.withAlpha(220),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.4,
                        height: 1.18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, 12 + bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.outline),
            boxShadow: AppTheme.softShadows(0.22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: scrollable ? SingleChildScrollView(child: body) : body,
          ),
        ),
      ),
    );
  }
}

class PremiumSheetInfoCard extends StatelessWidget {
  const PremiumSheetInfoCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.compact = false,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 11 : 12),
      decoration: BoxDecoration(
        color: compact ? Colors.white : AppTheme.bg,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 34 : 38,
            height: compact ? 34 : 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(compact ? 12 : 14),
              border: Border.all(color: Colors.white),
            ),
            child: Icon(icon, color: iconFg, size: compact ? 18 : 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 12.6 : 13,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(220),
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 11.9 : 12.1,
                    height: 1.18,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}
