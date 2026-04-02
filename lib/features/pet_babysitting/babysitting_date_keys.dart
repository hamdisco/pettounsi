import '../../core/date_formatters.dart';

/// Helper functions for babysitting date keys.
class BabysittingDateKeys {
  const BabysittingDateKeys._();

  static DateTime? babysittingDateFromKey(String? key) {
    if (key == null) return null;
    return AppDateFmt.parseYmdKey(key);
  }

  static String babysittingDateKey(DateTime date) {
    return AppDateFmt.toYmdKey(date);
  }

  static List<String> babysittingNormalizeDateKeys(List<DateTime> dates) {
    return dates.map((date) => babysittingDateKey(date)).toList();
  }

  static List<DateTime> babysittingExpandDateRangeKeys(
    List<DateTime> range, {
    int maxDays = 30,
  }) {
    if (range.isEmpty) return [];

    final start = range.first;
    final end = range.last;
    final result = <DateTime>[];

    for (int i = 0; start.add(Duration(days: i)).isBefore(end); i++) {
      final day = start.add(Duration(days: i));
      if (result.length >= maxDays) break;
      result.add(day);
    }

    return result;
  }

  static bool babysittingRangeConflictsWithDateKeys(
    List<DateTime> range,
    List<String> blockedKeys,
  ) {
    final expandedKeys = babysittingNormalizeDateKeys(
      babysittingExpandDateRangeKeys(range),
    );
    return expandedKeys.any((key) => blockedKeys.contains(key));
  }
}
