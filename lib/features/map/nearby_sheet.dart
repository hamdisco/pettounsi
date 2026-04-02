import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ui/app_theme.dart';
import 'map_models.dart';

class NearbySheet extends StatefulWidget {
  const NearbySheet({
    super.key,
    required this.origin,
    required this.pins,
    required this.onSelect,
  });

  final LatLng origin;
  final List<MapPin> pins;
  final ValueChanged<MapPin> onSelect;

  @override
  State<NearbySheet> createState() => _NearbySheetState();
}

class _NearbySheetState extends State<NearbySheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Distance _distance = const Distance();

  String _query = '';
  MapPinType? _filter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MapPin> get _filteredSorted {
    final q = _query.trim().toLowerCase();

    final list = widget.pins.where((p) {
      if (_filter != null && p.type != _filter) return false;

      if (q.isEmpty) return true;

      final title = p.title.toLowerCase();
      final subtitle = (p.subtitle ?? '').toLowerCase();
      final phone = (p.phone ?? '').toLowerCase();

      return title.contains(q) || subtitle.contains(q) || phone.contains(q);
    }).toList();

    list.sort((a, b) {
      final da = _distanceMeters(a.position);
      final db = _distanceMeters(b.position);
      return da.compareTo(db);
    });

    return list;
  }

  double _distanceMeters(LatLng p) {
    return _distance.as(LengthUnit.Meter, widget.origin, p);
  }

  String _distanceLabel(LatLng p) {
    final meters = _distanceMeters(p);
    if (meters < 1000) return '${meters.round()} m';
    final km = meters / 1000;
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
  }

  Future<void> _openDirections(MapPin pin) async {
    final lat = pin.position.latitude;
    final lng = pin.position.longitude;
    final safeLabel = pin.title.replaceAll(',', ' ');

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
    if (raw.isEmpty) return;

    final uri = Uri.parse('tel:${raw.replaceAll(' ', '')}');
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

  Future<void> _openSource(String? url) async {
    final raw = (url ?? '').trim();
    if (raw.isEmpty) return;

    final uri = Uri.tryParse(raw);
    if (uri == null) return;

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

  @override
  Widget build(BuildContext context) {
    final items = _filteredSorted;
    final maxHeight = MediaQuery.of(context).size.height * 0.84;

    Widget chip(String text, MapPinType? v) {
      final active = _filter == v;
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() => _filter = v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
              fontWeight: FontWeight.w900,
              color: active
                  ? const Color(0xFF7C62D7)
                  : AppTheme.ink.withAlpha(180),
              fontSize: 12.2,
              height: 1,
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        height: maxHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.outline),
              boxShadow: AppTheme.softShadows(0.22),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.ink.withAlpha(18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.lilac,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white),
                        ),
                        child: const Icon(
                          Icons.near_me_rounded,
                          color: Color(0xFF7C62D7),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Near me',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                color: AppTheme.ink,
                                height: 1,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Closest places and reports around your location',
                              style: TextStyle(
                                color: AppTheme.muted,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.blush,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        child: Text(
                          '${items.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                            color: AppTheme.orangeDark,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search nearby...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.trim().isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: const Color(0xFFF8F4FB),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AppTheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AppTheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AppTheme.outline),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        chip('All', null),
                        const SizedBox(width: 8),
                        chip('Lost', MapPinType.lost),
                        const SizedBox(width: 8),
                        chip('Found', MapPinType.found),
                        const SizedBox(width: 8),
                        chip('Vets', MapPinType.vet),
                        const SizedBox(width: 8),
                        chip('Petshops', MapPinType.petshop),
                        const SizedBox(width: 8),
                        chip('Events', MapPinType.event),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppTheme.sky,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.white),
                                  ),
                                  child: const Icon(
                                    Icons.search_off_rounded,
                                    color: Color(0xFF4C79C8),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No nearby results',
                                  style: TextStyle(
                                    color: AppTheme.ink,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Try another filter or search term.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.muted.withAlpha(220),
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 2, 14, 20),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final pin = items[i];
                            return _NearbyCard(
                              pin: pin,
                              distanceLabel: _distanceLabel(pin.position),
                              icon: _pinIconData(pin.type),
                              color: _pinColor(pin.type),
                              typeLabel: _typeLabel(pin.type),
                              onOpen: () => widget.onSelect(pin),
                              onDirections: () => _openDirections(pin),
                              onCall: (pin.phone ?? '').trim().isEmpty
                                  ? null
                                  : () => _callPhone(pin.phone),
                              onSource: (pin.sourceUrl ?? '').trim().isEmpty
                                  ? null
                                  : () => _openSource(pin.sourceUrl),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _typeLabel(MapPinType t) {
    switch (t) {
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

  IconData _pinIconData(MapPinType t) {
    switch (t) {
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

  Color _pinColor(MapPinType t) {
    switch (t) {
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
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({
    required this.pin,
    required this.distanceLabel,
    required this.icon,
    required this.color,
    required this.typeLabel,
    required this.onOpen,
    required this.onDirections,
    this.onCall,
    this.onSource,
  });

  final MapPin pin;
  final String distanceLabel;
  final IconData icon;
  final Color color;
  final String typeLabel;
  final VoidCallback onOpen;
  final VoidCallback onDirections;
  final VoidCallback? onCall;
  final VoidCallback? onSource;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withAlpha(18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pin.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.6,
                      color: AppTheme.ink,
                      height: 1.08,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.blush,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Text(
                    distanceLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11.1,
                      color: AppTheme.orangeDark,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.2,
                      height: 1,
                    ),
                  ),
                ),
                if ((pin.subtitle ?? '').trim().isNotEmpty)
                  Text(
                    pin.subtitle!,
                    style: TextStyle(
                      color: AppTheme.ink.withAlpha(165),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.15,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text(
                      'Open',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDirections,
                    icon: const Icon(Icons.near_me_rounded, size: 18),
                    label: const Text(
                      'Directions',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (onCall != null || onSource != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onCall != null)
                    OutlinedButton.icon(
                      onPressed: onCall,
                      icon: const Icon(Icons.call_outlined, size: 18),
                      label: const Text(
                        'Call',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  if (onSource != null)
                    OutlinedButton.icon(
                      onPressed: onSource,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text(
                        'Source',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
