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
    return BabysittingRepository.instance.streamListingReviewModels(
      listing.id,
      limit: 24,
    );
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
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 108),
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
          _TrustProfileCard(listing: listing, updatedLabel: _updatedLabel),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'About',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.description.trim().isEmpty
                      ? 'No description yet.'
                      : listing.description.trim(),
                  style: TextStyle(
                    color: AppTheme.ink.withAlpha(186),
                    fontWeight: FontWeight.w700,
                    height: 1.42,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FactCard(
                        icon: Icons.payments_rounded,
                        label: 'Price',
                        value: listing.priceText.trim().isEmpty
                            ? 'Ask in chat'
                            : listing.priceText.trim(),
                        iconBg: AppTheme.mist,
                        iconFg: AppTheme.orchidDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FactCard(
                        icon: Icons.pets_rounded,
                        label: 'Pet types',
                        value: _pets,
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
            title: 'Availability',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompactAvailabilityLine(
                  isActive: listing.isActive,
                  availability: _availability,
                  blockedCount:
                      listing.unavailableDateKeys.length +
                      listing.bookedDateKeys.length,
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
          _OwnerBookingPrepCard(priceText: listing.priceText),
          const SizedBox(height: 12),
          const _TrustChecklistCard(),
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
                    'No reviews yet.',
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
                      reviews: items,
                    ),
                    const SizedBox(height: 12),
                    _ReviewHighlightsCard(reviews: items),
                    const SizedBox(height: 12),
                    ...items.take(6).map((r) {
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
                  'Send dates and care notes. Confirm handoff and payment in chat.',
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
                          'Chat',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openRequest(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.orangeDark,
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

class _CompactAvailabilityLine extends StatelessWidget {
  const _CompactAvailabilityLine({
    required this.isActive,
    required this.availability,
    required this.blockedCount,
  });

  final bool isActive;
  final String availability;
  final int blockedCount;

  @override
  Widget build(BuildContext context) {
    final status = isActive ? availability : 'Paused';
    final busy = blockedCount == 0
        ? 'No blocked dates'
        : '$blockedCount blocked date${blockedCount == 1 ? '' : 's'}';

    return Row(
      children: [
        Expanded(
          child: _InlineInfoCard(
            title: 'Status',
            value: status,
            icon: Icons.schedule_rounded,
            bg: isActive ? AppTheme.mint : AppTheme.blush,
            fg: isActive ? const Color(0xFF2F9A6A) : AppTheme.roseDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InlineInfoCard(
            title: 'Calendar',
            value: busy,
            icon: Icons.event_available_rounded,
            bg: blockedCount > 0 ? AppTheme.butter : AppTheme.sky,
            fg: blockedCount > 0
                ? const Color(0xFF8A5A00)
                : const Color(0xFF4C79C8),
          ),
        ),
      ],
    );
  }
}

class _OwnerBookingPrepCard extends StatelessWidget {
  const _OwnerBookingPrepCard({required this.priceText});

  final String priceText;

  @override
  Widget build(BuildContext context) {
    final price = priceText.trim().isEmpty
        ? 'Confirm price in chat'
        : priceText.trim();
    return _SectionCard(
      title: 'Before you request',
      child: Column(
        children: [
          _PrepLine(
            icon: Icons.pets_rounded,
            text:
                'Prepare your pet name, pet type, routine, and special care notes.',
          ),
          const SizedBox(height: 10),
          _PrepLine(
            icon: Icons.event_available_rounded,
            text:
                'Choose dates that do not overlap unavailable or booked days.',
          ),
          const SizedBox(height: 10),
          _PrepLine(
            icon: Icons.payments_rounded,
            text:
                '$price • confirm final payment details directly with the sitter.',
          ),
        ],
      ),
    );
  }
}

class _PrepLine extends StatelessWidget {
  const _PrepLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.blush,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.orangeDark, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.ink.withAlpha(205),
              fontWeight: FontWeight.w700,
              height: 1.34,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrustProfileCard extends StatelessWidget {
  const _TrustProfileCard({required this.listing, required this.updatedLabel});

  final BabysittingListing listing;
  final String updatedLabel;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = listing.authorPhotoUrl.trim().isNotEmpty;
    final blockedDates =
        listing.unavailableDateKeys.length + listing.bookedDateKeys.length;

    return StreamBuilder<BabysitterRatingSummary>(
      stream: BabysittingRepository.instance.streamListingRatingSummary(
        listing.id,
        limit: 250,
      ),
      builder: (context, snap) {
        final summary = snap.data ?? BabysitterRatingSummary.empty;
        final ratingTitle = summary.hasReviews
            ? summary.average.toStringAsFixed(1)
            : 'New';
        final ratingSubtitle = summary.hasReviews
            ? '${summary.count} review${summary.count == 1 ? '' : 's'} from completed stays'
            : 'New sitter profile';

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.outline),
            boxShadow: AppTheme.softShadows(0.07),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.butter,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFFB96B00),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trust profile',
                          style: TextStyle(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Real reviews, availability, and chat help you decide with confidence.',
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.4,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TrustScoreTile(
                      icon: Icons.star_rounded,
                      title: ratingTitle,
                      subtitle: ratingSubtitle,
                      bg: AppTheme.butter,
                      fg: const Color(0xFFB96B00),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TrustScoreTile(
                      icon: hasPhoto
                          ? Icons.account_circle_rounded
                          : Icons.person_outline_rounded,
                      title: hasPhoto ? 'Photo' : 'Basic',
                      subtitle: hasPhoto
                          ? 'Profile photo visible'
                          : 'Ask for details in chat',
                      bg: AppTheme.sky,
                      fg: const Color(0xFF4C79C8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TrustScoreTile(
                      icon: Icons.event_available_rounded,
                      title: blockedDates == 0 ? 'Open' : '$blockedDates busy',
                      subtitle: 'Availability signal',
                      bg: blockedDates >= 8 ? AppTheme.butter : AppTheme.mint,
                      fg: blockedDates >= 8
                          ? const Color(0xFF8A5A00)
                          : const Color(0xFF2F9A6A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TrustScoreTile(
                      icon: Icons.update_rounded,
                      title: updatedLabel.replaceFirst('Updated ', ''),
                      subtitle: 'Listing activity',
                      bg: AppTheme.lilac,
                      fg: AppTheme.orchidDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _TrustSignalRow(
                icon: Icons.chat_bubble_outline_rounded,
                text:
                    'Chat first to confirm routine, handoff, pet behavior, emergency contact, and final price.',
              ),
              SizedBox(height: 9),
              _TrustSignalRow(
                icon: Icons.medical_services_outlined,
                text:
                    'Share feeding, medication, allergies, and behavior notes before the stay.',
              ),
              SizedBox(height: 9),
              const _TrustSignalRow(
                icon: Icons.payments_rounded,
                text:
                    'PetTounsi helps you connect; confirm payment details directly with the sitter.',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrustScoreTile extends StatelessWidget {
  const _TrustScoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: fg, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 14.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.muted.withAlpha(220),
              fontWeight: FontWeight.w700,
              fontSize: 11.3,
              height: 1.18,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustSignalRow extends StatelessWidget {
  const _TrustSignalRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3EC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 15, color: AppTheme.orangeDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.ink.withAlpha(178),
              fontWeight: FontWeight.w700,
              height: 1.28,
              fontSize: 12.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrustChecklistCard extends StatelessWidget {
  const _TrustChecklistCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Before you book',
            style: TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 12),
          _TrustChecklistRow(
            icon: Icons.chat_bubble_outline_rounded,
            text: 'Chat first if you need extra details.',
          ),
          SizedBox(height: 9),
          _TrustChecklistRow(
            icon: Icons.payments_rounded,
            text: 'Confirm final price and pickup/drop-off.',
          ),
          SizedBox(height: 9),
          _TrustChecklistRow(
            icon: Icons.medical_services_outlined,
            text: 'Mention feeding, medication, and pet behavior.',
          ),
        ],
      ),
    );
  }
}

class _TrustChecklistRow extends StatelessWidget {
  const _TrustChecklistRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.orangeDark),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.w700,
              height: 1.28,
            ),
          ),
        ),
      ],
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
        color: Colors.white,
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.07),
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
            listing.title.trim().isEmpty
                ? 'Pet sitting service'
                : listing.title.trim(),
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
                      UserName(
                        uid: listing.authorId,
                        fallback: listing.authorName.trim().isEmpty
                            ? 'Pet sitter'
                            : listing.authorName.trim(),
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
  const _ReviewSummaryBanner({
    required this.count,
    required this.average,
    required this.reviews,
  });

  final int count;
  final double average;
  final List<BabysittingReview> reviews;

  @override
  Widget build(BuildContext context) {
    final fiveStar = reviews.where((r) => r.rating >= 5).length;
    final recommended = count == 0 ? 0 : ((fiveStar / count) * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.butter,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Color(0xFFFFB703),
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
                    Text(
                      average.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '/ 5',
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '$count completed stay review${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(220),
                    fontWeight: FontWeight.w800,
                    fontSize: 12.2,
                  ),
                ),
                if (recommended > 0) ...[
                  const SizedBox(height: 5),
                  Text(
                    '$recommended% gave a 5-star experience',
                    style: const TextStyle(
                      color: Color(0xFF2F9A6A),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
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

class _ReviewHighlightsCard extends StatelessWidget {
  const _ReviewHighlightsCard({required this.reviews});

  final List<BabysittingReview> reviews;

  @override
  Widget build(BuildContext context) {
    final comments = reviews.where((r) => r.comment.trim().isNotEmpty).toList();
    if (comments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.outline),
        ),
        child: const Text(
          'Review comments will appear here after owners describe their stay.',
          style: TextStyle(
            color: AppTheme.muted,
            fontWeight: FontWeight.w700,
            height: 1.32,
          ),
        ),
      );
    }

    final best = comments.reduce((a, b) => a.rating >= b.rating ? a : b);
    return Container(
      width: double.infinity,
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.lilac,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              color: AppTheme.orchidDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review highlight',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  best.comment,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.ink.withAlpha(178),
                    fontWeight: FontWeight.w700,
                    height: 1.32,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${best.requesterName} • ${best.rating}/5',
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(220),
                    fontWeight: FontWeight.w900,
                    fontSize: 11.8,
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
