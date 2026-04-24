import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';
import '../../ui/user_avatar.dart';
import '../messages/chat_page.dart';
import 'babysitting_repository.dart';
import 'babysitting_sheets.dart';
import 'widgets/availability_calendar.dart';

class ListingDetailsPage extends StatelessWidget {
  const ListingDetailsPage({super.key, required this.listing});

  final BabysittingListing listing;

  Stream<List<BabysittingReview>> _streamLatestReviews() {
    return FirebaseFirestore.instance
        .collection('babysitting_reviews')
        .orderBy('createdAt', descending: true)
        .limit(1500)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map(BabysittingReview.fromDoc)
              .where((r) => r.listingId == listing.id)
              .toList();

          list.sort((a, b) {
            final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad);
          });

          return list.take(24).toList();
        });
  }

  String get _location {
    return [
      listing.city.trim(),
      listing.governorate.trim(),
    ].where((e) => e.isNotEmpty).join(', ');
  }

  String get _pets {
    final pets = listing.petTypes.where((e) => e.trim().isNotEmpty).toList();
    if (pets.isEmpty) return 'Any pets';
    if (pets.length == 1) return pets.first;
    if (pets.length == 2) return '${pets[0]} • ${pets[1]}';
    return '${pets.first} +${pets.length - 1}';
  }

  String get _availability {
    final text = listing.availabilityText.trim();
    if (text.isEmpty) return 'Available now';
    final lower = text.toLowerCase();
    if (lower.contains('immed') ||
        lower.contains('today') ||
        lower.contains('now')) {
      return 'Available now';
    }
    if (lower.contains('weekend')) return 'Weekends';
    if (lower.contains('weekday')) return 'Weekdays';
    if (lower.contains('flex')) return 'Flexible schedule';
    return text;
  }

  String get _updatedLabel {
    final date = listing.updatedAt ?? listing.createdAt;
    if (date == null) return 'Recently updated';
    final now = DateTime.now();
    final diff = now
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (diff <= 0) return 'Updated today';
    if (diff == 1) return 'Updated yesterday';
    if (diff < 7) return 'Updated ${diff}d ago';
    return 'Updated on ${date.day}/${date.month}/${date.year}';
  }

  String get _statusText {
    if (!listing.isActive) return 'Paused';
    final blocked =
        listing.unavailableDateKeys.length + listing.bookedDateKeys.length;
    if (blocked >= 8) return 'Limited dates';
    return 'Live listing';
  }

  Color get _statusBg {
    if (!listing.isActive) return AppTheme.blush;
    final blocked =
        listing.unavailableDateKeys.length + listing.bookedDateKeys.length;
    if (blocked >= 8) return AppTheme.butter;
    return AppTheme.mint;
  }

  Color get _statusFg {
    if (!listing.isActive) return AppTheme.roseDark;
    final blocked =
        listing.unavailableDateKeys.length + listing.bookedDateKeys.length;
    if (blocked >= 8) return const Color(0xFF8A5A00);
    return const Color(0xFF2F9A6A);
  }

  Future<void> _openChat(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          otherUid: listing.authorId,
          otherName: listing.authorName,
          otherPhoto: listing.authorPhotoUrl.trim().isEmpty
              ? null
              : listing.authorPhotoUrl,
        ),
      ),
    );
  }

  Future<void> _openRequest(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateRequestSheet(listing: listing),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Listing details',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 118),
        children: [
          _DetailsHero(
            listing: listing,
            location: _location,
            pets: _pets,
            availability: _availability,
            updatedLabel: _updatedLabel,
            statusText: _statusText,
            statusBg: _statusBg,
            statusFg: _statusFg,
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Overview',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _FactCard(
                        icon: Icons.payments_rounded,
                        label: 'Rate',
                        value: listing.priceText.trim().isEmpty
                            ? 'Ask in chat'
                            : listing.priceText,
                        iconBg: AppTheme.mist,
                        iconFg: AppTheme.orchidDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FactCard(
                        icon: Icons.pets_rounded,
                        label: 'Pets',
                        value: _pets,
                        iconBg: AppTheme.lilac,
                        iconFg: AppTheme.orchidDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _FactCard(
                        icon: Icons.schedule_rounded,
                        label: 'Availability',
                        value: _availability,
                        iconBg: AppTheme.mint,
                        iconFg: const Color(0xFF2F9A6A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FactCard(
                        icon: Icons.location_on_rounded,
                        label: 'Location',
                        value: _location.isEmpty ? 'Tunisia' : _location,
                        iconBg: AppTheme.sky,
                        iconFg: const Color(0xFF4C79C8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'About this sitter',
            child: Text(
              listing.description.trim().isEmpty
                  ? 'This sitter has not added a description yet.'
                  : listing.description,
              style: TextStyle(
                color: AppTheme.ink.withAlpha(182),
                fontWeight: FontWeight.w700,
                height: 1.42,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Availability',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InlineInfoCard(
                        title: 'Open for requests',
                        value: listing.isActive ? 'Yes' : 'Paused',
                        icon: Icons.schedule_rounded,
                        bg: AppTheme.mint,
                        fg: const Color(0xFF2F9A6A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InlineInfoCard(
                        title: 'Blocked dates',
                        value:
                            '${listing.unavailableDateKeys.length + listing.bookedDateKeys.length}',
                        icon: Icons.event_busy_rounded,
                        bg: AppTheme.butter,
                        fg: const Color(0xFF8A5A00),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AvailabilityCalendar(
                  unavailableDateKeys: listing.unavailableDateKeys,
                  bookedDateKeys: listing.bookedDateKeys,
                  days: 28,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Reviews',
            child: StreamBuilder<List<BabysittingReview>>(
              stream: _streamLatestReviews(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return Text(
                    'No reviews yet. Reviews will appear here after completed stays.',
                    style: TextStyle(
                      color: AppTheme.muted.withAlpha(220),
                      fontWeight: FontWeight.w700,
                      height: 1.34,
                    ),
                  );
                }

                final average =
                    items
                    // ignore: avoid_types_as_parameter_names
                    .fold<num>(0, (sum, item) => sum + item.rating) /
                    items.length;

                return Column(
                  children: [
                    _ReviewSummaryBanner(
                      count: items.length,
                      average: average.toDouble(),
                    ),
                    const SizedBox(height: 12),
                    ...items.take(8).map((r) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ReviewTile(r: r),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bg,
          border: Border(top: BorderSide(color: AppTheme.outline)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start with a chat or send your stay request directly.',
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(220),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.1,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openChat(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.ink,
                          side: const BorderSide(color: AppTheme.outline),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Chat first',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openRequest(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.orchidDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text(
                          'Request stay',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
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

class _DetailsHero extends StatelessWidget {
  const _DetailsHero({
    required this.listing,
    required this.location,
    required this.pets,
    required this.availability,
    required this.updatedLabel,
    required this.statusText,
    required this.statusBg,
    required this.statusFg,
  });

  final BabysittingListing listing;
  final String location;
  final String pets;
  final String availability;
  final String updatedLabel;
  final String statusText;
  final Color statusBg;
  final Color statusFg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [AppTheme.blush, AppTheme.lilac, AppTheme.sky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusFg,
                    fontWeight: FontWeight.w900,
                    fontSize: 11.6,
                  ),
                ),
              ),
              const Spacer(),
              _HeroRatingBadge(listingId: listing.id),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            listing.title,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: -0.4,
              height: 1.04,
            ),
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.place_rounded,
                  size: 18,
                  color: AppTheme.muted.withAlpha(188),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      color: AppTheme.muted.withAlpha(220),
                      fontWeight: FontWeight.w800,
                      fontSize: 13.8,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            updatedLabel,
            style: TextStyle(
              color: AppTheme.muted.withAlpha(210),
              fontWeight: FontWeight.w700,
              fontSize: 11.8,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(210),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white),
            ),
            child: Row(
              children: [
                UserAvatar(
                  uid: listing.authorId,
                  radius: 22,
                  fallbackName: listing.authorName,
                  fallbackPhotoUrl: listing.authorPhotoUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.authorName,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 15.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sitter profile',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.muted.withAlpha(218),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (listing.priceText.trim().isNotEmpty)
                _HeroChip(
                  icon: Icons.payments_rounded,
                  text: listing.priceText,
                  bg: AppTheme.mist,
                  fg: AppTheme.orchidDark,
                ),
              _HeroChip(
                icon: Icons.schedule_rounded,
                text: availability,
                bg: AppTheme.mint,
                fg: const Color(0xFF2F9A6A),
              ),
              _HeroChip(
                icon: Icons.pets_rounded,
                text: pets,
                bg: AppTheme.surface,
                fg: AppTheme.ink,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroRatingBadge extends StatelessWidget {
  const _HeroRatingBadge({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BabysitterRatingSummary>(
      stream: BabysittingRepository.instance.streamListingRatingSummary(
        listingId,
        limit: 200,
      ),
      builder: (context, snap) {
        final s = snap.data ?? BabysitterRatingSummary.empty;
        if (s.count == 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(228),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white),
            ),
            child: Text(
              'New',
              style: TextStyle(
                color: AppTheme.ink.withAlpha(185),
                fontWeight: FontWeight.w900,
                fontSize: 12.2,
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(228),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: Color(0xFFFFB703),
              ),
              const SizedBox(width: 4),
              Text(
                s.average.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.2,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${s.count})',
                style: TextStyle(
                  color: AppTheme.muted.withAlpha(215),
                  fontWeight: FontWeight.w800,
                  fontSize: 11.8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.text,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 11.9,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
        color: Colors.white,
        boxShadow: AppTheme.softShadows(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InlineInfoCard extends StatelessWidget {
  const _InlineInfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: fg, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(220),
                    fontWeight: FontWeight.w800,
                    fontSize: 11.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
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

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBg,
    required this.iconFg,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconBg;
  final Color iconFg;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white),
            ),
            child: Icon(icon, color: iconFg, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(220),
                    fontWeight: FontWeight.w800,
                    fontSize: 11.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    height: 1.16,
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

class _ReviewSummaryBanner extends StatelessWidget {
  const _ReviewSummaryBanner({required this.count, required this.average});

  final int count;
  final double average;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.butter,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Color(0xFFFFB703),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${average.toStringAsFixed(1)} average rating',
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count review${count == 1 ? '' : 's'} from completed stays',
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(220),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.r});
  final BabysittingReview r;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          UserAvatar(
            uid: r.requesterId,
            radius: 16,
            fallbackName: r.requesterName,
            fallbackPhotoUrl: r.requesterPhotoUrl,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.requesterName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (i) {
                    final on = i < r.rating;
                    return Icon(
                      on ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 16,
                      color: on
                          ? const Color(0xFFFFB703)
                          : AppTheme.muted.withAlpha(200),
                    );
                  }),
                ),
                if (r.comment.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    r.comment,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.ink.withAlpha(175),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
