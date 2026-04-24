import 'package:flutter/material.dart';
import '../../../ui/adaptive_cached_image.dart';
import '../../../ui/premium_pills.dart';
import '../../../ui/app_theme.dart';
import '../models/podcast_episode.dart';
import '../services/podcast_resume_store.dart';
import '../../../ui/premium_page_header.dart';
import '../../../ui/premium_cards.dart';
import '../../../ui/premium_sections.dart';

class PodcastHeroHeader extends StatelessWidget {
  const PodcastHeroHeader({super.key, required this.onTapInfo});
  final VoidCallback onTapInfo;

  @override
  Widget build(BuildContext context) {
    return PremiumPageHeader(
      icon: Icons.podcasts_rounded,
      iconColor: const Color(0xFF4C79C8),
      title: 'Podcasts',
      subtitle: 'Short, helpful episodes and curated for pet lovers.',
      trailing: IconButton(
        tooltip: 'Info',
        onPressed: onTapInfo,
        icon: Icon(
          Icons.info_outline_rounded,
          color: AppTheme.ink.withAlpha(170),
        ),
      ),
    );
  }
}

class PodcastSearchField extends StatelessWidget {
  const PodcastSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search podcasts…',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.trim().isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Clear',
              ),
      ),
    );
  }
}

class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = categories[i];
          return PremiumPill(
            label: c,
            selected: c == selected,
            onTap: () => onSelect(c),
            fontSize: 12.4,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          );
        },
      ),
    );
  }
}

class ContinueListeningCard extends StatelessWidget {
  const ContinueListeningCard({
    super.key,
    required this.resume,
    required this.onOpen,
    required this.onClear,
  });

  final PodcastResume resume;
  final VoidCallback onOpen;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    final when = _whenText(resume.updatedAtMs);
    final mmss = _mmss(resume.positionMs);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        border: Border.all(color: AppTheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          PodcastCover(
            imageUrl: resume.imageUrl,
            size: 56,
            radius: 18,
            showPlayBadge: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SoftChip(
                      label:
                          resume.sourceType.trim().toLowerCase() == 'youtube' ||
                              (resume.youtubeUrl ?? '').isNotEmpty
                          ? 'Continue video'
                          : 'Continue listening',
                      bg: AppTheme.mint,
                      fg: const Color(0xFF1B7A4B),
                      icon: Icons.play_circle_fill_rounded,
                    ),
                    if (resume.category.trim().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _SoftChip(
                        label: resume.category,
                        bg: AppTheme.lilac,
                        fg: const Color(0xFF4B3DB8),
                        icon: Icons.local_offer_rounded,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  resume.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    height: 1.1,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (resume.sourceType.trim().toLowerCase() == 'youtube' ||
                          (resume.youtubeUrl ?? '').isNotEmpty)
                      ? 'Last opened $when'
                      : 'Saved at $mmss · $when',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Clear',
            onPressed: () async => onClear(),
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: 2),
          FilledButton(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

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
      width: 268,
      child: PremiumCardSurface(
        radius: BorderRadius.circular(26),
        padding: const EdgeInsets.all(12),
        shadowOpacity: 0.13,
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'podcast_cover_${episode.id}',
              child: PodcastCover(
                imageUrl: episode.coverImageUrl,
                size: 78,
                radius: 22,
                showPlayBadge: true,
                isYouTube: episode.isYouTube,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 30,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          if (episode.category.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _SoftChip(
                                label: episode.category,
                                bg: AppTheme.lilac,
                                fg: const Color(0xFF4B3DB8),
                                icon: Icons.local_offer_rounded,
                              ),
                            ),
                          if (episode.isYouTube)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _SoftChip(
                                label: 'YouTube',
                                bg: const Color(0xFFFFECEC),
                                fg: const Color(0xFFE53935),
                                icon: Icons.play_circle_fill_rounded,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    episode.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.8,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    episode.description.trim().isEmpty
                        ? 'Tap to open'
                        : episode.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.muted.withAlpha(220),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  PremiumCardActionRow(
                    icon: episode.isYouTube
                        ? Icons.ondemand_video_rounded
                        : Icons.headphones_rounded,
                    label: episode.isYouTube ? 'Watch episode' : 'Listen now',
                    iconColor: episode.isYouTube
                        ? const Color(0xFFE53935)
                        : AppTheme.orangeDark,
                    textColor: episode.isYouTube
                        ? const Color(0xFFE53935)
                        : AppTheme.orangeDark,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (episode.durationLabel.trim().isNotEmpty) ...[
                          _MiniTag(text: episode.durationLabel),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.ink.withAlpha(145),
                        ),
                      ],
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

class PodcastEpisodeCard extends StatelessWidget {
  const PodcastEpisodeCard({
    super.key,
    required this.episode,
    required this.onTap,
    this.trailing,
  });

  final PodcastEpisode episode;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return PremiumCardSurface(
      radius: BorderRadius.circular(26),
      padding: const EdgeInsets.all(14),
      shadowOpacity: 0.11,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'podcast_cover_${episode.id}',
            child: PodcastCover(
              imageUrl: episode.coverImageUrl,
              size: 74,
              radius: 22,
              showPlayBadge: true,
              isYouTube: episode.isYouTube,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (episode.category.trim().isNotEmpty)
                      _SoftChip(
                        label: episode.category,
                        bg: AppTheme.lilac,
                        fg: const Color(0xFF4B3DB8),
                        icon: Icons.local_offer_rounded,
                      ),
                    if (episode.durationLabel.trim().isNotEmpty)
                      _SoftChip(
                        label: episode.durationLabel,
                        bg: AppTheme.butter,
                        fg: const Color(0xFFB97900),
                        icon: Icons.timer_rounded,
                      ),
                    if (episode.isYouTube)
                      _SoftChip(
                        label: 'YouTube',
                        bg: const Color(0xFFFFECEC),
                        fg: const Color(0xFFE53935),
                        icon: Icons.play_circle_fill_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  episode.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.8,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  episode.description.trim().isEmpty
                      ? 'Open to see details'
                      : episode.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(220),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.1,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 12),
                PremiumCardActionRow(
                  icon: episode.isYouTube
                      ? Icons.ondemand_video_rounded
                      : Icons.headphones_rounded,
                  label: episode.isYouTube ? 'Watch episode' : 'Listen now',
                  iconColor: episode.isYouTube
                      ? const Color(0xFFE53935)
                      : AppTheme.orangeDark,
                  textColor: episode.isYouTube
                      ? const Color(0xFFE53935)
                      : AppTheme.orangeDark,
                  trailing:
                      trailing ??
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.ink.withAlpha(140),
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

class PodcastCover extends StatelessWidget {
  const PodcastCover({
    super.key,
    required this.imageUrl,
    required this.size,
    required this.radius,
    this.showPlayBadge = false,
    this.isYouTube = false,
  });

  final String? imageUrl;
  final double size;
  final double radius;
  final bool showPlayBadge;
  final bool isYouTube;

  @override
  Widget build(BuildContext context) {
    final has = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: has
                    ? null
                    : const LinearGradient(
                        colors: [AppTheme.softOrange, AppTheme.lilac],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
              child: has
                  ? AdaptiveCachedImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      fallbackWidth: size,
                      fallbackHeight: size,
                      maxCacheDimension: 320,
                      placeholder: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                      ),
                      errorWidget: _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          if (showPlayBadge)
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Icon(
                  isYouTube
                      ? Icons.play_arrow_rounded
                      : Icons.play_arrow_rounded,
                  size: 16,
                  color: isYouTube
                      ? const Color(0xFFE53935)
                      : AppTheme.orangeDark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        Icons.podcasts_rounded,
        color: AppTheme.ink.withAlpha(140),
        size: size * 0.38,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return PremiumSectionHeader(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({
    required this.label,
    required this.bg,
    required this.fg,
    required this.icon,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PremiumToneChip(
      label: label,
      icon: icon,
      bg: bg,
      fg: fg,
      iconColor: fg,
      borderColor: AppTheme.outline,
      fontSize: 11.5,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return PremiumToneChip(
      label: text,
      bg: const Color(0xFFF8F5FF),
      fg: AppTheme.ink.withAlpha(165),
      borderColor: AppTheme.outline,
      fontSize: 11.5,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }
}

String _mmss(int ms) {
  if (ms < 0) ms = 0;
  final totalSec = (ms / 1000).floor();
  final m = (totalSec / 60).floor();
  final s = totalSec % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String _whenText(int updatedAtMs) {
  if (updatedAtMs <= 0) return 'recently';
  final dt = DateTime.fromMillisecondsSinceEpoch(updatedAtMs);
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
