import 'package:flutter/material.dart';

import '../../../ui/app_theme.dart';

class PodcastSectionHeader extends StatelessWidget {
  const PodcastSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.orange.withAlpha(12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Icon(icon, size: 20, color: AppTheme.orangeDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppTheme.ink,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.ink.withAlpha(150),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
