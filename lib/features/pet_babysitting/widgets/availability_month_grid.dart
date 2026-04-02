import 'package:flutter/material.dart';

import '../../../ui/app_theme.dart';

class AvailabilityMonthPager extends StatefulWidget {
  const AvailabilityMonthPager({
    super.key,
    required this.unavailableDateKeys,
    required this.bookedDateKeys,
    this.monthsAhead = 1,
  });

  final List<String> unavailableDateKeys;
  final List<String> bookedDateKeys;

  /// Number of extra months after the current month that the pager can show.
  /// monthsAhead=1 => current + next month (2 pages).
  final int monthsAhead;

  @override
  State<AvailabilityMonthPager> createState() => _AvailabilityMonthPagerState();
}

class _AvailabilityMonthPagerState extends State<AvailabilityMonthPager> {
  late final PageController _pc;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController();
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  bool _isIn(List<String> keys, DateTime d) {
    final k = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return keys.contains(k);
  }

  DateTime _monthForPage(int page) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, 1);
    // move page months forward
    final y = base.year + ((base.month - 1 + page) ~/ 12);
    final m = ((base.month - 1 + page) % 12) + 1;
    return DateTime(y, m, 1);
  }

  int _daysInMonth(DateTime month) {
    final next = (month.month == 12)
        ? DateTime(month.year + 1, 1, 1)
        : DateTime(month.year, month.month + 1, 1);
    return next.subtract(const Duration(days: 1)).day;
  }

  String _monthLabel(DateTime month) {
    const names = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${names[month.month - 1]} ${month.year}';
  }

  void _go(int next) {
    if (next < 0 || next > widget.monthsAhead) return;
    setState(() => _page = next);
    _pc.animateToPage(
      next,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.monthsAhead + 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Calendar',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Previous month',
                onPressed: _page > 0 ? () => _go(_page - 1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                _monthLabel(_monthForPage(_page)),
                style: TextStyle(
                  color: AppTheme.ink.withAlpha(210),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: _page < widget.monthsAhead ? () => _go(_page + 1) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _DowRow(),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: PageView.builder(
              controller: _pc,
              itemCount: pages,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final month = _monthForPage(i);
                return _MonthGrid(
                  month: month,
                  daysInMonth: _daysInMonth(month),
                  isBooked: (d) => _isIn(widget.bookedDateKeys, d),
                  isUnavailable: (d) => _isIn(widget.unavailableDateKeys, d),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _LegendDot(color: Color(0xFF2F9A6A), label: 'Free'),
              _LegendDot(color: Color(0xFFE05555), label: 'Booked'),
              _LegendDot(color: Color(0xFF757575), label: 'Unavailable'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DowRow extends StatelessWidget {
  const _DowRow();

  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: labels
          .map(
            (t) => Expanded(
              child: Text(
                t,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.muted.withAlpha(220),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

enum _DayStatus { free, booked, unavailable, past }

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.daysInMonth,
    required this.isBooked,
    required this.isUnavailable,
  });

  final DateTime month;
  final int daysInMonth;
  final bool Function(DateTime) isBooked;
  final bool Function(DateTime) isUnavailable;

  bool _isPast(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return d.isBefore(today);
  }

  _DayStatus _status(DateTime d) {
    if (_isPast(d)) return _DayStatus.past;
    if (isBooked(d)) return _DayStatus.booked;
    if (isUnavailable(d)) return _DayStatus.unavailable;
    return _DayStatus.free;
  }

  String _titleFor(_DayStatus s) {
    switch (s) {
      case _DayStatus.booked:
        return 'Booked';
      case _DayStatus.unavailable:
        return 'Unavailable';
      case _DayStatus.past:
        return 'Past';
      default:
        return 'Free';
    }
  }

  Color _bgFor(_DayStatus s) {
    switch (s) {
      case _DayStatus.booked:
        return const Color(0xFFFFEBEB);
      case _DayStatus.unavailable:
        return const Color(0xFFF2F2F2);
      case _DayStatus.past:
        return const Color(0xFFF7F7F7);
      default:
        return const Color(0xFFE9FFF5);
    }
  }

  Color _fgFor(_DayStatus s) {
    switch (s) {
      case _DayStatus.booked:
        return const Color(0xFFE05555);
      case _DayStatus.unavailable:
        return const Color(0xFF757575);
      case _DayStatus.past:
        return const Color(0xFF9A9A9A);
      default:
        return const Color(0xFF2F9A6A);
    }
  }

  Color _borderFor(_DayStatus s) {
    switch (s) {
      case _DayStatus.booked:
        return const Color(0xFFFFC7C7);
      case _DayStatus.unavailable:
        return AppTheme.outline;
      case _DayStatus.past:
        return AppTheme.outline;
      default:
        return const Color(0xFFBFEEDB);
    }
  }

  String _dateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _showDaySheet(BuildContext context, DateTime d, _DayStatus s) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayStatusSheet(
        dateLabel: _dateLabel(d),
        statusTitle: _titleFor(s),
        status: s,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final leading = first.weekday - 1; // Monday-based 0..6

    final total = leading + daysInMonth;
    final cells = ((total + 6) ~/ 7) * 7; // pad to full weeks

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: cells,
      itemBuilder: (context, idx) {
        final day = idx - leading + 1;
        if (day < 1 || day > daysInMonth) {
          return const SizedBox.shrink();
        }

        final d = DateTime(month.year, month.month, day);
        final s = _status(d);

        final bg = _bgFor(s);
        final fg = _fgFor(s);
        final border = _borderFor(s);

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showDaySheet(context, d, s),
          child: Ink(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DayStatusSheet extends StatelessWidget {
  const _DayStatusSheet({
    required this.dateLabel,
    required this.statusTitle,
    required this.status,
  });

  final String dateLabel;
  final String statusTitle;
  final _DayStatus status;

  Color _badgeBg() {
    switch (status) {
      case _DayStatus.booked:
        return const Color(0xFFFFEBEB);
      case _DayStatus.unavailable:
        return const Color(0xFFF2F2F2);
      case _DayStatus.past:
        return const Color(0xFFF7F7F7);
      default:
        return const Color(0xFFE9FFF5);
    }
  }

  Color _badgeFg() {
    switch (status) {
      case _DayStatus.booked:
        return const Color(0xFFE05555);
      case _DayStatus.unavailable:
        return const Color(0xFF757575);
      case _DayStatus.past:
        return const Color(0xFF9A9A9A);
      default:
        return const Color(0xFF2F9A6A);
    }
  }

  IconData _icon() {
    switch (status) {
      case _DayStatus.booked:
        return Icons.event_busy_rounded;
      case _DayStatus.unavailable:
        return Icons.block_rounded;
      case _DayStatus.past:
        return Icons.history_rounded;
      default:
        return Icons.event_available_rounded;
    }
  }

  String _body() {
    switch (status) {
      case _DayStatus.booked:
        return 'This date is already booked.';
      case _DayStatus.unavailable:
        return 'This date is marked as unavailable.';
      case _DayStatus.past:
        return 'This date is in the past.';
      default:
        return 'This date is currently available.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppTheme.outline),
            boxShadow: AppTheme.softShadows(0.22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
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
                          shape: BoxShape.circle,
                          color: _badgeBg(),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        child: Icon(_icon(), color: _badgeFg()),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusTitle,
                              style: TextStyle(
                                color: _badgeFg(),
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _body(),
                              style: TextStyle(
                                color: AppTheme.ink.withAlpha(175),
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.ink.withAlpha(190),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
