/// Lightweight date/time formatters with no extra package dependency.
/// Useful for Firestore Timestamp -> DateTime UI rendering.
///
/// Firestore note:
/// - This file does NOT read/write Firestore.
/// - Pass DateTime values obtained from FsCast.dt(...) or Timestamp.toDate().
class AppDateFmt {
  const AppDateFmt._();

  static const List<String> _monthsShort = <String>[
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

  static String two(int n) => n < 10 ? '0$n' : '$n';

  static String ymd(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
  }

  static String dMy(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day} ${_monthsShort[dt.month - 1]} ${dt.year}';
  }

  static String dMyHm(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day} ${_monthsShort[dt.month - 1]} ${dt.year} • ${hm(dt)}';
  }

  static String hm(DateTime? dt, {bool use24h = true}) {
    if (dt == null) return '';
    if (use24h) {
      return '${two(dt.hour)}:${two(dt.minute)}';
    }

    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${two(dt.minute)} $ampm';
  }

  static String shortDateOrRelative(DateTime? dt, {DateTime? now}) {
    if (dt == null) return '';
    final n = now ?? DateTime.now();
    final diff = n.difference(dt);

    if (diff.inSeconds < 45) return 'now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    return dMy(dt);
  }

  static bool sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String chatDayLabel(DateTime? dt, {DateTime? now}) {
    if (dt == null) return '';
    final n = now ?? DateTime.now();

    final today = DateTime(n.year, n.month, n.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(day).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';
    return dMy(dt);
  }

  static String rangeLabel(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';
    if (start != null && end == null) return dMy(start);
    if (start == null && end != null) return dMy(end);

    if (sameDay(start, end)) {
      return dMy(start);
    }

    return '${dMy(start)} → ${dMy(end)}';
  }

  /// Safe parsing of date-only keys like "2026-02-23" used in availability maps.
  static DateTime? parseYmdKey(String? key) {
    final s = (key ?? '').trim();
    if (s.isEmpty) return null;

    final parts = s.split('-');
    if (parts.length != 3) return null;

    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;

    try {
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  static String toYmdKey(DateTime dt) {
    final x = DateTime(dt.year, dt.month, dt.day);
    return '${x.year}-${two(x.month)}-${two(x.day)}';
  }
}
