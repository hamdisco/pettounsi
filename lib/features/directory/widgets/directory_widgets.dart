import 'package:flutter/material.dart';

import '../../../ui/adaptive_cached_image.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/premium_cards.dart';
import '../../../ui/premium_feedback.dart';
import '../../../ui/premium_pills.dart';
import '../../../ui/premium_sections.dart';
import '../../../ui/premium_sheet.dart';
import '../models/directory_item.dart';

class DirectoryHeroHeader extends StatelessWidget {
  const DirectoryHeroHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: PremiumCardSurface(
        radius: BorderRadius.circular(26),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        shadowOpacity: 0.15,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.blush, AppTheme.lilac, AppTheme.sky],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.outline),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(225),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white),
                ),
                child: Icon(icon, color: accent, size: 24),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: AppTheme.ink,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.muted.withAlpha(220),
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PremiumCardBadge(
                label: 'Directory',
                icon: Icons.place_rounded,
                bg: AppTheme.mist,
                fg: accent,
                borderColor: AppTheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DirectoryFiltersBar extends StatelessWidget {
  const DirectoryFiltersBar({
    super.key,
    required this.accent,
    required this.onMap,
    required this.nearMeActive,
    required this.locBusy,
    required this.onToggleNearMe,
    this.isEvents = false,
    this.upcomingOnly = false,
    this.onToggleUpcoming,
  });

  final Color accent;
  final VoidCallback onMap;
  final bool nearMeActive;
  final bool locBusy;
  final VoidCallback onToggleNearMe;
  final bool isEvents;
  final bool upcomingOnly;
  final VoidCallback? onToggleUpcoming;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: PremiumCardSurface(
        radius: BorderRadius.circular(22),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        shadowOpacity: 0.07,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PremiumPill(
              label: 'Map',
              icon: Icons.map_rounded,
              onTap: onMap,
              selected: false,
              fontSize: 12,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
            PremiumPill(
              label: locBusy
                  ? 'Locating...'
                  : (nearMeActive ? 'Near me on' : 'Near me'),
              icon: locBusy ? Icons.sync_rounded : Icons.near_me_rounded,
              onTap: locBusy ? null : onToggleNearMe,
              selected: nearMeActive,
              showCheckWhenSelected: nearMeActive,
              fontSize: 12,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
            if (isEvents)
              PremiumPill(
                label: upcomingOnly ? 'Upcoming only' : 'All events',
                icon: Icons.event_available_rounded,
                onTap: onToggleUpcoming,
                selected: upcomingOnly,
                showCheckWhenSelected: upcomingOnly,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DirectorySearchBox extends StatelessWidget {
  const DirectorySearchBox({
    super.key,
    required this.controller,
    required this.query,
    required this.accent,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final Color accent;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: PremiumCardSurface(
        radius: BorderRadius.circular(22),
        padding: const EdgeInsets.all(10),
        shadowOpacity: 0.06,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(Icons.search_rounded, color: accent),
            suffixIcon: query.trim().isEmpty
                ? null
                : IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            fillColor: AppTheme.mist,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppTheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppTheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppTheme.outline),
            ),
          ),
        ),
      ),
    );
  }
}

class DirectoryTopHintCard extends StatelessWidget {
  const DirectoryTopHintCard({
    super.key,
    required this.accent,
    required this.isEvents,
    required this.isVets,
  });

  final Color accent;
  final bool isEvents;
  final bool isVets;

  @override
  Widget build(BuildContext context) {
    final text = isEvents
        ? 'Tip: open Directions to navigate directly to the event location.'
        : isVets
        ? 'Tip: call a clinic first to confirm hours and emergency availability.'
        : 'Tip: use Near me and Map together to find nearby places faster.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: PremiumCardSurface(
        radius: BorderRadius.circular(20),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        shadowOpacity: 0.05,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color.lerp(accent, Colors.white, 0.88),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Icon(Icons.info_outline_rounded, color: accent, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: AppTheme.ink.withAlpha(185),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.2,
                  height: 1.22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DirectoryResultsSummary extends StatelessWidget {
  const DirectoryResultsSummary({
    super.key,
    required this.count,
    required this.accent,
    required this.title,
    required this.query,
  });

  final int count;
  final Color accent;
  final String title;
  final String query;

  @override
  Widget build(BuildContext context) {
    final isSearching = query.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: PremiumCardSurface(
        radius: BorderRadius.circular(18),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shadowOpacity: 0.05,
        child: Row(
          children: [
            PremiumCardBadge(
              label: '$count',
              bg: Color.lerp(accent, Colors.white, 0.88)!,
              fg: accent,
              borderColor: AppTheme.outline,
              fontSize: 11.7,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isSearching ? '$title matching "$query"' : '$title available',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.muted.withAlpha(220),
                  fontWeight: FontWeight.w800,
                  fontSize: 12.1,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DirectoryStateCard extends StatelessWidget {
  const DirectoryStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: PremiumEmptyStateCard(
          icon: icon,
          iconColor: accent,
          iconBg: Color.lerp(accent, Colors.white, 0.88)!,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }
}

class DirectoryCardSkeleton extends StatelessWidget {
  const DirectoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: PremiumSkeletonCard(height: 206, radius: 22),
    );
  }
}

class DirectoryItemCard extends StatelessWidget {
  const DirectoryItemCard({
    super.key,
    required this.item,
    required this.accent,
    required this.leadingIcon,
    required this.onTap,
    required this.onDirections,
    required this.onCall,
    required this.onSource,
  });

  final DirectoryItem item;
  final Color accent;
  final IconData leadingIcon;
  final VoidCallback onTap;
  final VoidCallback? onDirections;
  final VoidCallback? onCall;
  final VoidCallback? onSource;

  @override
  Widget build(BuildContext context) {
    final titleColor = Color.lerp(AppTheme.ink, const Color(0xFF6F6482), 0.30)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: PremiumCardSurface(
        onTap: onTap,
        radius: BorderRadius.circular(22),
        padding: EdgeInsets.zero,
        shadowOpacity: 0.10,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumSoftPanel(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              radius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
              gradient: const LinearGradient(
                colors: [AppTheme.blush, AppTheme.lilac, AppTheme.sky],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderColor: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.isEvent && item.dateLabel.trim().isNotEmpty) ...[
                    _EventPill(dateLabel: item.dateLabel, accent: accent),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(225),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Icon(leadingIcon, color: accent, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              height: 1.15,
                              color: titleColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (item.hasPhoto)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: _DirectoryPhoto(
                  photoUrl: item.photoUrl!,
                  accent: accent,
                  icon: leadingIcon,
                  height: 164,
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, item.hasPhoto ? 10 : 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_locationLine(item).isNotEmpty) ...[
                    _MetaRow(
                      icon: Icons.place_outlined,
                      accent: accent,
                      text: _locationLine(item),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (item.distanceKm != null) ...[
                    _MetaRow(
                      icon: Icons.near_me_outlined,
                      accent: accent,
                      text: _formatKm(item.distanceKm!),
                      prefix: 'Distance: ',
                    ),
                    const SizedBox(height: 8),
                  ],
                  if ((item.phone ?? '').trim().isNotEmpty) ...[
                    _MetaRow(
                      icon: Icons.call_outlined,
                      accent: accent,
                      text: item.phone!,
                      prefix: 'Phone: ',
                    ),
                    const SizedBox(height: 8),
                  ],
                  if ((item.notes ?? '').trim().isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF8FD),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: Text(
                        item.notes!,
                        style: TextStyle(
                          color: AppTheme.ink.withAlpha(175),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.4,
                          height: 1.22,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  PremiumCardActionRow(
                    icon: leadingIcon,
                    label: 'Open details',
                    iconColor: accent,
                    textColor: accent,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.ink.withAlpha(120),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (onDirections != null)
                        _ActionChipButton(
                          label: 'Directions',
                          icon: Icons.near_me_rounded,
                          onTap: onDirections!,
                          accent: accent,
                          filled: true,
                        ),
                      if (onCall != null)
                        _ActionChipButton(
                          label: 'Call',
                          icon: Icons.call_outlined,
                          onTap: onCall!,
                          accent: accent,
                        ),
                      if (onSource != null)
                        _ActionChipButton(
                          label: 'Source',
                          icon: Icons.open_in_new_rounded,
                          onTap: onSource!,
                          accent: accent,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _locationLine(DirectoryItem item) {
    final parts = <String>[
      if (item.address.isNotEmpty) item.address,
      if (item.city.isNotEmpty) item.city,
      if (item.governorate.isNotEmpty) item.governorate,
    ];
    return parts.join(' • ');
  }

  static String _formatKm(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }
}


class _DirectoryPhoto extends StatelessWidget {
  const _DirectoryPhoto({
    required this.photoUrl,
    required this.accent,
    required this.icon,
    required this.height,
  });

  final String photoUrl;
  final Color accent;
  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
        color: Color.lerp(accent, Colors.white, 0.9),
      ),
      clipBehavior: Clip.antiAlias,
      child: AdaptiveCachedImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        fallbackHeight: height,
        placeholder: _DirectoryPhotoFallback(accent: accent, icon: icon),
        errorWidget: _DirectoryPhotoFallback(accent: accent, icon: icon),
      ),
    );
  }
}

class _DirectoryPhotoFallback extends StatelessWidget {
  const _DirectoryPhotoFallback({required this.accent, required this.icon});

  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(accent, Colors.white, 0.74)!,
            Color.lerp(accent, Colors.white, 0.9)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(220),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
      ),
    );
  }
}

class _EventPill extends StatelessWidget {
  const _EventPill({required this.dateLabel, required this.accent});

  final String dateLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (dateLabel.trim().isEmpty) return const SizedBox.shrink();

    return PremiumCardBadge(
      label: dateLabel,
      icon: Icons.event_available_rounded,
      bg: Color.lerp(accent, Colors.white, 0.88)!,
      fg: accent,
      borderColor: AppTheme.outline,
      fontSize: 11.5,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.accent,
    required this.text,
    this.prefix,
  });

  final IconData icon;
  final Color accent;
  final String text;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: accent.withAlpha(16),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accent, size: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                if (prefix != null)
                  TextSpan(
                    text: prefix,
                    style: TextStyle(
                      color: AppTheme.ink.withAlpha(195),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                TextSpan(text: text),
              ],
            ),
            style: TextStyle(
              color: AppTheme.ink.withAlpha(170),
              fontWeight: FontWeight.w700,
              height: 1.22,
              fontSize: 12.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.accent,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return PremiumToneChip(
      label: label,
      icon: icon,
      bg: filled ? Color.lerp(accent, Colors.white, 0.88)! : Colors.white,
      fg: filled ? accent : AppTheme.ink,
      iconColor: filled ? accent : AppTheme.ink,
      borderColor: filled ? Colors.transparent : AppTheme.outline,
      fontSize: 12.2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    );
  }
}

class DirectoryDetailsSheet extends StatelessWidget {
  const DirectoryDetailsSheet({
    super.key,
    required this.item,
    required this.accent,
    required this.leadingIcon,
    required this.onDirections,
    required this.onCall,
    required this.onSource,
  });

  final DirectoryItem item;
  final Color accent;
  final IconData leadingIcon;
  final VoidCallback? onDirections;
  final VoidCallback? onCall;
  final VoidCallback? onSource;

  @override
  Widget build(BuildContext context) {
    return PremiumBottomSheetFrame(
      icon: leadingIcon,
      iconColor: accent,
      iconBg: Color.lerp(accent, Colors.white, 0.88)!,
      title: item.name,
      subtitle: item.isEvent
          ? 'Event details and quick actions'
          : 'Place details and quick actions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.hasPhoto) ...[
            _DirectoryPhoto(
              photoUrl: item.photoUrl!,
              accent: accent,
              icon: leadingIcon,
              height: 188,
            ),
            const SizedBox(height: 12),
          ],
          if (item.isEvent && item.dateLabel.trim().isNotEmpty) ...[
            _EventPill(dateLabel: item.dateLabel, accent: accent),
            const SizedBox(height: 10),
          ],
          PremiumSheetInfoCard(
            icon: leadingIcon,
            iconBg: Color.lerp(accent, Colors.white, 0.88)!,
            iconFg: accent,
            title: item.name,
            subtitle: _locationLine(item).isEmpty
                ? 'Open actions below for more.'
                : _locationLine(item),
          ),
          if (item.distanceKm != null) ...[
            const SizedBox(height: 10),
            PremiumSheetInfoCard(
              icon: Icons.near_me_outlined,
              iconBg: AppTheme.sky,
              iconFg: const Color(0xFF4C79C8),
              title: 'Distance',
              subtitle: DirectoryItemCard._formatKm(item.distanceKm!),
              compact: true,
            ),
          ],
          if (item.hasPhone) ...[
            const SizedBox(height: 10),
            PremiumSheetInfoCard(
              icon: Icons.call_outlined,
              iconBg: AppTheme.mint,
              iconFg: const Color(0xFF2F9A6A),
              title: 'Phone',
              subtitle: item.phone!,
              compact: true,
            ),
          ],
          if ((item.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF8FD),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Text(
                item.notes!,
                style: TextStyle(
                  color: AppTheme.ink.withAlpha(175),
                  fontWeight: FontWeight.w700,
                  height: 1.24,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _BigActionButton(
                  label: 'Directions',
                  icon: Icons.near_me_rounded,
                  accent: accent,
                  onTap: onDirections,
                  filled: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BigActionButton(
                  label: 'Call',
                  icon: Icons.call_outlined,
                  accent: accent,
                  onTap: onCall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _BigActionButton(
            label: 'Open source',
            icon: Icons.open_in_new_rounded,
            accent: accent,
            onTap: onSource,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  static String _locationLine(DirectoryItem item) {
    final parts = <String>[
      if (item.address.isNotEmpty) item.address,
      if (item.city.isNotEmpty) item.city,
      if (item.governorate.isNotEmpty) item.governorate,
    ];
    return parts.join(' • ');
  }
}

class _BigActionButton extends StatelessWidget {
  const _BigActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    final bg = disabled
        ? AppTheme.outline.withAlpha(80)
        : filled
        ? accent
        : Colors.white;

    final borderColor = disabled
        ? Colors.transparent
        : filled
        ? Colors.transparent
        : AppTheme.outline;

    final fg = disabled
        ? AppTheme.muted
        : filled
        ? Colors.white
        : AppTheme.ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: filled ? AppTheme.softShadows(0.20) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
