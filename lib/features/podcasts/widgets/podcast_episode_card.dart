import 'package:flutter/material.dart';

import '../../../ui/adaptive_cached_image.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/brand_widgets.dart';
import '../models/podcast_episode.dart';

class PodcastEpisodeCard extends StatelessWidget {
  const PodcastEpisodeCard({
    super.key,
    required this.episode,
    required this.onTap,
  });

  final PodcastEpisode episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Hero(
                    tag: 'podcast_list_cover_${episode.id}',
                    child: PodcastCover(imageUrl: episode.coverImageUrl, size: 86),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppTheme.outline),
                        boxShadow: AppTheme.softShadows(0.18),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 18,
                        color: AppTheme.orangeDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        fontSize: 14.4,
                        height: 1.12,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      episode.description.isEmpty
                          ? 'Tap to listen.'
                          : episode.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.ink.withAlpha(150),
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.headphones_rounded,
                            size: 18, color: AppTheme.ink.withAlpha(160)),
                        const SizedBox(width: 6),
                        Text(
                          'Listen',
                          style: TextStyle(
                            color: AppTheme.orangeDark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded,
                            color: AppTheme.ink.withAlpha(130)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PodcastCover extends StatelessWidget {
  const PodcastCover({
    super.key,
    required this.imageUrl,
    this.size = 84,
    this.radius = 16,
  });

  final String? imageUrl;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: hasImage
            ? null
            : const LinearGradient(
                colors: [Color(0xFFFFEAE0), Color(0xFFF3EEFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? AdaptiveCachedImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              fallbackWidth: size,
              fallbackHeight: size,
              maxCacheDimension: 320,
              errorWidget: _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Center(
        child: Icon(
          Icons.headphones_rounded,
          size: size * 0.40,
          color: AppTheme.ink.withAlpha(160),
        ),
      );
}

class PodcastTagChip extends StatelessWidget {
  const PodcastTagChip({
    super.key,
    required this.label,
    this.tint = const Color(0xFFF8F4FB),
    this.textColor,
  });

  final String label;
  final Color tint;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline.withAlpha(180)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? AppTheme.ink.withAlpha(160),
          fontWeight: FontWeight.w800,
          fontSize: 11,
          height: 1.0,
        ),
      ),
    );
  }
}
