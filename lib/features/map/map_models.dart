import 'package:latlong2/latlong.dart';

enum MapPinType { lost, found, vet, petshop, event }

class MapPin {
  final String id;
  final MapPinType type;

  /// Main label shown on marker detail / nearby list
  final String title;

  /// Optional subtitle (address / city / short description)
  final String? subtitle;

  final LatLng position;

  /// For pet reports
  final bool isResolved;
  final String? authorId;

  /// Optional details for directory/event pins
  final String? phone;
  final String? sourceUrl;

  const MapPin({
    required this.id,
    required this.type,
    required this.title,
    required this.position,
    this.subtitle,
    this.isResolved = false,
    this.authorId,
    this.phone,
    this.sourceUrl,
  });

  bool get hasPhone => (phone ?? '').trim().isNotEmpty;
  bool get hasSourceUrl => (sourceUrl ?? '').trim().isNotEmpty;
}
