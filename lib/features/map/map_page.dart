import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ui/app_theme.dart';
import '../../ui/premium_permission_dialog.dart';
import 'create_pet_report_sheet.dart';
import 'map_models.dart';
import 'map_pins_repository.dart';
import 'nearby_sheet.dart';
import 'pet_reports_page.dart';
import 'pet_reports_repository.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    this.initialFilter,
    this.initialCenter,
    this.initialZoom,
    this.standalone = false,
  });

  final MapPinType? initialFilter;
  final LatLng? initialCenter;
  final double? initialZoom;
  final bool standalone;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _map = MapController();

  LatLng _center = const LatLng(35.8, 10.2);
  double _zoom = 6.0;

  MapPinType? _filter;
  bool _locBusy = false;
  LatLng? _myLocation;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    if (widget.initialCenter != null) _center = widget.initialCenter!;
    if (widget.initialZoom != null) _zoom = widget.initialZoom!;
  }

  List<MapPin> _applyFilter(List<MapPin> pins) {
    final filtered = (_filter == null)
        ? pins
        : pins.where((p) => p.type == _filter).toList();

    return filtered.where((p) => !p.isResolved).toList();
  }

  Future<LatLng?> _requestDeviceLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return null;
      await showPremiumPermissionDialog(
        context: context,
        icon: Icons.location_off_rounded,
        tint: AppTheme.orangeDark,
        iconBg: AppTheme.softOrange,
        title: 'Turn on location',
        message:
            'To center the map on you, turn on Location Services on your phone, then return to Pettounsi.',
        primaryLabel: 'Open settings',
        onPrimary: () => Geolocator.openLocationSettings(),
      );
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return null;
      if (permission == LocationPermission.deniedForever) {
        await showPremiumPermissionDialog(
          context: context,
          icon: Icons.location_searching_rounded,
          tint: const Color(0xFF7C62D7),
          iconBg: AppTheme.lilac,
          title: 'Allow location access',
          message:
              'Pettounsi cannot use your location until you allow access in app settings.',
          primaryLabel: 'Open app settings',
          onPrimary: () => Geolocator.openAppSettings(),
          secondaryLabel: 'Later',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
      }
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return LatLng(pos.latitude, pos.longitude);
  }

  Future<void> _locateMe() async {
    setState(() => _locBusy = true);

    try {
      final here = await _requestDeviceLocation();
      if (here == null) return;

      _map.move(here, 15);

      setState(() {
        _center = here;
        _zoom = 15;
        _myLocation = here;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get your location')),
      );
    } finally {
      if (mounted) setState(() => _locBusy = false);
    }
  }

  void _zoomIn() {
    final next = (_zoom + 1).clamp(3.0, 19.0);
    _map.move(_center, next);
    setState(() => _zoom = next);
  }

  void _zoomOut() {
    final next = (_zoom - 1).clamp(3.0, 19.0);
    _map.move(_center, next);
    setState(() => _zoom = next);
  }

  void _openCreateReport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePetReportSheet(position: _center),
    );
  }

  void _openReportsList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PetReportsPage()),
    );
  }

  Future<void> _openDirections(LatLng p, {String? label}) async {
    final lat = p.latitude;
    final lng = p.longitude;
    final safeLabel = (label ?? 'Destination').replaceAll(',', ' ');

    try {
      final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($safeLabel)');
      if (await canLaunchUrl(geoUri)) {
        final ok = await launchUrl(geoUri);
        if (ok) return;
      }

      if (Platform.isIOS) {
        final appleUri = Uri.parse('http://maps.apple.com/?daddr=$lat,$lng');
        if (await canLaunchUrl(appleUri)) {
          final ok = await launchUrl(
            appleUri,
            mode: LaunchMode.externalApplication,
          );
          if (ok) return;
        }
      }

      final osmUri = Uri.parse(
        'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=16/$lat/$lng',
      );
      final ok = await launchUrl(osmUri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open directions')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions')),
      );
    }
  }

  Future<void> _callPhone(String? phone) async {
    final raw = (phone ?? '').trim();
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }

    final normalized = raw.replaceAll(' ', '');
    final uri = Uri.parse('tel:$normalized');

    try {
      final ok = await launchUrl(uri);
      if (!ok && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open dialer')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open dialer')));
    }
  }

  Future<void> _openSourceLink(String? url) async {
    final raw = (url ?? '').trim();
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No source link available')));
      return;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid source link')));
      return;
    }

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open source link')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open source link')),
      );
    }
  }

  Future<void> _openNearby(List<MapPin> allPins) async {
    setState(() => _locBusy = true);

    try {
      final here = await _requestDeviceLocation();
      if (here == null) return;

      _map.move(here, 14.5);

      setState(() {
        _center = here;
        _zoom = 14.5;
        _myLocation = here;
      });

      if (!mounted) return;

      final visiblePins = _applyFilter(allPins);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => NearbySheet(
          origin: here,
          pins: visiblePins,
          onSelect: (pin) {
            Navigator.pop(context);
            _map.move(pin.position, 16);
            setState(() {
              _center = pin.position;
              _zoom = 16;
            });
            _showPin(pin);
          },
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get your location')),
      );
    } finally {
      if (mounted) setState(() => _locBusy = false);
    }
  }

  void _showPin(MapPin pin) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isMyReport = (pin.authorId ?? '') == myUid;
    final isReport =
        pin.type == MapPinType.lost || pin.type == MapPinType.found;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MapPinDetailsSheet(
        pin: pin,
        onDirections: () => _openDirections(pin.position, label: pin.title),
        onCall: pin.hasPhone ? () => _callPhone(pin.phone) : null,
        onSource: pin.hasSourceUrl
            ? () => _openSourceLink(pin.sourceUrl)
            : null,
        onResolve: (isReport && isMyReport && !pin.isResolved)
            ? () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  await PetReportsRepository.instance.markResolved(pin.id);
                  navigator.pop();
                } catch (_) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("Could not mark as resolved."),
                    ),
                  );
                }
              }
            : null,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return StreamBuilder<List<MapPin>>(
      stream: MapPinsRepository.instance.streamAllPins(),
      builder: (context, snap) {
        final allPins = snap.data ?? const <MapPin>[];
        final pins = _applyFilter(allPins);

        final markers = pins.map((pin) {
          return Marker(
            point: pin.position,
            width: 56,
            height: 56,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () => _showPin(pin),
              child: _MapMarker(pin: pin),
            ),
          );
        }).toList();

        if (_myLocation != null) {
          markers.add(
            Marker(
              point: _myLocation!,
              width: 58,
              height: 58,
              alignment: Alignment.center,
              child: const IgnorePointer(child: _MyLocationMarker()),
            ),
          );
        }

        return Stack(
          children: [
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: _zoom,
                minZoom: 3,
                maxZoom: 19,
                onPositionChanged: (pos, _) {
                  _center = pos.center;
                  _zoom = pos.zoom;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.pettounsi.app',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: _MapTopBar(
                filter: _filter,
                pinCount: pins.length,
                onSelect: (v) => setState(() => _filter = v),
              ),
            ),
            Positioned(left: 12, top: 116, child: _LegendCard(filter: _filter)),
            Positioned(
              left: 12,
              bottom: 24,
              child: Row(
                children: [
                  _GlassActionButton.extended(
                    icon: _locBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          )
                        : const Icon(Icons.near_me_outlined),
                    label: 'Near me',
                    onTap: _locBusy ? null : () => _openNearby(allPins),
                  ),
                  const SizedBox(width: 8),
                  _GlassActionButton.extended(
                    icon: const Icon(Icons.list_alt_rounded),
                    label: 'Reports',
                    onTap: _openReportsList,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 170,
              child: _ZoomControls(onPlus: _zoomIn, onMinus: _zoomOut),
            ),
            Positioned(
              right: 12,
              bottom: 100,
              child: _GlassActionButton(
                icon: _locBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.my_location_rounded),
                onTap: _locBusy ? null : _locateMe,
              ),
            ),
            Positioned(
              right: 12,
              bottom: 24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C62D7), Color(0xFFC86B9A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C62D7).withAlpha(40),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  heroTag: 'report',
                  onPressed: _openCreateReport,
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  highlightElevation: 0,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Report',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (!widget.standalone) return content;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(child: content),
    );
  }
}

class _MyLocationMarker extends StatelessWidget {
  const _MyLocationMarker();

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C62D7);
    const accent2 = Color(0xFFC86B9A);

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withAlpha(22),
              border: Border.all(color: accent.withAlpha(32), width: 1.2),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [accent, accent2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: accent.withAlpha(55),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          Positioned(
            bottom: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: accent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: accent.withAlpha(35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapTopBar extends StatelessWidget {
  const _MapTopBar({
    required this.filter,
    required this.pinCount,
    required this.onSelect,
  });

  final MapPinType? filter;
  final int pinCount;
  final ValueChanged<MapPinType?> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget chip(String text, MapPinType? v) {
      final active = filter == v;
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onSelect(v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFF3ECFF) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? const Color(0xFF7C62D7) : AppTheme.outline,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: active
                  ? const Color(0xFF7C62D7)
                  : AppTheme.ink.withAlpha(180),
              fontWeight: FontWeight.w900,
              fontSize: 11.4,
              height: 1,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.sky,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white),
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: Color(0xFF4C79C8),
                  size: 19,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Explore the map',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.4,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.blush,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Text(
                  '$pinCount pins',
                  style: const TextStyle(
                    color: AppTheme.orangeDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.8,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip('All', null),
                const SizedBox(width: 6),
                chip('Lost', MapPinType.lost),
                const SizedBox(width: 6),
                chip('Found', MapPinType.found),
                const SizedBox(width: 6),
                chip('Vets', MapPinType.vet),
                const SizedBox(width: 6),
                chip('Petshops', MapPinType.petshop),
                const SizedBox(width: 6),
                chip('Events', MapPinType.event),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendCard extends StatelessWidget {
  const _LegendCard({required this.filter});

  final MapPinType? filter;

  @override
  Widget build(BuildContext context) {
    Widget dot(Color color, String label) {
      final show =
          filter == null ||
          (label == 'Lost' && filter == MapPinType.lost) ||
          (label == 'Found' && filter == MapPinType.found) ||
          (label == 'Vets' && filter == MapPinType.vet) ||
          (label == 'Petshops' && filter == MapPinType.petshop) ||
          (label == 'Events' && filter == MapPinType.event);

      if (!show) return const SizedBox.shrink();

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.4,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
              height: 1,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(236),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        children: [
          dot(const Color(0xFFE05555), 'Lost'),
          dot(const Color(0xFF2F9A6A), 'Found'),
          dot(const Color(0xFF4C79C8), 'Vets'),
          dot(const Color(0xFF7C62D7), 'Petshops'),
          dot(AppTheme.orangeDark, 'Events'),
        ],
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({required this.onPlus, required this.onMinus});

  final VoidCallback onPlus;
  final VoidCallback onMinus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Zoom in',
            onPressed: onPlus,
            icon: const Icon(Icons.add_rounded),
          ),
          Divider(height: 1, thickness: 1, color: AppTheme.outline),
          IconButton(
            tooltip: 'Zoom out',
            onPressed: onMinus,
            icon: const Icon(Icons.remove_rounded),
          ),
        ],
      ),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({required this.icon, required this.onTap})
    : label = null;

  const _GlassActionButton.extended({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final extended = label != null;

    if (extended) {
      return FloatingActionButton.extended(
        heroTag: label,
        onPressed: onTap,
        backgroundColor: Colors.white.withAlpha(236),
        foregroundColor: AppTheme.ink,
        elevation: 0,
        highlightElevation: 0,
        icon: icon,
        label: Text(
          label!,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      );
    }

    return FloatingActionButton.small(
      heroTag: 'glass_${icon.hashCode}',
      onPressed: onTap,
      backgroundColor: Colors.white.withAlpha(236),
      foregroundColor: AppTheme.ink,
      elevation: 0,
      highlightElevation: 0,
      child: icon,
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.pin});

  final MapPin pin;

  Color get _color {
    switch (pin.type) {
      case MapPinType.lost:
        return const Color(0xFFE05555);
      case MapPinType.found:
        return const Color(0xFF2F9A6A);
      case MapPinType.vet:
        return const Color(0xFF4C79C8);
      case MapPinType.petshop:
        return const Color(0xFF7C62D7);
      case MapPinType.event:
        return AppTheme.orangeDark;
    }
  }

  IconData get _icon {
    switch (pin.type) {
      case MapPinType.lost:
        return Icons.pets;
      case MapPinType.found:
        return Icons.pets_outlined;
      case MapPinType.vet:
        return Icons.local_hospital_outlined;
      case MapPinType.petshop:
        return Icons.storefront_outlined;
      case MapPinType.event:
        return Icons.event_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 46,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppTheme.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(18),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(_icon, color: _color, size: 22),
        ),
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
    );
  }
}

class _MapPinDetailsSheet extends StatelessWidget {
  const _MapPinDetailsSheet({
    required this.pin,
    required this.onDirections,
    this.onCall,
    this.onSource,
    this.onResolve,
  });

  final MapPin pin;
  final VoidCallback onDirections;
  final VoidCallback? onCall;
  final VoidCallback? onSource;
  final VoidCallback? onResolve;

  Color get _accent {
    switch (pin.type) {
      case MapPinType.lost:
        return const Color(0xFFE05555);
      case MapPinType.found:
        return const Color(0xFF2F9A6A);
      case MapPinType.vet:
        return const Color(0xFF4C79C8);
      case MapPinType.petshop:
        return const Color(0xFF7C62D7);
      case MapPinType.event:
        return AppTheme.orangeDark;
    }
  }

  IconData get _icon {
    switch (pin.type) {
      case MapPinType.lost:
        return Icons.pets;
      case MapPinType.found:
        return Icons.pets_outlined;
      case MapPinType.vet:
        return Icons.local_hospital_outlined;
      case MapPinType.petshop:
        return Icons.storefront_outlined;
      case MapPinType.event:
        return Icons.event_outlined;
    }
  }

  String get _typeLabel {
    switch (pin.type) {
      case MapPinType.lost:
        return 'Lost';
      case MapPinType.found:
        return 'Found';
      case MapPinType.vet:
        return 'Vet';
      case MapPinType.petshop:
        return 'Petshop';
      case MapPinType.event:
        return 'Event';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.outline),
            boxShadow: AppTheme.softShadows(0.22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.ink.withAlpha(18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Color.lerp(_accent, Colors.white, 0.88),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Icon(_icon, color: _accent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pin.title,
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              pin.subtitle?.trim().isNotEmpty == true
                                  ? pin.subtitle!
                                  : 'Map location details and quick actions',
                              style: TextStyle(
                                color: AppTheme.muted.withAlpha(220),
                                fontWeight: FontWeight.w700,
                                fontSize: 12.2,
                                height: 1.18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Color.lerp(_accent, Colors.white, 0.88),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: Text(
                      _typeLabel,
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDirections,
                        icon: const Icon(Icons.near_me_rounded),
                        label: const Text(
                          'Directions',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    if (onCall != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCall,
                          icon: const Icon(Icons.call_outlined),
                          label: const Text(
                            'Call',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.outline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (onSource != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onSource,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text(
                        'Open source',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
                if (onResolve != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onResolve,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F9A6A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text(
                        'Mark resolved',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
