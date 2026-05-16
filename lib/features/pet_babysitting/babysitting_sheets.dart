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
  final _petName = TextEditingController();
  final _petType = TextEditingController();
  final _msg = TextEditingController();

  bool _loading = false;
  DateTimeRange? _range;
  String _handoff = 'Drop-off';

  static const int _maxMessage = 800;

  @override
  void dispose() {
    _petName.dispose();
    _petType.dispose();
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

  List<String> _selectedDateKeys() {
    final r = _range;
    if (r == null) return const [];
    return babysittingExpandDateRangeKeys(r);
  }

  List<String> _blockedSelectedDateKeys() {
    final selected = _selectedDateKeys();
    if (selected.isEmpty) return const [];

    final blocked = <String>{
      ...widget.listing.unavailableDateKeys,
      ...widget.listing.bookedDateKeys,
    };

    return selected.where(blocked.contains).toList();
  }

  String _blockedDatesLabel(List<String> keys) {
    if (keys.isEmpty) return '';
    if (keys.length == 1) return keys.first;
    if (keys.length == 2) return '${keys.first} and ${keys.last}';
    return '${keys.first}, ${keys[1]} +${keys.length - 2} more';
  }

  void _appendCareDetail(String text) {
    final current = _msg.text.trim();
    final next = current.isEmpty ? text : '$current\n$text';
    if (next.length > _maxMessage) return;
    _msg.text = next;
    _msg.selection = TextSelection.fromPosition(
      TextPosition(offset: _msg.text.length),
    );
    setState(() {});
  }

  String _finalMessage() {
    final petName = _petName.text.trim();
    final petType = _petType.text.trim();
    final care = _msg.text.trim();
    final lines = <String>[
      if (petName.isNotEmpty) 'Pet name: $petName',
      if (petType.isNotEmpty) 'Pet type: $petType',
      'Dates: ${_rangeLabel()}',
      'Handoff preference: $_handoff',
      '',
      'Care details:',
      care,
    ];
    return lines.where((line) => line.trim().isNotEmpty).join('\n');
  }

  Future<bool> _confirmRequest() async {
    final listing = widget.listing;
    final days = _daysCount();
    final price = listing.priceText.trim().isEmpty
        ? 'Confirm final price in chat'
        : listing.priceText.trim();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Send stay request?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogLine(icon: Icons.event_rounded, text: _rangeLabel()),
              const SizedBox(height: 10),
              _DialogLine(
                icon: Icons.today_rounded,
                text: '$days day${days == 1 ? '' : 's'} requested',
              ),
              const SizedBox(height: 10),
              _DialogLine(icon: Icons.payments_rounded, text: price),
              const SizedBox(height: 14),
              Text(
                'The sitter will receive dates and care notes. Confirm price, handoff, and emergency contact in chat.',
                style: TextStyle(
                  color: AppTheme.muted.withAlpha(230),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Review'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Send stay request'),
            ),
          ],
        );
      },
    );
    return ok == true;
  }

  Future<void> _submit() async {
    final msg = _msg.text.trim();
    if (_range == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please choose dates.')));
      return;
    }
    if (_petType.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add your pet type.')),
      );
      return;
    }
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a short care message.')),
      );
      return;
    }

    final blocked = _blockedSelectedDateKeys();
    if (blocked.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Some selected dates are unavailable: ${_blockedDatesLabel(blocked)}',
          ),
        ),
      );
      return;
    }

    final confirmed = await _confirmRequest();
    if (!confirmed || !mounted) return;

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
        message: _finalMessage(),
        dateRangeText: dateRangeText,
        requestedDateKeys: requestedDateKeys,
        startDateKey: startDateKey,
        endDateKey: endDateKey,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Stay request sent to ${widget.listing.authorName}. You will be notified when they reply.',
          ),
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
    final blockedDates = _blockedSelectedDateKeys();
    final hasDates = _range != null;

    return _BottomSheetFrame(
      title: 'Request this stay',
      subtitle: 'Send dates and pet details to ${listing.authorName}',
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
          _OwnerBookingChecklist(hasDates: hasDates, blockedDates: blockedDates),
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
                  'Unavailable or booked dates cannot be requested.',
            ),
          ],
          if (blockedDates.isNotEmpty) ...[
            const SizedBox(height: 10),
            _HintCard(
              icon: Icons.warning_amber_rounded,
              iconBg: const Color(0xFFFFEBEB),
              iconFg: const Color(0xFFE05555),
              text:
                  'Unavailable dates selected: ${_blockedDatesLabel(blockedDates)}. Please change the range.',
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _petName,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Pet name',
                    hintText: 'Miso',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _petType,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Pet type',
                    hintText: 'Cat, dog...',
                    prefixIcon: Icon(Icons.pets_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _HandoffSelector(
            value: _handoff,
            onChanged: _loading ? null : (v) => setState(() => _handoff = v),
          ),
          const SizedBox(height: 12),
          const Text(
            'Quick care details',
            style: TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CareQuickChip(
                label: 'Feeding routine',
                onTap: () => _appendCareDetail('Feeding routine: '),
              ),
              _CareQuickChip(
                label: 'Medication',
                onTap: () => _appendCareDetail('Medication or allergies: '),
              ),
              _CareQuickChip(
                label: 'Behavior',
                onTap: () => _appendCareDetail('Behavior with people/pets: '),
              ),
              _CareQuickChip(
                label: 'Updates',
                onTap: () => _appendCareDetail('Preferred updates: photos/messages.'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _msg,
            maxLines: 5,
            maxLength: _maxMessage,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Care message',
              hintText:
                  'Pet routine, medication, behavior, handoff, and key notes.',
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
                color: remaining < 0
                    ? const Color(0xFFD64545)
                    : AppTheme.ink.withAlpha(145),
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _HintCard(
            icon: Icons.shield_outlined,
            iconBg: AppTheme.mint,
            iconFg: const Color(0xFF2F9A6A),
            text:
                'Before the stay, confirm price, address, handoff, and emergency contact in chat.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading || remaining < 0 ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orangeDark,
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
              label: const Text('Review and send request'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerBookingChecklist extends StatelessWidget {
  const _OwnerBookingChecklist({
    required this.hasDates,
    required this.blockedDates,
  });

  final bool hasDates;
  final List<String> blockedDates;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          _ChecklistLine(
            done: hasDates && blockedDates.isEmpty,
            text: hasDates && blockedDates.isEmpty
                ? 'Dates are ready'
                : 'Choose available stay dates',
          ),
          const SizedBox(height: 8),
          const _ChecklistLine(
            done: false,
            text: 'Add pet routine, behavior, and special care notes',
          ),
          const SizedBox(height: 8),
          const _ChecklistLine(
            done: false,
            text: 'Use chat after sending to confirm price and handoff',
          ),
        ],
      ),
    );
  }
}

class _ChecklistLine extends StatelessWidget {
  const _ChecklistLine({required this.done, required this.text});

  final bool done;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: done ? const Color(0xFF2F9A6A) : AppTheme.muted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.ink.withAlpha(210),
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _HandoffSelector extends StatelessWidget {
  const _HandoffSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    const items = ['Drop-off', 'Pickup', 'Discuss in chat'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          ChoiceChip(
            selected: value == item,
            label: Text(item),
            avatar: Icon(
              item == 'Pickup'
                  ? Icons.directions_car_rounded
                  : item == 'Drop-off'
                      ? Icons.home_work_rounded
                      : Icons.chat_bubble_outline_rounded,
              size: 16,
            ),
            onSelected: onChanged == null ? null : (_) => onChanged!(item),
            selectedColor: AppTheme.blush,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w900,
              color: value == item ? AppTheme.orangeDark : AppTheme.ink,
            ),
            shape: StadiumBorder(side: BorderSide(color: AppTheme.outline)),
          ),
      ],
    );
  }
}

class _CareQuickChip extends StatelessWidget {
  const _CareQuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: const Icon(Icons.add_rounded, size: 16),
      label: Text(label),
      backgroundColor: AppTheme.bg,
      side: BorderSide(color: AppTheme.outline),
      labelStyle: const TextStyle(
        color: AppTheme.ink,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _DialogLine extends StatelessWidget {
  const _DialogLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.orangeDark),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ),
      ],
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
      ).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Review published. Thanks for helping other owners.'),
        ),
      );
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
      title: 'Review this stay',
      subtitle: 'Help other pet owners choose trusted sitters',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionCard(
            icon: Icons.verified_rounded,
            iconBg: AppTheme.mint,
            iconFg: const Color(0xFF2F9A6A),
            title: 'Stay completed',
            subtitle:
                'Your review helps build trust for future bookings.',
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
                'Useful reviews mention communication, timing, and pet comfort.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orangeDark,
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
              label: const Text('Publish review'),
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
