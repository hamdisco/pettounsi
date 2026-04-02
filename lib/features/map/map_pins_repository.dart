import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'map_models.dart';

class MapPinsRepository {
  MapPinsRepository._();
  static final MapPinsRepository instance = MapPinsRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<MapPin>> streamAllPins() {
    final vetsStream = _db.collection('vets').snapshots();
    final petshopsStream = _db.collection('petshops').snapshots();
    final eventsStream = _db.collection('events').snapshots();
    final petReportsStream = _db.collection('pet_reports').snapshots();

    return Stream.multi((controller) {
      QuerySnapshot<Map<String, dynamic>>? vetsSnap;
      QuerySnapshot<Map<String, dynamic>>? petshopsSnap;
      QuerySnapshot<Map<String, dynamic>>? eventsSnap;
      QuerySnapshot<Map<String, dynamic>>? reportsSnap;

      void emit() {
        if (vetsSnap == null ||
            petshopsSnap == null ||
            eventsSnap == null ||
            reportsSnap == null) {
          return;
        }

        final pins = <MapPin>[
          ..._parseDirectoryDocs(vetsSnap!.docs, MapPinType.vet),
          ..._parseDirectoryDocs(petshopsSnap!.docs, MapPinType.petshop),
          ..._parseDirectoryDocs(eventsSnap!.docs, MapPinType.event),
          ..._parsePetReports(reportsSnap!.docs),
        ];

        controller.add(pins);
      }

      final subs = <StreamSubscription>[
        vetsStream.listen((s) {
          vetsSnap = s;
          emit();
        }, onError: controller.addError),
        petshopsStream.listen((s) {
          petshopsSnap = s;
          emit();
        }, onError: controller.addError),
        eventsStream.listen((s) {
          eventsSnap = s;
          emit();
        }, onError: controller.addError),
        petReportsStream.listen((s) {
          reportsSnap = s;
          emit();
        }, onError: controller.addError),
      ];

      controller.onCancel = () async {
        for (final s in subs) {
          await s.cancel();
        }
      };
    });
  }

  // ---------------------------
  // Parsers
  // ---------------------------

  List<MapPin> _parseDirectoryDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    MapPinType type,
  ) {
    final out = <MapPin>[];

    for (final doc in docs) {
      final m = doc.data();

      final isActive = _asBool(m['isActive'], fallback: true);
      if (!isActive) continue;

      final pos = _readPosition(m);
      if (pos == null) continue;

      final name = _pickFirstString(m, const [
        'name',
        'title',
      ], fallback: 'Unnamed');

      final address = _pickFirstString(m, const ['address', 'location']);
      final city = _pickFirstString(m, const ['city']);
      final governorate = _pickFirstString(m, const ['governorate', 'state']);

      final subtitle = _composeDirectorySubtitle(
        address: address,
        city: city,
        governorate: governorate,
      );

      final phone = _pickFirstString(m, const ['phone', 'phoneNumber', 'tel']);
      final sourceUrl = _pickFirstString(m, const [
        'sourceUrl',
        'website',
        'url',
      ]);

      out.add(
        MapPin(
          id: doc.id,
          type: type,
          title: name,
          subtitle: subtitle.isEmpty ? null : subtitle,
          position: pos,
          phone: phone.isEmpty ? null : phone,
          sourceUrl: sourceUrl.isEmpty ? null : sourceUrl,
          isResolved: false,
        ),
      );
    }

    return out;
  }

  List<MapPin> _parsePetReports(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final out = <MapPin>[];

    for (final doc in docs) {
      final m = doc.data();

      final typeRaw = _pickFirstString(m, const ['type']).toLowerCase();
      if (typeRaw != 'lost' && typeRaw != 'found') continue;

      final pos = _readPosition(m);
      if (pos == null) continue;

      final isResolved = _readResolved(m);

      final title = _buildPetReportTitle(m, typeRaw);
      final subtitle = _buildPetReportSubtitle(m);

      out.add(
        MapPin(
          id: doc.id,
          type: typeRaw == 'lost' ? MapPinType.lost : MapPinType.found,
          title: title,
          subtitle: subtitle.isEmpty ? null : subtitle,
          position: pos,
          isResolved: isResolved,
          authorId: _pickFirstString(m, const [
            'authorId',
            'userId',
            'ownerId',
          ]),
          phone: _pickFirstString(m, const ['phone', 'contactPhone']).isEmpty
              ? null
              : _pickFirstString(m, const ['phone', 'contactPhone']),
          sourceUrl: _pickFirstString(m, const ['sourceUrl']).isEmpty
              ? null
              : _pickFirstString(m, const ['sourceUrl']),
        ),
      );
    }

    return out;
  }

  // ---------------------------
  // Helpers
  // ---------------------------

  LatLng? _readPosition(Map<String, dynamic> m) {
    // Preferred Firestore GeoPoint field
    final geo = m['geo'];
    if (geo is GeoPoint) {
      return LatLng(geo.latitude, geo.longitude);
    }

    // Common alt shape: { location: GeoPoint }
    final location = m['location'];
    if (location is GeoPoint) {
      return LatLng(location.latitude, location.longitude);
    }

    // Numeric lat/lng fallback
    final lat = m['lat'];
    final lng = m['lng'];
    if (lat is num && lng is num) {
      return LatLng(lat.toDouble(), lng.toDouble());
    }

    return null;
  }

  bool _readResolved(Map<String, dynamic> m) {
    final isResolved = m['isResolved'];
    if (isResolved is bool) return isResolved;

    final status = _pickFirstString(m, const ['status']).toLowerCase();
    return status == 'resolved' || status == 'closed';
  }

  String _buildPetReportTitle(Map<String, dynamic> m, String typeRaw) {
    final title = _pickFirstString(m, const ['title']);
    if (title.isNotEmpty) return title;

    final animal = _pickFirstString(m, const ['animal', 'petType', 'species']);
    if (animal.isNotEmpty) {
      return '${typeRaw == 'lost' ? 'Lost' : 'Found'} $animal';
    }

    return typeRaw == 'lost' ? 'Lost Pet' : 'Found Pet';
  }

  String _buildPetReportSubtitle(Map<String, dynamic> m) {
    final description = _pickFirstString(m, const [
      'description',
      'details',
      'note',
    ]);
    final address = _pickFirstString(m, const ['address', 'locationLabel']);
    final city = _pickFirstString(m, const ['city']);
    final governorate = _pickFirstString(m, const ['governorate']);

    final parts = <String>[];

    if (description.isNotEmpty) {
      parts.add(description);
    } else if (address.isNotEmpty) {
      parts.add(address);
    }

    final place = [city, governorate].where((e) => e.isNotEmpty).join(' • ');
    if (place.isNotEmpty) parts.add(place);

    return parts.join(' — ');
  }

  String _composeDirectorySubtitle({
    required String address,
    required String city,
    required String governorate,
  }) {
    final parts = <String>[];

    if (address.isNotEmpty) parts.add(address);

    final place = [city, governorate].where((e) => e.isNotEmpty).join(' • ');
    if (place.isNotEmpty) parts.add(place);

    return parts.join(' — ');
  }

  bool _asBool(Object? value, {bool fallback = false}) {
    if (value is bool) return value;
    return fallback;
  }

  String _pickFirstString(
    Map<String, dynamic> m,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final k in keys) {
      final v = m[k];
      final s = _asString(v);
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  String _asString(Object? v) {
    if (v == null) return '';
    final s = v.toString().trim();
    return s;
  }
}
