import 'package:flutter/material.dart';

import '../../../ui/app_theme.dart';
import '../../../ui/brand_widgets.dart';
import '../models/podcast_episode.dart';
import 'podcast_episode_card.dart';

class PodcastFeaturedCard extends StatelessWidget {
  const PodcastFeaturedCard({
    super.key,
    required this.episode,
    required this.onTap,
  });

  final PodcastEpisode episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: SoftCard(
        padding: const EdgeInsets.all(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Hero(
                      tag: 'podcast_featured_cover_${episode.id}',
                      child: PodcastCover(
                        imageUrl: episode.coverImageUrl,
                        size: 156,
                        radius: 20,
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.outline),
                          boxShadow: AppTheme.softShadows(0.25),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppTheme.orangeDark,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (episode.category.trim().isNotEmpty)
                      PodcastTagChip(label: episode.category),
                    if (episode.durationLabel.trim().isNotEmpty)
                      PodcastTagChip(label: episode.durationLabel),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  episode.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.8,
                    height: 1.12,
                    color: AppTheme.ink,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.headphones_rounded,
                        size: 16, color: AppTheme.ink.withAlpha(160)),
                    const SizedBox(width: 6),
                    Text(
                      'Listen now',
                      style: TextStyle(
                        color: AppTheme.ink.withAlpha(170),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        color: AppTheme.ink.withAlpha(120)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
