
import 'package:flutter/material.dart';

import '../../../ui/app_theme.dart';

class AvailabilityCalendar extends StatelessWidget {
  const AvailabilityCalendar({
    super.key,
    required this.unavailableDateKeys,
    required this.bookedDateKeys,
    this.days = 28,
  });

  final List<String> unavailableDateKeys;
  final List<String> bookedDateKeys;
  final int days;

  bool _isIn(List<String> keys, DateTime d) {
    final k =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return keys.contains(k);
  }

  static const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final list = List.generate(days, (i) => start.add(Duration(days: i)));
    final weeks = <List<DateTime>>[];
    for (var i = 0; i < list.length; i += 7) {
      weeks.add(list.sublist(i, (i + 7).clamp(0, list.length)));
    }

    final freeCount = list.where((d) => !_isIn(bookedDateKeys, d) && !_isIn(unavailableDateKeys, d)).length;
    final bookedCount = list.where((d) => _isIn(bookedDateKeys, d)).length;
    final unavailableCount = list.where((d) => !_isIn(bookedDateKeys, d) && _isIn(unavailableDateKeys, d)).length;

    return Container(
      width: double.infinity,
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
          const Text(
            'Availability',
            style: TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Next $days days',
            style: TextStyle(
              color: AppTheme.muted.withAlpha(205),
              fontWeight: FontWeight.w800,
              fontSize: 11.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _weekdayLabels
                .map(
                  (e) => Expanded(
                    child: Text(
                      e,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.ink.withAlpha(155),
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          ...weeks.map(
            (week) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: List.generate(7, (index) {
                  if (index >= week.length) {
                    return const Expanded(child: SizedBox());
                  }
                  final d = week[index];
                  final booked = _isIn(bookedDateKeys, d);
                  final unavailable = _isIn(unavailableDateKeys, d) && !booked;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _DayCell(
                        date: d,
                        booked: booked,
                        unavailable: unavailable,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: const [
              _LegendDot(color: Color(0xFF2F9A6A), label: 'Free'),
              _LegendDot(color: Color(0xFFE05555), label: 'Booked'),
              _LegendDot(color: Color(0xFF757575), label: 'Unavailable'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$freeCount free • $bookedCount booked • $unavailableCount unavailable',
            style: TextStyle(
              color: AppTheme.ink.withAlpha(178),
              fontWeight: FontWeight.w800,
              fontSize: 12.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.booked,
    required this.unavailable,
  });

  final DateTime date;
  final bool booked;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final available = !booked && !unavailable;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cellDate = DateTime(date.year, date.month, date.day);
    final isToday = cellDate == today;

    final bg = booked
        ? const Color(0xFFFFEBEB)
        : unavailable
            ? const Color(0xFFF2F2F2)
            : const Color(0xFFE9FFF5);

    final fg = booked
        ? const Color(0xFFE05555)
        : unavailable
            ? const Color(0xFF757575)
            : const Color(0xFF2F9A6A);

    final border = isToday
        ? const Color(0xFF6F7BFF)
        : booked
            ? const Color(0xFFFFC7C7)
            : unavailable
                ? AppTheme.outline
                : const Color(0xFFBFEEDB);

    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: isToday ? 1.6 : 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${date.day}',
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            available ? 'Free' : booked ? 'Booked' : 'Off',
            style: TextStyle(
              color: fg.withAlpha(230),
              fontWeight: FontWeight.w900,
              fontSize: 10.4,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            width: 20,
            height: 6,
            decoration: BoxDecoration(
              color: fg.withAlpha(220),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.ink.withAlpha(175),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
