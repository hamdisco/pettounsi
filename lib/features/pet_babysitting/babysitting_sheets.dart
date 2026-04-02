import 'package:flutter/material.dart';
import '../../ui/premium_sheet.dart';
import '../../ui/app_theme.dart';
import '../../ui/user_avatar.dart';
import 'babysitting_repository.dart';

class CreateRequestSheet extends StatefulWidget {
  const CreateRequestSheet({super.key, required this.listing});

  final BabysittingListing listing;

  @override
  State<CreateRequestSheet> createState() => _CreateRequestSheetState();
}

class _CreateRequestSheetState extends State<CreateRequestSheet> {
  final _msg = TextEditingController();
  bool _loading = false;
  DateTimeRange? _range;

  static const int _maxMessage = 800;

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final end = start.add(const Duration(days: 2));

    final r = await showDateRangePicker(
      context: context,
      firstDate: start,
      lastDate: start.add(const Duration(days: 365)),
      initialDateRange: _range ?? DateTimeRange(start: start, end: end),
    );
    if (r == null) return;
    setState(() => _range = r);
  }

  String _rangeLabel() {
    final r = _range;
    if (r == null) return 'Choose dates';
    final a = '${r.start.day}/${r.start.month}/${r.start.year}';
    final b = '${r.end.day}/${r.end.month}/${r.end.year}';
    return '$a → $b';
  }

  int _daysCount() {
    final r = _range;
    if (r == null) return 0;
    return r.end.difference(r.start).inDays + 1;
  }

  Future<void> _submit() async {
    final msg = _msg.text.trim();
    if (_range == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please choose dates.')));
      return;
    }
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a short message.')),
      );
      return;
    }

    final range = _range!;
    final startDateKey = babysittingDateKey(range.start);
    final endDateKey = babysittingDateKey(range.end);
    final dateRangeText = _rangeLabel();

    final requestedDateKeys = <String>[];
    DateTime d = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    while (!d.isAfter(end)) {
      requestedDateKeys.add(babysittingDateKey(d));
      d = d.add(const Duration(days: 1));
    }

    setState(() => _loading = true);
    try {
      await BabysittingRepository.instance.createRequest(
        listing: widget.listing,
        message: msg,
        dateRangeText: dateRangeText,
        requestedDateKeys: requestedDateKeys,
        startDateKey: startDateKey,
        endDateKey: endDateKey,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request sent to ${widget.listing.authorName}.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send request: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final place =
        '${listing.city}${listing.governorate.trim().isEmpty ? '' : ', ${listing.governorate}'}';
    final remaining = _maxMessage - _msg.text.length;

    return _BottomSheetFrame(
      title: 'Request sitter',
      subtitle: 'Send a care request to ${listing.authorName}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ListingMiniHero(listing: listing),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.place_rounded,
                text: place,
                bg: AppTheme.sky,
                fg: const Color(0xFF4C79C8),
              ),
              if (listing.priceText.trim().isNotEmpty)
                _InfoChip(
                  icon: Icons.payments_rounded,
                  text: listing.priceText,
                  bg: AppTheme.mist,
                  fg: AppTheme.orchidDark,
                ),
              _InfoChip(
                icon: Icons.pets_rounded,
                text: listing.petTypes.isEmpty
                    ? 'Any pets'
                    : listing.petTypes.join(' • '),
                bg: AppTheme.lilac,
                fg: const Color(0xFF7C62D7),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.date_range_rounded,
            iconBg: AppTheme.sky,
            iconFg: const Color(0xFF4C79C8),
            title: 'Stay dates',
            subtitle: _range == null
                ? 'Choose the dates you need care for.'
                : '${_rangeLabel()} • ${_daysCount()} day${_daysCount() == 1 ? '' : 's'}',
            trailing: OutlinedButton(
              onPressed: _loading ? null : _pickRange,
              child: Text(_range == null ? 'Pick' : 'Change'),
            ),
          ),
          if (listing.unavailableDateKeys.isNotEmpty ||
              listing.bookedDateKeys.isNotEmpty) ...[
            const SizedBox(height: 10),
            _HintCard(
              icon: Icons.info_outline_rounded,
              iconBg: const Color(0xFFFFF2DB),
              iconFg: const Color(0xFFDA8A1F),
              text:
                  'Some dates may already be unavailable. If the sitter cannot accept your range, choose different dates.',
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _msg,
            maxLines: 5,
            maxLength: _maxMessage,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText:
                  'Introduce yourself, your pet, and any care details the sitter should know.',
              prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
              alignLabelWithHint: true,
              counterText: '',
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$remaining characters left',
              style: TextStyle(
                color: AppTheme.ink.withAlpha(145),
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _HintCard(
            icon: Icons.checklist_rounded,
            iconBg: AppTheme.mint,
            iconFg: const Color(0xFF2F9A6A),
            text:
                'A strong request usually mentions pet type, feeding routine, medication, and pickup or drop-off expectations.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orchidDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: const Text('Send request'),
            ),
          ),
        ],
      ),
    );
  }
}

class LeaveReviewSheet extends StatefulWidget {
  const LeaveReviewSheet({super.key, required this.req});

  final BabysittingRequestModel req;

  @override
  State<LeaveReviewSheet> createState() => _LeaveReviewSheetState();
}

class _LeaveReviewSheetState extends State<LeaveReviewSheet> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _loading = false;

  static const int _maxComment = 500;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  String _ratingLabel() {
    switch (_rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very good';
      default:
        return 'Excellent';
    }
  }

  Future<void> _submit() async {
    final c = _comment.text.trim();
    setState(() => _loading = true);
    try {
      await BabysittingRepository.instance.submitReviewForCompletedRequest(
        req: widget.req,
        rating: _rating,
        comment: c,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Review submitted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not submit review: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _maxComment - _comment.text.length;

    return _BottomSheetFrame(
      title: 'Leave a review',
      subtitle: widget.req.listingTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionCard(
            icon: Icons.verified_rounded,
            iconBg: AppTheme.mint,
            iconFg: const Color(0xFF2F9A6A),
            title: 'Completed stay',
            subtitle:
                'Share how the babysitting experience went to help future pet owners.',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: AppTheme.bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your rating',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                _Stars(
                  value: _rating,
                  onChanged: _loading
                      ? null
                      : (v) => setState(() => _rating = v),
                ),
                const SizedBox(height: 8),
                Text(
                  _ratingLabel(),
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(220),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _comment,
            maxLines: 5,
            maxLength: _maxComment,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Comment (optional)',
              hintText:
                  'Mention responsiveness, care quality, communication, or anything helpful for other users.',
              prefixIcon: Icon(Icons.notes_rounded),
              alignLabelWithHint: true,
              counterText: '',
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$remaining characters left',
              style: TextStyle(
                color: AppTheme.ink.withAlpha(145),
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _HintCard(
            icon: Icons.tips_and_updates_rounded,
            iconBg: AppTheme.sky,
            iconFg: const Color(0xFF4C79C8),
            text:
                'The most useful reviews mention communication, punctuality, pet comfort, and whether expectations matched reality.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orchidDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.star_rounded, size: 18),
              label: const Text('Submit review'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingMiniHero extends StatelessWidget {
  const _ListingMiniHero({required this.listing});

  final BabysittingListing listing;

  @override
  Widget build(BuildContext context) {
    final place =
        '${listing.city}${listing.governorate.trim().isEmpty ? '' : ', ${listing.governorate}'}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppTheme.blush, AppTheme.lilac, AppTheme.sky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(235),
              border: Border.all(color: Colors.white),
            ),
            child: UserAvatar(
              uid: listing.authorId,
              radius: 20,
              fallbackName: listing.authorName,
              fallbackPhotoUrl: listing.authorPhotoUrl,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${listing.authorName} • $place',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(220),
                    fontWeight: FontWeight.w700,
                    height: 1.15,
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg.withAlpha(185),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: AppTheme.ink.withAlpha(220),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return PremiumSheetInfoCard(
      icon: icon,
      iconBg: iconBg,
      iconFg: iconFg,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.text,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String text;

  @override
  Widget build(BuildContext context) {
    return PremiumSheetInfoCard(
      icon: icon,
      iconBg: iconBg,
      iconFg: iconFg,
      title: 'Helpful note',
      subtitle: text,
      compact: true,
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    Widget star(int i) {
      final filled = i <= value;
      return InkWell(
        onTap: onChanged == null ? null : () => onChanged!(i),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: filled
                ? const Color(0xFFFFB703)
                : AppTheme.muted.withAlpha(200),
            size: 30,
          ),
        ),
      );
    }

    return Row(children: [1, 2, 3, 4, 5].map(star).toList());
  }
}

class _BottomSheetFrame extends StatelessWidget {
  const _BottomSheetFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PremiumBottomSheetFrame(
      icon: Icons.pets_rounded,
      iconColor: const Color(0xFF7C62D7),
      iconBg: AppTheme.lilac,
      title: title,
      subtitle: subtitle,
      child: child,
    );
  }
}
