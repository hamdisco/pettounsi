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
  final String? whatsapp;
  final String? sourceUrl;
  final String? notes;
  final String? photoUrl;
  final double? lat;
  final double? lng;
  final bool isActive;

  /// Optional partner/business fields. They are safe if missing in Firestore.
  final String category;
  final String? openingHours;
  final String? offerText;
  final String? servicesText;
  final String? partnerTier;
  final bool isEmergency;
  final bool isFeatured;

  /// Mainly for events (optional)
  final DateTime? startsAt;
  final DateTime? endsAt;
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
    required this.whatsapp,
    required this.sourceUrl,
    required this.notes,
    required this.photoUrl,
    required this.lat,
    required this.lng,
    required this.isActive,
    required this.category,
    required this.openingHours,
    required this.offerText,
    required this.servicesText,
    required this.partnerTier,
    required this.isEmergency,
    required this.isFeatured,
    required this.startsAt,
    required this.endsAt,
    required this.dateLabel,
    this.distanceKm,
  });

  bool get hasCoords => lat != null && lng != null;
  bool get hasPhone => (phone ?? '').trim().isNotEmpty;
  bool get hasWhatsapp => (whatsapp ?? '').trim().isNotEmpty;
  bool get hasPhoto => (photoUrl ?? '').trim().isNotEmpty;
  bool get hasSource => (sourceUrl ?? '').trim().isNotEmpty;
  bool get hasOffer => (offerText ?? '').trim().isNotEmpty;
  bool get hasServices => (servicesText ?? '').trim().isNotEmpty;
  bool get hasPartnerLabel => isFeatured || (partnerTier ?? '').trim().isNotEmpty;
  bool get isEvent => collectionName == 'events' || dateLabel.trim().isNotEmpty || startsAt != null;

  bool get isEventToday {
    if (!isEvent || startsAt == null) return false;
    return AppDateFmt.sameDay(startsAt, DateTime.now());
  }

  bool get isEventPast {
    if (!isEvent) return false;
    final marker = endsAt ?? startsAt;
    if (marker == null) return false;
    return marker.isBefore(DateTime.now().subtract(const Duration(hours: 2)));
  }

  String get eventStatusLabel {
    if (!isEvent) return '';
    if (isEventPast) return 'Past';
    if (isEventToday) return 'Today';
    return 'Upcoming';
  }

  String get eventTimeLabel {
    if (!isEvent) return '';
    if (startsAt == null) return dateLabel;
    final date = dateLabel.trim().isNotEmpty ? dateLabel : AppDateFmt.dMy(startsAt);
    final startTime = AppDateFmt.hm(startsAt);
    final endTime = endsAt == null ? '' : AppDateFmt.hm(endsAt);
    if (startTime == '00:00' && endTime.isEmpty) return date;
    if (endTime.isNotEmpty && endTime != startTime) return '$date • $startTime - $endTime';
    return '$date • $startTime';
  }

  DirectoryItem withDistanceKm(double? km) {
    return DirectoryItem(
      id: id,
      collectionName: collectionName,
      name: name,
      address: address,
      city: city,
      governorate: governorate,
      phone: phone,
      whatsapp: whatsapp,
      sourceUrl: sourceUrl,
      notes: notes,
      photoUrl: photoUrl,
      lat: lat,
      lng: lng,
      isActive: isActive,
      category: category,
      openingHours: openingHours,
      offerText: offerText,
      servicesText: servicesText,
      partnerTier: partnerTier,
      isEmergency: isEmergency,
      isFeatured: isFeatured,
      startsAt: startsAt,
      endsAt: endsAt,
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
    final whatsapp = _firstString(m, [
      'whatsapp',
      'whatsApp',
      'whatsappNumber',
      'whatsAppNumber',
    ]);
    final sourceUrl = _firstString(m, ['sourceUrl', 'website', 'url']);

    final notes = _firstString(
      m,
      collectionName == 'events'
          ? ['description', 'details', 'notes']
          : ['notes', 'description'],
    );
    final photoUrl = _firstString(
      m,
      ['photoUrl', 'imageUrl', 'coverPhotoUrl', 'coverImageUrl', 'logoUrl'],
    );

    final category = _firstString(
      m,
      ['category', 'type', 'serviceType'],
      fallback: _defaultCategory(collectionName),
    );
    final openingHours = _firstString(m, [
      'openingHours',
      'hours',
      'availabilityText',
      'scheduleText',
    ]);
    final offerText = _firstString(m, [
      'offerText',
      'offer',
      'dealText',
      'promotionText',
    ]);
    final servicesText = _firstString(m, [
      'servicesText',
      'services',
      'specialties',
      'products',
      'productCategories',
    ]);
    final partnerTier = _firstString(m, [
      'partnerTier',
      'partnerPlan',
      'plan',
      'badge',
    ]);
    final isEmergency = _asBool(m['isEmergency'] ?? m['emergency'] ?? m['emergencyVet']);

    final isFeatured = _asBool(m['isFeatured'] ?? m['featured']) ||
        partnerTier.toLowerCase().contains('featured') ||
        partnerTier.toLowerCase().contains('premium');

    final isActive = (m['isActive'] is bool) ? (m['isActive'] as bool) : true;

    final startsAt = _readEventStart(m, collectionName);
    final endsAt = _readEventEnd(m, collectionName);
    final dateLabel = _buildEventDateLabel(m, collectionName, startsAt);

    return DirectoryItem(
      id: doc.id,
      collectionName: collectionName,
      name: name,
      address: address,
      city: city,
      governorate: governorate,
      phone: phone.isEmpty ? null : phone,
      whatsapp: whatsapp.isEmpty ? null : whatsapp,
      sourceUrl: sourceUrl.isEmpty ? null : sourceUrl,
      notes: notes.isEmpty ? null : notes,
      photoUrl: photoUrl.isEmpty ? null : photoUrl,
      lat: lat,
      lng: lng,
      isActive: isActive,
      category: category,
      openingHours: openingHours.isEmpty ? null : openingHours,
      offerText: offerText.isEmpty ? null : offerText,
      servicesText: servicesText.isEmpty ? null : servicesText,
      partnerTier: partnerTier.isEmpty ? null : partnerTier,
      isEmergency: isEmergency,
      isFeatured: isFeatured,
      startsAt: startsAt,
      endsAt: endsAt,
      dateLabel: dateLabel,
    );
  }

  static DateTime? _readEventStart(
    Map<String, dynamic> m,
    String collectionName,
  ) {
    if (collectionName != 'events') return null;

    return _asDateTime(
      m['startAt'] ?? m['dateAt'] ?? m['startsAt'] ?? m['createdAt'],
    );
  }

  static DateTime? _readEventEnd(
    Map<String, dynamic> m,
    String collectionName,
  ) {
    if (collectionName != 'events') return null;

    return _asDateTime(m['endAt'] ?? m['endsAt'] ?? m['finishAt']);
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

  static String _defaultCategory(String collectionName) {
    switch (collectionName) {
      case 'vets':
        return 'Vet clinic';
      case 'petshops':
        return 'Pet shop';
      case 'events':
        return 'Pet event';
      default:
        return 'Partner';
    }
  }

  static String _firstString(
    Map<String, dynamic> m,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final k in keys) {
      final v = m[k];
      if (v == null) continue;
      final s = v is Iterable
          ? v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).join(' · ')
          : v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  static bool _asBool(Object? v) {
    if (v is bool) return v;
    if (v is String) return v.trim().toLowerCase() == 'true';
    if (v is num) return v != 0;
    return false;
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
