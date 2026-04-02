import 'package:flutter/material.dart';

import 'app_theme.dart';

Future<void> showPremiumPermissionDialog({
  required BuildContext context,
  required IconData icon,
  required Color tint,
  required Color iconBg,
  required String title,
  required String message,
  required String primaryLabel,
  required Future<void> Function() onPrimary,
  String secondaryLabel = 'Not now',
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _PremiumPermissionDialog(
      icon: icon,
      tint: tint,
      iconBg: iconBg,
      title: title,
      message: message,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
      secondaryLabel: secondaryLabel,
    ),
  );
}

class _PremiumPermissionDialog extends StatelessWidget {
  const _PremiumPermissionDialog({
    required this.icon,
    required this.tint,
    required this.iconBg,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
  });

  final IconData icon;
  final Color tint;
  final Color iconBg;
  final String title;
  final String message;
  final String primaryLabel;
  final Future<void> Function() onPrimary;
  final String secondaryLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surface = isDark ? const Color(0xFF17131C) : Colors.white;
    final soft = isDark ? const Color(0xFF231D2A) : const Color(0xFFFFF6F1);
    final border = isDark ? const Color(0xFF31283A) : AppTheme.outline;
    final titleColor = isDark ? const Color(0xFFF4EFFA) : AppTheme.ink;
    final bodyColor = isDark ? const Color(0xFFC6BACF) : AppTheme.muted;

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 70 : 28),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    soft,
                    isDark ? const Color(0xFF1C1822) : const Color(0xFFF8F4FB),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(31),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withAlpha(18)
                            : Colors.white,
                      ),
                    ),
                    child: Icon(icon, color: tint, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Permission needed',
                          style: TextStyle(
                            color: bodyColor.withAlpha(220),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.2,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Text(
                message,
                style: TextStyle(
                  color: bodyColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(secondaryLabel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await onPrimary();
                      },
                      icon: const Icon(Icons.settings_rounded, size: 18),
                      label: Text(primaryLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
