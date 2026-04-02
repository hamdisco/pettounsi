import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/date_formatters.dart';
import '../../ui/app_theme.dart';
import '../../ui/premium_cards.dart';
import '../../ui/premium_feedback.dart';
import '../../ui/premium_pills.dart';
import '../../ui/premium_sections.dart';
import '../../ui/premium_sheet.dart';
import 'pet_reports_repository.dart';

class PetReportsPage extends StatefulWidget {
  const PetReportsPage({super.key});

  @override
  State<PetReportsPage> createState() => _PetReportsPageState();
}

class _PetReportsPageState extends State<PetReportsPage> {
  final _searchCtrl = TextEditingController();

  String _query = '';
  bool _mineOnly = false;
  String _type = 'all'; // all | lost | found
  String _status = 'open'; // open | resolved | all

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matches(_PetReportItem item) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;

    return item.title.toLowerCase().contains(q) ||
        item.description.toLowerCase().contains(q) ||
        item.animal.toLowerCase().contains(q) ||
        item.address.toLowerCase().contains(q) ||
        item.city.toLowerCase().contains(q) ||
        item.governorate.toLowerCase().contains(q) ||
        item.authorName.toLowerCase().contains(q) ||
        item.phone.toLowerCase().contains(q);
  }

  Future<void> _openDirections(_PetReportItem item) async {
    if (item.lat == null || item.lng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No coordinates available')));
      return;
    }

    final lat = item.lat!;
    final lng = item.lng!;
    final safeLabel = item.title.replaceAll(',', ' ');

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

  Future<void> _callPhone(String phone) async {
    final raw = phone.trim();
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

  Future<void> _openSource(String url) async {
    final raw = url.trim();
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

  void _openDetails(_PetReportItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PetReportDetailsSheet(
        item: item,
        onDirections: item.hasCoords ? () => _openDirections(item) : null,
        onCall: item.hasPhone ? () => _callPhone(item.phone) : null,
        onSource: item.hasSource ? () => _openSource(item.sourceUrl) : null,
        onResolve: (!item.isResolved && item.isMine)
            ? () async {
                try {
                  await PetReportsRepository.instance.markResolved(item.id);
                  if (!mounted) return;
                  Navigator.pop(context);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not update report: $e')),
                  );
                }
              }
            : null,
        onReopen: (item.isResolved && item.isMine)
            ? () async {
                try {
                  await PetReportsRepository.instance.reopenReport(item.id);
                  if (!mounted) return;
                  Navigator.pop(context);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not reopen report: $e')),
                  );
                }
              }
            : null,
        onDelete: item.isMine
            ? () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete report?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (ok != true) return;

                try {
                  await PetReportsRepository.instance.deleteReport(item.id);
                  if (!mounted) return;
                  Navigator.pop(context);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not delete report: $e')),
                  );
                }
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text(
          'Lost & found reports',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: PetReportsRepository.instance.streamAll(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              children: const [
                PremiumSkeletonCard(height: 100, radius: 24),
                SizedBox(height: 12),
                PremiumMiniEmptyCard(
                  icon: Icons.sync_rounded,
                  iconColor: Color(0xFF7C62D7),
                  iconBg: AppTheme.lilac,
                  title: 'Loading reports',
                  subtitle: 'Fetching the latest lost & found activity.',
                ),
                SizedBox(height: 12),
                PremiumSkeletonCard(height: 210, radius: 22),
                SizedBox(height: 10),
                PremiumSkeletonCard(height: 210, radius: 22),
                SizedBox(height: 10),
                PremiumSkeletonCard(height: 210, radius: 22),
              ],
            );
          }

          final items =
              snap.data!.docs.map((d) => _PetReportItem.fromDoc(d)).where((e) {
                if (_mineOnly && !e.isMine) return false;
                if (_type != 'all' && e.type != _type) return false;
                if (_status != 'all') {
                  if (_status == 'open' && e.isResolved) return false;
                  if (_status == 'resolved' && !e.isResolved) return false;
                }
                return _matches(e);
              }).toList()..sort((a, b) {
                final ad = a.createdAt ?? DateTime(1970);
                final bd = b.createdAt ?? DateTime(1970);
                return bd.compareTo(ad);
              });

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            children: [
              const _PetReportsHero(),
              const SizedBox(height: 12),
              PremiumCardSurface(
                radius: BorderRadius.circular(22),
                padding: const EdgeInsets.all(12),
                shadowOpacity: 0.08,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Search reports…',
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
                        fillColor: AppTheme.mist,
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
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PremiumPill(
                          label: _mineOnly ? 'My reports' : 'All reports',
                          icon: Icons.person_outline_rounded,
                          selected: _mineOnly,
                          showCheckWhenSelected: _mineOnly,
                          onTap: () => setState(() => _mineOnly = !_mineOnly),
                          fontSize: 12,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                        ),
                        _chip('All', 'all'),
                        _chip('Lost', 'lost'),
                        _chip('Found', 'found'),
                        _statusChip('Open', 'open'),
                        _statusChip('Resolved', 'resolved'),
                        _statusChip('Any status', 'all'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PremiumCardSurface(
                radius: BorderRadius.circular(18),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shadowOpacity: 0.05,
                child: Row(
                  children: [
                    PremiumCardBadge(
                      label: '${items.length}',
                      bg: AppTheme.blush,
                      fg: AppTheme.orangeDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        items.length == 1
                            ? '1 report available'
                            : '${items.length} reports available',
                        style: TextStyle(
                          color: AppTheme.muted.withAlpha(220),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                const PremiumEmptyStateCard(
                  icon: Icons.search_off_rounded,
                  iconColor: Color(0xFF4C79C8),
                  iconBg: AppTheme.sky,
                  title: 'No matching reports',
                  subtitle: 'Try another keyword or change the filters above.',
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PetReportCard(
                      item: item,
                      onTap: () => _openDetails(item),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, String value) {
    final active = _type == value;
    return PremiumPill(
      label: label,
      selected: active,
      showCheckWhenSelected: active,
      onTap: () => setState(() => _type = value),
      fontSize: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    );
  }

  Widget _statusChip(String label, String value) {
    final active = _status == value;
    return PremiumPill(
      label: label,
      selected: active,
      showCheckWhenSelected: active,
      onTap: () => setState(() => _status = value),
      fontSize: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    );
  }
}

class _PetReportsHero extends StatelessWidget {
  const _PetReportsHero();

  @override
  Widget build(BuildContext context) {
    return PremiumCardSurface(
      radius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(14),
      shadowOpacity: 0.14,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.blush,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: AppTheme.orangeDark,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lost & found reports',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Follow the latest community reports, open directions, and manage your own cases.',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                    height: 1.16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PetReportCard extends StatelessWidget {
  const _PetReportCard({required this.item, required this.onTap});

  final _PetReportItem item;
  final VoidCallback onTap;

  Color get accent =>
      item.type == 'lost' ? const Color(0xFFE05555) : const Color(0xFF2F9A6A);

  Color get bg => item.type == 'lost' ? const Color(0xFFFFEBEB) : AppTheme.mint;

  String get locationLine {
    final parts = <String>[
      if (item.address.isNotEmpty) item.address,
      if (item.city.isNotEmpty) item.city,
      if (item.governorate.isNotEmpty) item.governorate,
    ];
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return PremiumCardSurface(
      onTap: onTap,
      radius: BorderRadius.circular(22),
      padding: EdgeInsets.zero,
      shadowOpacity: 0.10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumSoftPanel(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            radius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
            gradient: const LinearGradient(
              colors: [AppTheme.blush, AppTheme.lilac, AppTheme.sky],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderColor: Colors.transparent,
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Icon(
                    item.type == 'lost' ? Icons.pets : Icons.pets_outlined,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      height: 1.12,
                    ),
                  ),
                ),
                PremiumCardBadge(
                  label: item.isResolved ? 'Resolved' : 'Open',
                  bg: item.isResolved ? AppTheme.mint : bg,
                  fg: item.isResolved ? const Color(0xFF2F9A6A) : accent,
                  borderColor: AppTheme.outline,
                  fontSize: 10.8,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PremiumCardBadge(
                      label: item.type == 'lost' ? 'Lost' : 'Found',
                      icon: item.type == 'lost'
                          ? Icons.search_rounded
                          : Icons.check_circle_outline_rounded,
                      bg: bg,
                      fg: accent,
                    ),
                    if (item.animal.isNotEmpty)
                      PremiumCardBadge(
                        label: item.animal,
                        icon: Icons.pets_rounded,
                        bg: AppTheme.lilac,
                        fg: const Color(0xFF7C62D7),
                      ),
                    if (item.createdAt != null)
                      PremiumCardBadge(
                        label: AppDateFmt.dMy(item.createdAt),
                        icon: Icons.schedule_rounded,
                        bg: AppTheme.sky,
                        fg: const Color(0xFF4C79C8),
                      ),
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    item.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.ink.withAlpha(180),
                      fontWeight: FontWeight.w700,
                      height: 1.24,
                    ),
                  ),
                ],
                if (locationLine.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  PremiumMetaRow(
                    icon: Icons.place_rounded,
                    text: locationLine,
                    iconColor: accent,
                    textColor: AppTheme.ink.withAlpha(175),
                    fontSize: 11.9,
                  ),
                ],
                const SizedBox(height: 10),
                PremiumCardActionRow(
                  icon: Icons.visibility_outlined,
                  label: item.isMine
                      ? 'Open and manage this report'
                      : 'Open report details',
                  iconColor: accent,
                  textColor: accent,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.ink.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PetReportDetailsSheet extends StatelessWidget {
  const _PetReportDetailsSheet({
    required this.item,
    this.onDirections,
    this.onCall,
    this.onSource,
    this.onResolve,
    this.onReopen,
    this.onDelete,
  });

  final _PetReportItem item;
  final VoidCallback? onDirections;
  final VoidCallback? onCall;
  final VoidCallback? onSource;
  final VoidCallback? onResolve;
  final VoidCallback? onReopen;
  final VoidCallback? onDelete;

  Color get accent =>
      item.type == 'lost' ? const Color(0xFFE05555) : const Color(0xFF2F9A6A);

  Color get bg => item.type == 'lost' ? const Color(0xFFFFEBEB) : AppTheme.mint;

  String get locationLine {
    final parts = <String>[
      if (item.address.isNotEmpty) item.address,
      if (item.city.isNotEmpty) item.city,
      if (item.governorate.isNotEmpty) item.governorate,
    ];
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBottomSheetFrame(
      icon: item.type == 'lost' ? Icons.pets : Icons.pets_outlined,
      iconColor: accent,
      iconBg: bg,
      title: item.title,
      subtitle: item.isResolved
          ? 'This report has been marked as resolved.'
          : 'Open report details and quick actions.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.photoUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 1.45,
                child: Image.network(
                  item.photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: bg,
                    alignment: Alignment.center,
                    child: Icon(
                      item.type == 'lost' ? Icons.pets : Icons.pets_outlined,
                      color: accent,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PremiumCardBadge(
                label: item.type == 'lost' ? 'Lost' : 'Found',
                icon: item.type == 'lost'
                    ? Icons.search_rounded
                    : Icons.check_circle_outline_rounded,
                bg: bg,
                fg: accent,
              ),
              PremiumCardBadge(
                label: item.isResolved ? 'Resolved' : 'Open',
                bg: item.isResolved ? AppTheme.mint : bg,
                fg: item.isResolved ? const Color(0xFF2F9A6A) : accent,
              ),
              if (item.animal.isNotEmpty)
                PremiumCardBadge(
                  label: item.animal,
                  icon: Icons.pets_rounded,
                  bg: AppTheme.lilac,
                  fg: const Color(0xFF7C62D7),
                ),
              if (item.createdAt != null)
                PremiumCardBadge(
                  label: AppDateFmt.dMyHm(item.createdAt),
                  icon: Icons.schedule_rounded,
                  bg: AppTheme.sky,
                  fg: const Color(0xFF4C79C8),
                ),
            ],
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF8FD),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Text(
                item.description,
                style: TextStyle(
                  color: AppTheme.ink.withAlpha(180),
                  fontWeight: FontWeight.w700,
                  height: 1.24,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          PremiumSheetInfoCard(
            icon: Icons.person_outline_rounded,
            iconBg: AppTheme.sky,
            iconFg: const Color(0xFF4C79C8),
            title: 'Reporter',
            subtitle: item.authorName.isEmpty ? 'Unknown' : item.authorName,
            compact: true,
          ),
          if (locationLine.isNotEmpty) ...[
            const SizedBox(height: 10),
            PremiumSheetInfoCard(
              icon: Icons.place_rounded,
              iconBg: bg,
              iconFg: accent,
              title: 'Location',
              subtitle: locationLine,
              compact: true,
            ),
          ],
          if (item.phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            PremiumSheetInfoCard(
              icon: Icons.call_outlined,
              iconBg: AppTheme.mint,
              iconFg: const Color(0xFF2F9A6A),
              title: 'Phone',
              subtitle: item.phone,
              compact: true,
            ),
          ],
          const SizedBox(height: 14),
          if (onDirections != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDirections,
                icon: const Icon(Icons.near_me_rounded),
                label: const Text(
                  'Directions',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          if (onCall != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.call_outlined),
                label: const Text(
                  'Call',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
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
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text(
                  'Mark resolved',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
          if (onReopen != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onReopen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C62D7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Reopen report',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
          if (onDelete != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text(
                  'Delete report',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE05555),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PetReportItem {
  const _PetReportItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.address,
    required this.city,
    required this.governorate,
    required this.animal,
    required this.phone,
    required this.photoUrl,
    required this.sourceUrl,
    required this.authorId,
    required this.authorName,
    required this.isResolved,
    required this.createdAt,
    required this.lat,
    required this.lng,
    required this.isMine,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final String address;
  final String city;
  final String governorate;
  final String animal;
  final String phone;
  final String photoUrl;
  final String sourceUrl;
  final String authorId;
  final String authorName;
  final bool isResolved;
  final DateTime? createdAt;
  final double? lat;
  final double? lng;
  final bool isMine;

  bool get hasCoords => lat != null && lng != null;
  bool get hasPhone => phone.trim().isNotEmpty;
  bool get hasSource => sourceUrl.trim().isNotEmpty;

  factory _PetReportItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final type = (d['type'] ?? '').toString().trim().toLowerCase();
    final animal = (d['animal'] ?? '').toString().trim();
    final title = (d['title'] ?? '').toString().trim();

    final t = title.isNotEmpty
        ? title
        : animal.isNotEmpty
        ? '${type == 'found' ? 'Found' : 'Lost'} $animal'
        : (type == 'found' ? 'Found Pet' : 'Lost Pet');

    DateTime? createdAt;
    final ts = d['createdAt'];
    if (ts is Timestamp) createdAt = ts.toDate();

    double? lat;
    double? lng;
    final latRaw = d['lat'];
    final lngRaw = d['lng'];
    if (latRaw is num) lat = latRaw.toDouble();
    if (lngRaw is num) lng = lngRaw.toDouble();

    return _PetReportItem(
      id: doc.id,
      type: type == 'found' ? 'found' : 'lost',
      title: t,
      description: (d['description'] ?? '').toString().trim(),
      address: (d['address'] ?? '').toString().trim(),
      city: (d['city'] ?? '').toString().trim(),
      governorate: (d['governorate'] ?? '').toString().trim(),
      animal: animal,
      phone: (d['phone'] ?? '').toString().trim(),
      photoUrl: ((d['photoUrl'] ?? d['imageUrl'] ?? '')).toString().trim(),
      sourceUrl: (d['sourceUrl'] ?? '').toString().trim(),
      authorId: (d['authorId'] ?? '').toString().trim(),
      authorName: (d['authorName'] ?? 'User').toString().trim(),
      isResolved:
          d['isResolved'] == true ||
          (d['status'] ?? '').toString().trim().toLowerCase() == 'resolved',
      createdAt: createdAt,
      lat: lat,
      lng: lng,
      isMine: (d['authorId'] ?? '').toString().trim() == currentUid,
    );
  }
}
