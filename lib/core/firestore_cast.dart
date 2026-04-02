import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-safe casting helpers.
/// Use these helpers when reading dynamic maps from Firestore to avoid:
/// - num vs int/double type errors
/// - Timestamp parsing crashes
/// - null field crashes
/// - "type X is not a subtype of Y" runtime errors
class FsCast {
  const FsCast._();

  static String s(dynamic v, {String fallback = '', bool trim = true}) {
    if (v == null) return fallback;
    final out = v is String ? v : v.toString();
    return trim ? out.trim() : out;
  }

  static String? sN(dynamic v, {bool trim = true, bool emptyAsNull = true}) {
    if (v == null) return null;
    final out = v is String ? v : v.toString();
    final result = trim ? out.trim() : out;
    if (emptyAsNull && result.isEmpty) return null;
    return result;
  }

  static int i(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? fallback;
    return fallback;
  }

  static int? iN(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static double d(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? fallback;
    return fallback;
  }

  static double? dN(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  static bool b(dynamic v, {bool fallback = false}) {
    if (v == null) return fallback;
    if (v is bool) return v;

    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true' || t == '1' || t == 'yes') return true;
      if (t == 'false' || t == '0' || t == 'no') return false;
    }

    if (v is num) return v != 0;
    return fallback;
  }

  static DateTime? dt(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v.trim());
    return null;
  }

  static Timestamp? ts(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v;
    if (v is DateTime) return Timestamp.fromDate(v);
    return null;
  }

  static List<String> stringList(dynamic v, {bool trim = true}) {
    if (v == null) return const <String>[];
    if (v is! List) return const <String>[];

    final out = <String>[];
    for (final item in v) {
      final s = item == null ? '' : item.toString();
      final x = trim ? s.trim() : s;
      if (x.isNotEmpty) out.add(x);
    }
    return out;
  }

  static List<Map<String, dynamic>> mapList(dynamic v) {
    if (v == null || v is! List) return const <Map<String, dynamic>>[];
    final out = <Map<String, dynamic>>[];
    for (final item in v) {
      if (item is Map<String, dynamic>) {
        out.add(item);
      } else if (item is Map) {
        out.add(Map<String, dynamic>.from(item));
      }
    }
    return out;
  }

  static Map<String, dynamic> map(dynamic v) {
    if (v == null) return <String, dynamic>{};
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  static T? enumByName<T extends Enum>(
    List<T> values,
    dynamic raw, {
    bool caseInsensitive = true,
  }) {
    final s = FsCast.sN(raw);
    if (s == null) return null;

    for (final v in values) {
      final a = caseInsensitive ? v.name.toLowerCase() : v.name;
      final b = caseInsensitive ? s.toLowerCase() : s;
      if (a == b) return v;
    }
    return null;
  }
}

/// Convenience extensions for Firestore maps/docs.
extension FsMapX on Map<String, dynamic> {
  String fsString(String key, {String fallback = '', bool trim = true}) =>
      FsCast.s(this[key], fallback: fallback, trim: trim);

  String? fsStringN(String key, {bool trim = true, bool emptyAsNull = true}) =>
      FsCast.sN(this[key], trim: trim, emptyAsNull: emptyAsNull);

  int fsInt(String key, {int fallback = 0}) =>
      FsCast.i(this[key], fallback: fallback);

  int? fsIntN(String key) => FsCast.iN(this[key]);

  double fsDouble(String key, {double fallback = 0.0}) =>
      FsCast.d(this[key], fallback: fallback);

  double? fsDoubleN(String key) => FsCast.dN(this[key]);

  bool fsBool(String key, {bool fallback = false}) =>
      FsCast.b(this[key], fallback: fallback);

  DateTime? fsDateTime(String key) => FsCast.dt(this[key]);

  Timestamp? fsTimestamp(String key) => FsCast.ts(this[key]);

  List<String> fsStringList(String key, {bool trim = true}) =>
      FsCast.stringList(this[key], trim: trim);

  List<Map<String, dynamic>> fsMapList(String key) => FsCast.mapList(this[key]);

  Map<String, dynamic> fsMap(String key) => FsCast.map(this[key]);
}

extension FsDocX on DocumentSnapshot<Map<String, dynamic>> {
  Map<String, dynamic> fsDataOrEmpty() => data() ?? <String, dynamic>{};
}

extension FsQueryDocX on QueryDocumentSnapshot<Map<String, dynamic>> {
  Map<String, dynamic> fsDataMap() => data();
}
