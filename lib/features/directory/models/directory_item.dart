import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/date_formatters.dart';

class DirectoryItem {
  final String id;
  final String collectionName; // vets | petshops | events

  final String name;
  final String address;
  final String city;
  final String governorate;
  final String? phone;
  final String? sourceUrl;
  final String? notes;
  final double? lat;
  final double? lng;
  final bool isActive;

  /// Mainly for events (optional)
  final DateTime? startsAt;
  final String dateLabel;

  /// Optional, computed at runtime.
  final double? distanceKm;

  const DirectoryItem({
    required this.id,
    required this.collectionName,
    required this.name,
    required this.address,
    required this.city,
    required this.governorate,
    required this.phone,
    required this.sourceUrl,
    required this.notes,
    required this.lat,
    required this.lng,
    required this.isActive,
    required this.startsAt,
    required this.dateLabel,
    this.distanceKm,
  });

  bool get hasCoords => lat != null && lng != null;
  bool get hasPhone => (phone ?? '').trim().isNotEmpty;
  bool get hasSource => (sourceUrl ?? '').trim().isNotEmpty;
  bool get isEvent => dateLabel.trim().isNotEmpty || startsAt != null;

  DirectoryItem withDistanceKm(double? km) {
    return DirectoryItem(
      id: id,
      collectionName: collectionName,
      name: name,
      address: address,
      city: city,
      governorate: governorate,
      phone: phone,
      sourceUrl: sourceUrl,
      notes: notes,
      lat: lat,
      lng: lng,
      isActive: isActive,
      startsAt: startsAt,
      dateLabel: dateLabel,
      distanceKm: km,
    );
  }

  static DirectoryItem fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String collectionName,
  ) {
    final m = doc.data();

    final gp = (m['geo'] is GeoPoint)
        ? m['geo'] as GeoPoint
        : (m['location'] is GeoPoint ? m['location'] as GeoPoint : null);

    final lat = gp?.latitude ?? _asDouble(m['lat']);
    final lng = gp?.longitude ?? _asDouble(m['lng']);

    final name = _firstString(m, ['name', 'title'], fallback: 'Unnamed');
    final address = _firstString(m, ['address', 'locationLabel', 'location']);
    final city = _firstString(m, ['city']);
    final governorate = _firstString(m, ['governorate', 'state']);
    final phone = _firstString(m, ['phone', 'phoneNumber', 'tel']);
    final sourceUrl = _firstString(m, ['sourceUrl', 'website', 'url']);

    final notes = _firstString(
      m,
      collectionName == 'events'
          ? ['description', 'details', 'notes']
          : ['notes', 'description'],
    );

    final isActive = (m['isActive'] is bool) ? (m['isActive'] as bool) : true;

    final startsAt = _readEventStart(m, collectionName);
    final dateLabel = _buildEventDateLabel(m, collectionName, startsAt);

    return DirectoryItem(
      id: doc.id,
      collectionName: collectionName,
      name: name,
      address: address,
      city: city,
      governorate: governorate,
      phone: phone.isEmpty ? null : phone,
      sourceUrl: sourceUrl.isEmpty ? null : sourceUrl,
      notes: notes.isEmpty ? null : notes,
      lat: lat,
      lng: lng,
      isActive: isActive,
      startsAt: startsAt,
      dateLabel: dateLabel,
    );
  }

  static DateTime? _readEventStart(
    Map<String, dynamic> m,
    String collectionName,
  ) {
    if (collectionName != 'events') return null;

    return _asDateTime(
      m['startAt'] ??
          m['dateAt'] ??
          m['startsAt'] ??
          m['createdAt'],
    );
  }

  static String _buildEventDateLabel(
    Map<String, dynamic> m,
    String collectionName,
    DateTime? startsAt,
  ) {
    if (collectionName != 'events') return '';

    final dateText = _firstString(m, ['dateLabel', 'date', 'eventDate']);
    if (dateText.isNotEmpty) return dateText;

    if (startsAt != null) {
      return AppDateFmt.dMy(startsAt);
    }

    return '';
  }

  static String _firstString(
    Map<String, dynamic> m,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  static DateTime? _asDateTime(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static double? _asDouble(Object? v) {
    if (v is num) return v.toDouble();
    return null;
  }
}
