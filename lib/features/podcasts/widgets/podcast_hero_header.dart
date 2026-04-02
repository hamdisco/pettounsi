import 'package:flutter/material.dart';

import '../../../ui/app_theme.dart';

class PodcastHeroHeader extends StatelessWidget {
  const PodcastHeroHeader({super.key, this.onTipTap});

  final VoidCallback? onTipTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.blush, AppTheme.lilac, AppTheme.sky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.38),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/start.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.05, -0.05),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFB79E), AppTheme.orange],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.orange.withAlpha(35),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.headphones_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Podcasts',
                            style: TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(210),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppTheme.outline),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.podcasts_rounded,
                                  size: 14,
                                  color: AppTheme.ink.withAlpha(160),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Audio',
                                  style: TextStyle(
                                    color: AppTheme.ink.withAlpha(170),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11.5,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Quick episodes for pet care tips, stories, and updates — ready to listen anywhere.',
                        style: TextStyle(
                          color: AppTheme.ink.withAlpha(170),
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniPill(
                            icon: Icons.offline_bolt_rounded,
                            label: 'Fast',
                          ),
                          _MiniPill(
                            icon: Icons.auto_awesome_rounded,
                            label: 'Premium UI',
                          ),
                          _MiniPill(
                            icon: Icons.bookmark_added_rounded,
                            label: 'Resume',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.white.withAlpha(220),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onTipTap,
                    child: const SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: AppTheme.orangeDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(210),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.ink.withAlpha(170)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.ink.withAlpha(175),
              fontWeight: FontWeight.w900,
              fontSize: 12,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
