import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ui/app_theme.dart';
import '../../ui/premium_permission_dialog.dart';
import '../map/map_models.dart';
import '../map/map_page.dart';
import 'models/directory_item.dart';
import 'widgets/directory_widgets.dart';

enum DirectorySort { name, distance, upcoming }

class DirectoryListPage extends StatefulWidget {
  const DirectoryListPage({
    super.key,
    required this.title,
    required this.collectionName,
    required this.icon,
    required this.emptyText,
    this.accentColor,
    this.heroSubtitle,
  });

  final String title;
  final String collectionName;
  final IconData icon;
  final String emptyText;
  final Color? accentColor;
  final String? heroSubtitle;

  @override
  State<DirectoryListPage> createState() => _DirectoryListPageState();
}

class _DirectoryListPageState extends State<DirectoryListPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  bool _nearMe = false;
  bool _locBusy = false;
  LatLng? _me;

  late DirectorySort _sort;
  bool _upcomingOnly = false;

  bool get _isEvents => widget.collectionName == 'events';
  bool get _isVets => widget.collectionName == 'vets';

  @override
  void initState() {
    super.initState();
    _sort = _isEvents ? DirectorySort.upcoming : DirectorySort.name;
    _upcomingOnly = _isEvents;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _subtitle {
    if (widget.heroSubtitle != null && widget.heroSubtitle!.trim().isNotEmpty) {
      return widget.heroSubtitle!.trim();
    }

    switch (widget.collectionName) {
      case 'vets':
        return 'Trusted clinics and emergency contacts — find help fast.';
      case 'events':
        return 'Upcoming meetups, adoption days, and pet-friendly events.';
      case 'petshops':
        return 'Food, grooming and accessories — discover nearby shops.';
      default:
        return 'Browse places and open Directions to navigate quickly.';
    }
  }

  bool _matches(DirectoryItem item) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;

    return item.name.toLowerCase().contains(q) ||
        item.address.toLowerCase().contains(q) ||
        item.city.toLowerCase().contains(q) ||
        item.governorate.toLowerCase().contains(q) ||
        (item.phone ?? '').toLowerCase().contains(q) ||
        (item.notes ?? '').toLowerCase().contains(q);
  }

  Future<void> _openDirections(DirectoryItem item) async {
    if (item.lat == null || item.lng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No coordinates available')));
      return;
    }

    final lat = item.lat!;
    final lng = item.lng!;
    final safeLabel = item.name.replaceAll(',', ' ');

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open map')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open map')));
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
      ).showSnackBar(const SnackBar(content: Text('Invalid URL')));
      return;
    }

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  double get _nearMeRadiusKm {
    switch (widget.collectionName) {
      case 'events':
        return 120;
      case 'vets':
      case 'petshops':
        return 50;
      default:
        return 50;
    }
  }

  Future<void> _toggleNearMe() async {
    if (_nearMe) {
      setState(() => _nearMe = false);
      return;
    }

    if (_me != null) {
      setState(() => _nearMe = true);
      return;
    }

    setState(() => _locBusy = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        await showPremiumPermissionDialog(
          context: context,
          icon: Icons.location_off_rounded,
          tint: AppTheme.orangeDark,
          iconBg: AppTheme.softOrange,
          title: 'Turn on location',
          message:
              'To use Near me, enable Location Services on your phone, then come back to Pettounsi.',
          primaryLabel: 'Open settings',
          onPrimary: () => Geolocator.openLocationSettings(),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        if (permission == LocationPermission.deniedForever) {
          await showPremiumPermissionDialog(
            context: context,
            icon: Icons.location_searching_rounded,
            tint: const Color(0xFF7C62D7),
            iconBg: AppTheme.lilac,
            title: 'Allow location access',
            message:
                'Near me needs location permission for Pettounsi. Open app settings and allow access to continue.',
            primaryLabel: 'Open app settings',
            onPrimary: () => Geolocator.openAppSettings(),
            secondaryLabel: 'Later',
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _me = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _nearMe = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get your location')),
      );
    } finally {
      if (mounted) setState(() => _locBusy = false);
    }
  }

  void _openMap() {
    final type = _pinTypeFor(widget.collectionName);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapPage(
          initialFilter: type,
          initialCenter: _me,
          initialZoom: _me != null ? 12.8 : null,
          standalone: true,
        ),
      ),
    );
  }

  MapPinType? _pinTypeFor(String collectionName) {
    switch (collectionName) {
      case 'vets':
        return MapPinType.vet;
      case 'petshops':
        return MapPinType.petshop;
      case 'events':
        return MapPinType.event;
      default:
        return null;
    }
  }

  void _openDetails(DirectoryItem item, Color accent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DirectoryDetailsSheet(
        item: item,
        accent: accent,
        leadingIcon: widget.icon,
        onDirections: item.hasCoords ? () => _openDirections(item) : null,
        onCall: item.hasPhone ? () => _callPhone(item.phone) : null,
        onSource: item.hasSource ? () => _openSource(item.sourceUrl) : null,
      ),
    );
  }

  void _setSort(DirectorySort s) {
    setState(() => _sort = s);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppTheme.orangeDark;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          PopupMenuButton<DirectorySort>(
            tooltip: 'Sort',
            onSelected: _setSort,
            itemBuilder: (_) {
              final items = <PopupMenuEntry<DirectorySort>>[
                const PopupMenuItem(
                  value: DirectorySort.name,
                  child: Text('Sort by name'),
                ),
                const PopupMenuItem(
                  value: DirectorySort.distance,
                  child: Text('Sort by distance'),
                ),
              ];
              if (_isEvents) {
                items.insert(
                  0,
                  const PopupMenuItem(
                    value: DirectorySort.upcoming,
                    child: Text('Sort by date (upcoming)'),
                  ),
                );
              }
              return items;
            },
            icon: const Icon(Icons.sort_rounded),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(widget.collectionName)
            .snapshots(),
        builder: (context, snap) {
          final header = <Widget>[
            DirectoryHeroHeader(
              title: widget.title,
              subtitle: _subtitle,
              accent: accent,
              icon: widget.icon,
            ),
            DirectoryFiltersBar(
              accent: accent,
              onMap: _openMap,
              nearMeActive: _nearMe,
              locBusy: _locBusy,
              onToggleNearMe: _toggleNearMe,
              isEvents: _isEvents,
              upcomingOnly: _upcomingOnly,
              onToggleUpcoming: _isEvents
                  ? () => setState(() => _upcomingOnly = !_upcomingOnly)
                  : null,
            ),
            DirectorySearchBox(
              controller: _searchCtrl,
              query: _query,
              accent: accent,
              hintText: 'Search ${widget.title.toLowerCase()}...',
              onChanged: (v) => setState(() => _query = v),
              onClear: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
            ),
            DirectoryTopHintCard(
              accent: accent,
              isEvents: _isEvents,
              isVets: _isVets,
            ),
          ];

          Widget buildList(List<Widget> children) {
            return RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 350));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(bottom: 18),
                children: children,
              ),
            );
          }

          if (snap.hasError) {
            return buildList([
              ...header,
              DirectoryStateCard(
                icon: Icons.cloud_off_rounded,
                title: 'Could not load ${widget.title.toLowerCase()}',
                subtitle: 'Please check your connection and try again.',
                accent: accent,
              ),
            ]);
          }

          if (!snap.hasData) {
            return buildList([
              ...header,
              const DirectoryCardSkeleton(),
              const DirectoryCardSkeleton(),
              const DirectoryCardSkeleton(),
              const DirectoryCardSkeleton(),
            ]);
          }

          final docs = snap.data!.docs;
          final now = DateTime.now();

          var items = docs
              .map((d) => DirectoryItem.fromDoc(d, widget.collectionName))
              .where((e) => e.isActive)
              .where(_matches)
              .toList();

          if (_isEvents && _upcomingOnly) {
            items = items.where((e) {
              if (e.startsAt == null) return true;
              return e.startsAt!.isAfter(
                now.subtract(const Duration(hours: 2)),
              );
            }).toList();
          }

          if (_nearMe && _me != null) {
            final me = _me!;
            const dist = Distance();

            items = items
                .where((e) => e.hasCoords)
                .map((e) {
                  final km = dist.as(
                    LengthUnit.Kilometer,
                    me,
                    LatLng(e.lat!, e.lng!),
                  );
                  return e.withDistanceKm(km);
                })
                .where(
                  (e) => (e.distanceKm ?? double.infinity) <= _nearMeRadiusKm,
                )
                .toList();
          }

          items.sort((a, b) {
            int cmp;

            if (_nearMe || _sort == DirectorySort.distance) {
              final da = a.distanceKm;
              final db = b.distanceKm;
              if (da == null && db == null) {
                cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
              } else if (da == null) {
                cmp = 1;
              } else if (db == null) {
                cmp = -1;
              } else {
                cmp = da.compareTo(db);
              }
              if (cmp != 0) return cmp;
            }

            if (_sort == DirectorySort.upcoming && _isEvents) {
              final ta = a.startsAt;
              final tb = b.startsAt;
              if (ta == null && tb == null) {
                cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
              } else if (ta == null) {
                cmp = 1;
              } else if (tb == null) {
                cmp = -1;
              } else {
                cmp = ta.compareTo(tb);
              }
              if (cmp != 0) return cmp;
            }

            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

          if (items.isEmpty) {
            final q = _query.trim();
            return buildList([
              ...header,
              DirectoryStateCard(
                icon: q.isEmpty ? widget.icon : Icons.search_off_rounded,
                title: q.isEmpty ? widget.emptyText : 'No results for "$q"',
                subtitle: q.isEmpty
                    ? (_nearMe
                          ? 'No nearby places were found around your current location.'
                          : 'Nothing is available here yet. Please check back soon.')
                    : 'Try another keyword like city, address, name, or phone.',
                accent: accent,
              ),
            ]);
          }

          final children = <Widget>[
            ...header,
            DirectoryResultsSummary(
              count: items.length,
              accent: accent,
              title: widget.title,
              query: _query.trim(),
            ),
            for (final item in items)
              DirectoryItemCard(
                item: item,
                accent: accent,
                leadingIcon: widget.icon,
                onTap: () => _openDetails(item, accent),
                onDirections: item.hasCoords
                    ? () => _openDirections(item)
                    : null,
                onCall: item.hasPhone ? () => _callPhone(item.phone) : null,
                onSource: item.hasSource
                    ? () => _openSource(item.sourceUrl)
                    : null,
              ),
          ];

          return buildList(children);
        },
      ),
    );
  }
}
