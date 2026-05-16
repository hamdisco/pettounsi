import 'package:flutter/material.dart';

import '../../../ui/adaptive_cached_image.dart';
import '../../../ui/app_theme.dart';
import '../../../ui/premium_cards.dart';
import '../../../ui/premium_feedback.dart';
import '../../../ui/premium_pills.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: PremiumCardSurface(
        radius: BorderRadius.circular(28),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        shadowOpacity: 0.07,
        backgroundColor: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Color.lerp(accent, Colors.white, 0.88),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 21,
                      color: AppTheme.ink,
                      height: 1.05,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.6,
                      height: 1.18,
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

class DirectoryPartnerBand extends StatelessWidget {
  const DirectoryPartnerBand({
    super.key,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String ctaLabel;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: PremiumCardSurface(
        radius: BorderRadius.circular(24),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        shadowOpacity: 0.05,
        backgroundColor: Colors.white,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Color.lerp(accent, Colors.white, 0.90),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Icon(icon, color: accent, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.2,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.7,
                      height: 1.14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _InlineButton(label: ctaLabel, accent: accent, onTap: onTap),
          ],
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            unselectedBackground: Colors.white,
          ),
          PremiumPill(
            label: locBusy ? 'Locating' : (nearMeActive ? 'Near me' : 'Nearby'),
            icon: locBusy ? Icons.sync_rounded : Icons.near_me_rounded,
            onTap: locBusy ? null : onToggleNearMe,
            selected: nearMeActive,
            showCheckWhenSelected: nearMeActive,
            fontSize: 12,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            unselectedBackground: Colors.white,
          ),
          if (isEvents)
            PremiumPill(
              label: upcomingOnly ? 'Upcoming' : 'All events',
              icon: Icons.event_available_rounded,
              onTap: onToggleUpcoming,
              selected: upcomingOnly,
              showCheckWhenSelected: upcomingOnly,
              fontSize: 12,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              unselectedBackground: Colors.white,
            ),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
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
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppTheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppTheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: accent, width: 1.2),
          ),
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
    final label = isSearching ? 'Results for "$query"' : '$title available';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 15.2,
              height: 1.05,
            ),
          ),
          const Spacer(),
          PremiumCardBadge(
            label: '$count',
            bg: Color.lerp(accent, Colors.white, 0.88)!,
            fg: accent,
            borderColor: AppTheme.outline,
            fontSize: 11.7,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          ),
        ],
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
      padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: PremiumSkeletonCard(height: 144, radius: 24),
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
    required this.onWhatsApp,
  });

  final DirectoryItem item;
  final Color accent;
  final IconData leadingIcon;
  final VoidCallback onTap;
  final VoidCallback? onDirections;
  final VoidCallback? onCall;
  final VoidCallback? onSource;
  final VoidCallback? onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final location = _locationLine(item);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: PremiumCardSurface(
        onTap: onTap,
        radius: BorderRadius.circular(26),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        shadowOpacity: 0.08,
        backgroundColor: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                item.isEvent
                    ? _EventDateAvatar(item: item, accent: accent)
                    : _DirectoryAvatar(
                        item: item,
                        accent: accent,
                        icon: leadingIcon,
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 16.2,
                                height: 1.08,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (item.isEvent)
                            _SmallBadge(
                              label: item.eventStatusLabel,
                              accent: accent,
                            )
                          else if (item.isFeatured)
                            _SmallBadge(label: 'Featured', accent: accent)
                          else if (item.hasPartnerLabel)
                            _SmallBadge(label: 'Partner', accent: accent),
                          if (item.isEmergency)
                            _SmallBadge(label: 'Emergency', accent: accent),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _MiniMeta(
                            icon: item.isEvent
                                ? Icons.event_available_rounded
                                : Icons.business_rounded,
                            text: item.isEvent
                                ? item.eventTimeLabel
                                : item.category,
                          ),
                          if (location.isNotEmpty)
                            _MiniMeta(icon: Icons.place_outlined, text: location),
                          if (item.distanceKm != null)
                            _MiniMeta(
                              icon: Icons.near_me_outlined,
                              text: _formatKm(item.distanceKm!),
                            ),
                          if (!item.isEvent && item.hasServices)
                            _MiniMeta(
                              icon: Icons.check_circle_outline_rounded,
                              text: item.servicesText!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.isEvent) ...[
              const SizedBox(height: 12),
              _EventClarityStrip(item: item, accent: accent),
            ] else ...[
              if ((item.openingHours ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _PartnerClarityStrip(
                  icon: Icons.schedule_rounded,
                  text: item.openingHours!,
                  accent: accent,
                ),
              ],
              if ((item.offerText ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                _OfferStrip(text: item.offerText!, accent: accent),
              ],
            ],
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _CardButton(
                    label: item.isEvent ? 'Event info' : 'Details',
                    icon: item.isEvent
                        ? Icons.event_note_rounded
                        : Icons.info_outline_rounded,
                    onTap: onTap,
                    accent: accent,
                  ),
                ),
                const SizedBox(width: 8),
                if (onWhatsApp != null) ...[
                  Expanded(
                    child: _CardButton(
                      label: 'WhatsApp',
                      icon: Icons.chat_bubble_outline_rounded,
                      onTap: onWhatsApp!,
                      accent: accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (onCall != null) ...[
                  Expanded(
                    child: _CardButton(
                      label: 'Call',
                      icon: Icons.call_outlined,
                      onTap: onCall!,
                      accent: accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: _CardButton(
                    label: 'Directions',
                    icon: Icons.near_me_rounded,
                    onTap: onDirections,
                    accent: accent,
                    filled: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String locationLine(DirectoryItem item) => _locationLine(item);
  static String formatKm(double km) => _formatKm(km);

  static String _locationLine(DirectoryItem item) {
    final parts = <String>[
      if (item.city.isNotEmpty) item.city,
      if (item.governorate.isNotEmpty && item.governorate != item.city)
        item.governorate,
      if (item.address.isNotEmpty) item.address,
    ];
    return parts.join(' · ');
  }

  static String _formatKm(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
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
    required this.onWhatsApp,
  });

  final DirectoryItem item;
  final Color accent;
  final IconData leadingIcon;
  final VoidCallback? onDirections;
  final VoidCallback? onCall;
  final VoidCallback? onSource;
  final VoidCallback? onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final location = DirectoryItemCard.locationLine(item);

    return PremiumBottomSheetFrame(
      icon: leadingIcon,
      iconColor: accent,
      iconBg: Color.lerp(accent, Colors.white, 0.88)!,
      title: item.name,
      subtitle: item.isEvent
          ? 'Event information'
          : (item.collectionName == 'vets'
                ? 'Clinic profile'
                : (item.collectionName == 'petshops'
                      ? 'Shop profile'
                      : item.category)),
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
          if (item.isEvent) ...[
            _EventClarityStrip(item: item, accent: accent),
            const SizedBox(height: 12),
          ] else ...[
            _PartnerProfileStrip(item: item, accent: accent),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (item.isEvent && item.dateLabel.trim().isNotEmpty)
                _SmallBadge(label: item.dateLabel, accent: accent),
              _SmallBadge(label: item.category, accent: accent),
              if (item.isFeatured) _SmallBadge(label: 'Featured', accent: accent),
              if (!item.isFeatured && item.hasPartnerLabel)
                _SmallBadge(label: 'Partner', accent: accent),
              if (item.isEmergency) _SmallBadge(label: 'Emergency', accent: accent),
            ],
          ),
          const SizedBox(height: 12),
          if (item.isEvent && item.eventTimeLabel.trim().isNotEmpty) ...[
            PremiumSheetInfoCard(
              icon: Icons.event_available_rounded,
              iconBg: Color.lerp(accent, Colors.white, 0.90)!,
              iconFg: accent,
              title: item.eventStatusLabel,
              subtitle: item.eventTimeLabel,
              compact: true,
            ),
            const SizedBox(height: 10),
          ],
          if (location.isNotEmpty)
            PremiumSheetInfoCard(
              icon: Icons.place_outlined,
              iconBg: Color.lerp(accent, Colors.white, 0.90)!,
              iconFg: accent,
              title: 'Location',
              subtitle: location,
              compact: true,
            ),
          if (item.distanceKm != null) ...[
            const SizedBox(height: 10),
            PremiumSheetInfoCard(
              icon: Icons.near_me_outlined,
              iconBg: AppTheme.sky,
              iconFg: const Color(0xFF4C79C8),
              title: 'Distance',
              subtitle: DirectoryItemCard.formatKm(item.distanceKm!),
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
          if (item.hasWhatsapp) ...[
            const SizedBox(height: 10),
            PremiumSheetInfoCard(
              icon: Icons.chat_bubble_outline_rounded,
              iconBg: AppTheme.mint,
              iconFg: const Color(0xFF2F9A6A),
              title: 'WhatsApp',
              subtitle: item.whatsapp!,
              compact: true,
            ),
          ],
          if ((item.openingHours ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            PremiumSheetInfoCard(
              icon: Icons.schedule_rounded,
              iconBg: AppTheme.butter,
              iconFg: const Color(0xFFB87900),
              title: item.isEvent ? 'Schedule note' : 'Hours',
              subtitle: item.openingHours!,
              compact: true,
            ),
          ],
          if (!item.isEvent && (item.servicesText ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            PremiumSheetInfoCard(
              icon: Icons.check_circle_outline_rounded,
              iconBg: Color.lerp(accent, Colors.white, 0.90)!,
              iconFg: accent,
              title: item.collectionName == 'petshops' ? 'Products & services' : 'Clinic services',
              subtitle: item.servicesText!,
              compact: true,
            ),
          ],
          if ((item.offerText ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _OfferStrip(text: item.offerText!, accent: accent),
          ],
          if ((item.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _NotesBox(text: item.notes!),
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
                  label: item.hasWhatsapp ? 'WhatsApp' : 'Call',
                  icon: item.hasWhatsapp
                      ? Icons.chat_bubble_outline_rounded
                      : Icons.call_outlined,
                  accent: accent,
                  onTap: item.hasWhatsapp ? onWhatsApp : onCall,
                ),
              ),
            ],
          ),
          if (item.hasWhatsapp && onCall != null) ...[
            const SizedBox(height: 10),
            _BigActionButton(
              label: 'Call',
              icon: Icons.call_outlined,
              accent: accent,
              onTap: onCall,
            ),
          ],
          if (onSource != null) ...[
            const SizedBox(height: 10),
            _BigActionButton(
              label: item.isEvent ? 'Event source' : 'Website / source',
              icon: Icons.open_in_new_rounded,
              accent: accent,
              onTap: onSource,
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _DirectoryAvatar extends StatelessWidget {
  const _DirectoryAvatar({
    required this.item,
    required this.accent,
    required this.icon,
  });

  final DirectoryItem item;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (item.hasPhoto) {
      return Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: AdaptiveCachedImage(
          imageUrl: item.photoUrl!,
          fit: BoxFit.cover,
          fallbackHeight: 62,
          placeholder: _DirectoryPhotoFallback(accent: accent, icon: icon),
          errorWidget: _DirectoryPhotoFallback(accent: accent, icon: icon),
        ),
      );
    }

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: Color.lerp(accent, Colors.white, 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Icon(icon, color: accent, size: 25),
    );
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
        borderRadius: BorderRadius.circular(20),
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
      color: Color.lerp(accent, Colors.white, 0.86),
      child: Center(child: Icon(icon, color: accent, size: 24)),
    );
  }
}

class _EventDateAvatar extends StatelessWidget {
  const _EventDateAvatar({required this.item, required this.accent});

  final DirectoryItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final startsAt = item.startsAt;
    final day = startsAt == null ? '—' : '${startsAt.day}';
    final month = startsAt == null ? 'Date' : _eventMonth(startsAt.month);

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: Color.lerp(accent, Colors.white, 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color.lerp(accent, Colors.white, 0.70)!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            month,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 10.5,
              height: 1,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            day,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              height: 0.9,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }

  static String _eventMonth(int month) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > months.length) return 'Date';
    return months[month - 1];
  }
}

class _EventClarityStrip extends StatelessWidget {
  const _EventClarityStrip({required this.item, required this.accent});

  final DirectoryItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final location = DirectoryItemCard.locationLine(item);
    final subtitle = item.isEventPast
        ? 'This event has already passed.'
        : (location.isNotEmpty
              ? 'Check details and location before going.'
              : 'Check details before going.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: Color.lerp(accent, Colors.white, 0.93),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color.lerp(accent, Colors.white, 0.74)!),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Icon(_eventStatusIcon(item), color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.eventStatusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.8,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.4,
                    height: 1.14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _eventStatusIcon(DirectoryItem item) {
    if (item.isEventPast) return Icons.history_rounded;
    if (item.isEventToday) return Icons.today_rounded;
    return Icons.event_available_rounded;
  }
}



class _PartnerProfileStrip extends StatelessWidget {
  const _PartnerProfileStrip({required this.item, required this.accent});

  final DirectoryItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final title = item.collectionName == 'vets'
        ? (item.isEmergency ? 'Clinic contact ready' : 'Clinic profile')
        : (item.collectionName == 'petshops'
              ? 'Shop profile'
              : 'Partner profile');
    final subtitle = item.hasPhone || item.hasWhatsapp
        ? 'Use call, WhatsApp, or directions before visiting.'
        : 'Check details and location before visiting.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: Color.lerp(accent, Colors.white, 0.93),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color.lerp(accent, Colors.white, 0.74)!),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Icon(
              item.collectionName == 'vets'
                  ? Icons.medical_services_rounded
                  : Icons.storefront_rounded,
              color: accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.8,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.4,
                    height: 1.14,
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

class _PartnerClarityStrip extends StatelessWidget {
  const _PartnerClarityStrip({
    required this.icon,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Color.lerp(accent, Colors.white, 0.94),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Color.lerp(accent, Colors.white, 0.78)!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.ink.withAlpha(195),
                fontWeight: FontWeight.w800,
                fontSize: 12.1,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferStrip extends StatelessWidget {
  const _OfferStrip({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Color.lerp(accent, Colors.white, 0.92),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Color.lerp(accent, Colors.white, 0.72)!),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer_rounded, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.ink.withAlpha(205),
                fontWeight: FontWeight.w800,
                fontSize: 12.2,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesBox extends StatelessWidget {
  const _NotesBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.ink.withAlpha(180),
          fontWeight: FontWeight.w700,
          height: 1.24,
          fontSize: 12.6,
        ),
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  const _MiniMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.muted),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 185),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.w800,
              fontSize: 11.8,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return PremiumToneChip(
      label: label,
      bg: Color.lerp(accent, Colors.white, 0.90)!,
      fg: accent,
      borderColor: Color.lerp(accent, Colors.white, 0.72)!,
      fontSize: 11.4,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    );
  }
}

class _InlineButton extends StatelessWidget {
  const _InlineButton({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11.6,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.accent,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color accent;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final bg = filled ? accent : Colors.white;
    final fg = filled ? Colors.white : AppTheme.ink;
    final border = filled ? accent : AppTheme.outline;

    return Material(
      color: enabled ? bg : AppTheme.mist,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          height: 43,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: enabled ? border : AppTheme.outline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: enabled ? fg : AppTheme.muted, size: 17),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: enabled ? fg : AppTheme.muted,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.2,
                    height: 1,
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
    final enabled = onTap != null;
    final bg = filled ? accent : Colors.white;
    final fg = filled ? Colors.white : AppTheme.ink;
    final border = filled ? accent : AppTheme.outline;

    return Material(
      color: enabled ? bg : AppTheme.mist,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: enabled ? border : AppTheme.outline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: enabled ? fg : AppTheme.muted, size: 19),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: enabled ? fg : AppTheme.muted,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
