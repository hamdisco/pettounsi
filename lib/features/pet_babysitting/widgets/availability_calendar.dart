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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final list = List.generate(days, (i) => start.add(Duration(days: i)));

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
          const Text(
            'Availability',
            style: TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: list.map((d) {
                final booked = _isIn(bookedDateKeys, d);
                final unavailable = _isIn(unavailableDateKeys, d);
                final available = !booked && !unavailable;

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

                final border = booked
                    ? const Color(0xFFFFC7C7)
                    : unavailable
                        ? AppTheme.outline
                        : const Color(0xFFBFEEDB);

                final label = ['S', 'M', 'T', 'W', 'T', 'F', 'S'][d.weekday % 7];

                return Container(
                  width: 64,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: fg.withAlpha(220),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        d.day.toString(),
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        available
                            ? 'Free'
                            : booked
                                ? 'Booked'
                                : 'Off',
                        style: TextStyle(
                          color: fg.withAlpha(230),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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
