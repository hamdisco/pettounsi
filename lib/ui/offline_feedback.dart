import 'package:flutter/material.dart';

import '../services/connectivity_status_controller.dart';
import 'app_theme.dart';
import 'premium_feedback.dart';

class OfflinePageState extends StatelessWidget {
  const OfflinePageState({
    super.key,
    this.title = 'You are offline',
    this.subtitle =
        'Showing saved content when available. Reconnect to refresh live data.',
    this.compact = false,
    this.icon = Icons.cloud_off_rounded,
    this.iconColor = const Color(0xFF6B56C9),
    this.iconBg = AppTheme.lilac,
    this.primaryLabel = 'Retry',
  });

  final String title;
  final String subtitle;
  final bool compact;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String primaryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: PremiumEmptyStateCard(
          icon: icon,
          iconColor: iconColor,
          iconBg: iconBg,
          title: title,
          subtitle: subtitle,
          primaryLabel: primaryLabel,
          primaryIcon: Icons.refresh_rounded,
          onPrimary: () => ConnectivityStatusController.instance.refresh(),
          compact: compact,
        ),
      ),
    );
  }
}
