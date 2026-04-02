import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';

class PointsHistoryPage extends StatelessWidget {
  const PointsHistoryPage({super.key});

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Points activity')),
        body: const Center(
          child: Text('Please sign in to view your points activity.'),
        ),
      );
    }

    final claimsStream = FirebaseFirestore.instance
        .collection('game_claims')
        .where('uid', isEqualTo: uid)
        .snapshots();

    final redemptionsStream = FirebaseFirestore.instance
        .collection('accessory_redemptions')
        .where('uid', isEqualTo: uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Points activity')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: claimsStream,
        builder: (context, claimsSnap) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: redemptionsStream,
            builder: (context, redSnap) {
              if (claimsSnap.hasError || redSnap.hasError) {
                return Center(
                  child: Text(
                    'Failed to load history',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              }
              if (claimsSnap.connectionState == ConnectionState.waiting ||
                  redSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final entries = <_PointsHistoryEntry>[
                for (final doc in claimsSnap.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                  ...[if (_PointsHistoryEntry.fromGameClaim(doc) case final e?) e],
                for (final doc in redSnap.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                  ...[if (_PointsHistoryEntry.fromRedemption(doc) case final e?) e],
              ]..sort((a, b) => b.sortDate.compareTo(a.sortDate));

              if (entries.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No points activity yet.',
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final e = entries[index];
                  final amountColor = e.amount > 0
                      ? Colors.green.shade700
                      : e.amount < 0
                      ? Colors.red.shade700
                      : AppTheme.muted;
                  final amountText = e.amount > 0
                      ? '+${e.amount} pts'
                      : e.amount < 0
                      ? '${e.amount} pts'
                      : '0 pts';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: e.amount > 0
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.orange.withValues(alpha: 0.12),
                        child: Icon(
                          e.icon,
                          color: e.amount > 0
                              ? Colors.green.shade700
                              : AppTheme.orange,
                        ),
                      ),
                      title: Text(
                        e.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _StatusChip(
                                  label: e.statusLabel,
                                  tone: e.statusTone,
                                ),
                                if (e.meta != null && e.meta!.isNotEmpty)
                                  _MiniChip(label: e.meta!),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              e.dateLabel,
                              style: TextStyle(
                                color: AppTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Text(
                        amountText,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: amountColor,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final _StatusTone tone;
  const _StatusChip({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _StatusTone.pending => (
        Colors.orange.shade50,
        Colors.orange.shade800,
        Colors.orange.shade200,
      ),
      _StatusTone.success => (
        Colors.green.shade50,
        Colors.green.shade800,
        Colors.green.shade200,
      ),
      _StatusTone.danger => (
        Colors.red.shade50,
        Colors.red.shade800,
        Colors.red.shade200,
      ),
      _StatusTone.neutral => (
        Colors.grey.shade100,
        Colors.grey.shade800,
        Colors.grey.shade300,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.$3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colors.$2,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

enum _StatusTone { pending, success, danger, neutral }

class _PointsHistoryEntry {
  final String title;
  final int amount;
  final IconData icon;
  final String statusLabel;
  final _StatusTone statusTone;
  final String? meta;
  final DateTime sortDate;
  final String dateLabel;

  _PointsHistoryEntry({
    required this.title,
    required this.amount,
    required this.icon,
    required this.statusLabel,
    required this.statusTone,
    required this.sortDate,
    required this.dateLabel,
    this.meta,
  });

  static _PointsHistoryEntry? fromGameClaim(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final reward = (data['missionReward'] is num)
        ? (data['missionReward'] as num).toInt()
        : 0;
    final title = (data['missionTitle'] ?? 'Mission claim').toString();
    final ts =
        (data['updatedAt'] as Timestamp?) ?? (data['createdAt'] as Timestamp?);
    final date = ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);

    if (status != 'approved' || reward <= 0) return null;

    return _PointsHistoryEntry(
      title: title,
      amount: reward,
      icon: Icons.emoji_events_outlined,
      statusLabel: 'Approved',
      statusTone: _StatusTone.success,
      meta: (data['dayKey'] ?? '').toString().isEmpty
          ? null
          : 'Day ${(data['dayKey'] ?? '').toString()}',
      sortDate: date,
      dateLabel: _formatDate(date),
    );
  }

  static _PointsHistoryEntry? fromRedemption(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final cost = (data['pointsCost'] is num)
        ? (data['pointsCost'] as num).toInt()
        : 0;
    final title = (data['itemTitle'] ?? 'Accessory redemption').toString();
    final ts =
        (data['updatedAt'] as Timestamp?) ?? (data['createdAt'] as Timestamp?);
    final date = ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);

    if (cost <= 0) return null;
    if (status == 'declined' || status == 'canceled') return null;

    final amount = -cost;

    return _PointsHistoryEntry(
      title: title,
      amount: amount,
      icon: Icons.shopping_bag_outlined,
      statusLabel: switch (status) {
        'fulfilled' => 'Fulfilled',
        'approved' => 'Approved',
        _ => 'Pending',
      },
      statusTone: (status == 'fulfilled' || status == 'approved')
          ? _StatusTone.success
          : _StatusTone.pending,
      meta: 'Redeem request',
      sortDate: date,
      dateLabel: _formatDate(date),
    );
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day • $hh:$mm';
  }
}
