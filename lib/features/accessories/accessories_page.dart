import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/points_runtime.dart';
import '../../ui/app_theme.dart';
import '../../ui/premium_cards.dart';
import '../../ui/premium_feedback.dart';
import '../../ui/premium_pills.dart';

class AccessoriesPage extends StatefulWidget {
  const AccessoriesPage({super.key});

  @override
  State<AccessoriesPage> createState() => _AccessoriesPageState();
}

class _AccessoriesPageState extends State<AccessoriesPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _busy = false;
  String? _category;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _requestRedemption(
    _AccessoryDoc item,
    int officialPoints,
    int reservedPoints,
  ) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      _toast('Please sign in first.');
      return;
    }
    if (_busy) return;

    if (!item.isPublished) {
      _toast('This item is not available right now.');
      return;
    }
    if (!item.isRedeemable) {
      _toast('This item is not redeemable yet.');
      return;
    }
    if (item.pointsCost <= 0) {
      _toast('This item is not configured with a points cost.');
      return;
    }

    final availablePoints = math.max(0, officialPoints - reservedPoints);
    if (availablePoints < item.pointsCost) {
      _toast(
        'Not enough available points right now. '
        'Need ${item.pointsCost - availablePoints} more points.',
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redeem accessory?'),
        content: Text(
          'Request "${item.title}" for ${item.pointsCost} points?\n\n'
          'Your points stay in your official balance until the request is reviewed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send request'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final q = await _db
          .collection('accessory_redemptions')
          .where('uid', isEqualTo: uid)
          .where('itemId', isEqualTo: item.id)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        _toast('You already have a pending request for this item.');
        return;
      }

      final redemptionRef = _db.collection('accessory_redemptions').doc();

      await redemptionRef.set({
        'uid': uid,
        'itemId': item.id,
        'itemTitle': item.title,
        'itemCashPrice': item.cashPriceText,
        'pointsCost': item.pointsCost,
        'status': 'pending',
        'source': 'games_points',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userDisplayName': user?.displayName,
        'userEmail': user?.email,
      });

      _toast('Redemption request sent ✅ It will appear below.');
    } catch (e) {
      _toast('Could not send request: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Accessories')),
      body: uid == null || uid.isEmpty
          ? const _SignedOutAccessoriesView()
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _db.collection('users').doc(uid).snapshots(),
              builder: (context, userSnap) {
                final user = userSnap.data?.data() ?? <String, dynamic>{};
                _asInt(user['pointsBalance']);

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _db
                      .collection('game_claims')
                      .where('uid', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, claimsSnap) {
                    final approvedClaimPoints =
                        approvedClaimPointsFromSnapshots(claimsSnap.data?.docs);
                    final officialPoints = approvedClaimPoints;

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _db
                          .collection('accessory_redemptions')
                          .where('uid', isEqualTo: uid)
                          .snapshots(),
                      builder: (context, redemptionsSnap) {
                        final reservedPoints =
                            reservedRedemptionPointsFromSnapshots(
                              redemptionsSnap.data?.docs,
                            );
                        final pendingRequestCount =
                            _openRedemptionRequestsCount(
                              redemptionsSnap.data?.docs,
                            );
                        final availableForRequest = math.max(
                          0,
                          officialPoints - reservedPoints,
                        );

                        return StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>
                        >(
                          stream: _db
                              .collection('accessories')
                              .where('isPublished', isEqualTo: true)
                              .snapshots(),
                          builder: (context, itemsSnap) {
                            final items = <_AccessoryDoc>[];
                            if (itemsSnap.hasData) {
                              for (final d in itemsSnap.data!.docs) {
                                final item = _AccessoryDoc.fromDoc(d);
                                if (!item.isPublished) continue;
                                if (_category != null &&
                                    _category!.isNotEmpty &&
                                    item.category != _category) {
                                  continue;
                                }
                                items.add(item);
                              }
                              items.sort((a, b) {
                                final bySort = a.sortOrder.compareTo(
                                  b.sortOrder,
                                );
                                if (bySort != 0) return bySort;
                                return a.title.toLowerCase().compareTo(
                                  b.title.toLowerCase(),
                                );
                              });
                            }

                            final allCategories = <String>{};
                            if (itemsSnap.hasData) {
                              for (final d in itemsSnap.data!.docs) {
                                final item = _AccessoryDoc.fromDoc(d);
                                if (!item.isPublished) continue;
                                if (item.category.trim().isNotEmpty) {
                                  allCategories.add(item.category.trim());
                                }
                              }
                            }
                            final categories = allCategories.toList()..sort();

                            return CustomScrollView(
                              slivers: [
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      10,
                                      12,
                                      0,
                                    ),
                                    child: Column(
                                      children: [
                                        _PointsWalletHeader(
                                          points: officialPoints,
                                          reservedPoints: reservedPoints,
                                          pendingRequestCount:
                                              pendingRequestCount,
                                          busy: _busy,
                                        ),
                                        const SizedBox(height: 12),
                                        const _AccessoriesRedeemRulesCard(),
                                        const SizedBox(height: 12),
                                        _CategoryRow(
                                          categories: categories,
                                          selected: _category,
                                          onSelected: (v) =>
                                              setState(() => _category = v),
                                        ),
                                        const SizedBox(height: 14),
                                      ],
                                    ),
                                  ),
                                ),
                                if (itemsSnap.hasError)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: _ErrorCard(
                                        message:
                                            'Could not load accessories right now. Please try again later.\n${itemsSnap.error}',
                                      ),
                                    ),
                                  )
                                else if (!itemsSnap.hasData)
                                  SliverLayoutBuilder(
                                    builder: (context, constraints) {
                                      final width = constraints.crossAxisExtent;

                                      final int crossAxisCount = width >= 980
                                          ? 4
                                          : width >= 700
                                          ? 3
                                          : width >= 330
                                          ? 2
                                          : 1;

                                      final double mainAxisExtent =
                                          _mainAxisExtentFor(crossAxisCount);

                                      return SliverPadding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        sliver: SliverGrid(
                                          delegate: SliverChildBuilderDelegate(
                                            (_, __) => PremiumSkeletonCard(
                                              height: mainAxisExtent,
                                              radius: 24,
                                            ),
                                            childCount: crossAxisCount * 2,
                                          ),
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: crossAxisCount,
                                                mainAxisSpacing: 12,
                                                crossAxisSpacing: 12,
                                                mainAxisExtent: mainAxisExtent,
                                              ),
                                        ),
                                      );
                                    },
                                  )
                                else if (items.isEmpty)
                                  const SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: _EmptyAccessoriesCard(),
                                    ),
                                  )
                                else
                                  SliverLayoutBuilder(
                                    builder: (context, constraints) {
                                      final width = constraints.crossAxisExtent;

                                      final int crossAxisCount = width >= 980
                                          ? 4
                                          : width >= 700
                                          ? 3
                                          : width >= 330
                                          ? 2
                                          : 1;

                                      final double mainAxisExtent =
                                          _mainAxisExtentFor(crossAxisCount);

                                      return SliverPadding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        sliver: SliverGrid(
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: crossAxisCount,
                                                mainAxisSpacing: 12,
                                                crossAxisSpacing: 12,
                                                mainAxisExtent: mainAxisExtent,
                                              ),
                                          delegate: SliverChildBuilderDelegate((
                                            context,
                                            i,
                                          ) {
                                            final item = items[i];
                                            return _AccessoryCard(
                                              item: item,
                                              points: availableForRequest,
                                              busy: _busy,
                                              onRedeem: () =>
                                                  _requestRedemption(
                                                    item,
                                                    officialPoints,
                                                    reservedPoints,
                                                  ),
                                            );
                                          }, childCount: items.length),
                                        ),
                                      );
                                    },
                                  ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      18,
                                      12,
                                      16,
                                    ),
                                    child: _RedemptionHistoryCard(uid: uid),
                                  ),
                                ),
                              ],
                            );
                          },
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

double _mainAxisExtentFor(int crossAxisCount) {
  if (crossAxisCount >= 4) return 310;
  if (crossAxisCount == 3) return 324;
  if (crossAxisCount == 2) return 382;
  return 340;
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return 0;
}

int _openRedemptionRequestsCount(
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? docs,
) {
  var count = 0;
  for (final doc in docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
    final status = (doc.data()['status'] ?? '').toString().toLowerCase();
    if (status == 'pending' || status == 'approved') count += 1;
  }
  return count;
}

class _SignedOutAccessoriesView extends StatelessWidget {
  const _SignedOutAccessoriesView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        _SignInInfoCard(),
        SizedBox(height: 12),
        _AccessoriesRedeemRulesCard(),
        SizedBox(height: 12),
        _EmptyAccessoriesCard(showHintOnly: true),
      ],
    );
  }
}

class _SignInInfoCard extends StatelessWidget {
  const _SignInInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.orange.withAlpha(16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.shopping_bag_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sign in to view rewards',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  'Sign in to browse rewards and send redemption requests.',
                  style: TextStyle(
                    color: AppTheme.ink.withAlpha(150),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.3,
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

class _PointsWalletHeader extends StatelessWidget {
  const _PointsWalletHeader({
    required this.points,
    required this.reservedPoints,
    required this.pendingRequestCount,
    required this.busy,
  });

  final int points;
  final int reservedPoints;
  final int pendingRequestCount;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final availablePoints = math.max(0, points - reservedPoints);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE8F2), Color(0xFFF4ECFF), Color(0xFFEAF4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.75),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(210),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: AppTheme.orangeDark,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rewards',
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.8,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Use your official points on available items',
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.7,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(210),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: const Text(
                    'Sending',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  label: 'Official',
                  value: '$points pts',
                  icon: Icons.stars_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  label: 'Available',
                  value: '$availablePoints pts',
                  icon: Icons.redeem_rounded,
                ),
              ),
            ],
          ),
          if (reservedPoints > 0 || pendingRequestCount > 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(210),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Text(
                '$pendingRequestCount open ${pendingRequestCount == 1 ? 'request reserves' : 'requests reserve'} $reservedPoints pts.',
                style: TextStyle(
                  color: AppTheme.ink.withAlpha(180),
                  fontWeight: FontWeight.w700,
                  fontSize: 11.7,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccessoriesRedeemRulesCard extends StatelessWidget {
  const _AccessoriesRedeemRulesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppTheme.lilac,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'How redemption works',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RuleLine('Mission points count after approval.'),
          _RuleLine('Official points can be used here.'),
          _RuleLine('Sending a request does not deduct points immediately.'),
          _RuleLine('Open requests temporarily reserve the required points.'),
          _RuleLine('Pettounsi Team reviews redemption.'),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 1),
        children: [
          _FilterChipButton(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final c in categories) ...[
            const SizedBox(width: 8),
            _FilterChipButton(
              label: c,
              selected: selected == c,
              onTap: () => onSelected(c),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumPill(
      label: label,
      selected: selected,
      onTap: onTap,
      fontSize: 12.2,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: AppTheme.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.ink.withAlpha(150),
                fontWeight: FontWeight.w700,
                fontSize: 12.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessoryCard extends StatelessWidget {
  const _AccessoryCard({
    required this.item,
    required this.points,
    required this.busy,
    required this.onRedeem,
  });

  final _AccessoryDoc item;
  final int points;
  final bool busy;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final enough = points >= item.pointsCost;
    final canRedeem = !busy && item.isRedeemable && enough;
    final needMore = math.max(0, item.pointsCost - points);

    final statusColor = !item.isRedeemable
        ? AppTheme.muted.withAlpha(180)
        : enough
        ? const Color(0xFF15803D)
        : const Color(0xFFB45309);

    final statusText = !item.isRedeemable
        ? 'Not redeemable yet'
        : enough
        ? 'Ready to request'
        : 'Need $needMore more pts';

    final buttonLabel = !item.isRedeemable
        ? 'Unavailable'
        : enough
        ? 'Request redeem'
        : 'Need more points';

    return PremiumCardSurface(
      radius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(12),
      shadowOpacity: 0.14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: item.fallbackColor,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (item.imageUrl.isNotEmpty)
                  Positioned.fill(
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _ItemIconPlaceholder(item: item),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: item.fallbackColor,
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Positioned.fill(child: _ItemIconPlaceholder(item: item)),
                Positioned(
                  top: 8,
                  right: 8,
                  child: PremiumCardBadge(
                    label: '${item.pointsCost} pts',
                    icon: Icons.stars_rounded,
                    bg: Colors.white.withAlpha(230),
                    fg: AppTheme.orangeDark,
                    borderColor: Colors.white.withAlpha(170),
                    fontSize: 10.8,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (item.category.isNotEmpty)
                Expanded(
                  child: _CompactMetaChip(
                    icon: Icons.grid_view_rounded,
                    label: item.category,
                    bg: AppTheme.lilac,
                    fg: const Color(0xFF6B56C9),
                  ),
                ),
              if (item.category.isNotEmpty) const SizedBox(width: 8),
              Expanded(
                child: _CompactMetaChip(
                  icon: Icons.inventory_2_outlined,
                  label: item.stock > 0
                      ? 'Stock ${item.stock}'
                      : 'Out of stock',
                  bg: AppTheme.sky,
                  fg: const Color(0xFF4C79C8),
                ),
              ),
            ],
          ),
          if (item.cashPriceText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.sell_outlined, size: 15, color: AppTheme.roseDark),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.cashPriceText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.roseDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 13.8,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.subtitle.isEmpty ? item.description : item.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.ink.withAlpha(160),
              fontWeight: FontWeight.w700,
              fontSize: 11.9,
              height: 1.22,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                !item.isRedeemable
                    ? Icons.lock_outline_rounded
                    : enough
                    ? Icons.check_circle_rounded
                    : Icons.stars_rounded,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: canRedeem ? onRedeem : null,
              icon: const Icon(Icons.redeem_outlined, size: 18),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMetaChip extends StatelessWidget {
  const _CompactMetaChip({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 11.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemIconPlaceholder extends StatelessWidget {
  const _ItemIconPlaceholder({required this.item});

  final _AccessoryDoc item;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: item.fallbackColor,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.emoji.isNotEmpty)
            Text(item.emoji, style: const TextStyle(fontSize: 30))
          else
            Icon(item.iconData, size: 34, color: AppTheme.ink.withAlpha(180)),
          if (item.category.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.category,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink.withAlpha(140),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyAccessoriesCard extends StatelessWidget {
  const _EmptyAccessoriesCard({this.showHintOnly = false});

  final bool showHintOnly;

  @override
  Widget build(BuildContext context) {
    return PremiumEmptyStateCard(
      icon: Icons.inventory_2_outlined,
      iconColor: const Color(0xFF7C62D7),
      iconBg: AppTheme.lilac,
      title: 'No accessories yet',
      subtitle: showHintOnly
          ? 'Accessories will appear here as soon as they are available.'
          : 'No accessories match this filter right now.',
      compact: true,
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFDCDC)),
      ),
      child: Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _RedemptionHistoryCard extends StatelessWidget {
  const _RedemptionHistoryCard({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('accessory_redemptions')
        .where('uid', isEqualTo: uid)
        .limit(50);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My redemption requests',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15.5,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: q.snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return _ErrorCard(
                  message: 'Could not load redemptions.\n${snap.error}',
                );
              }
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = [...snap.data!.docs]
                ..sort((a, b) {
                  final ta = a.data()['createdAt'];
                  final tb = b.data()['createdAt'];
                  final da = ta is Timestamp ? ta.toDate() : DateTime(1970);
                  final db = tb is Timestamp ? tb.toDate() : DateTime(1970);
                  return db.compareTo(da);
                });

              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F4F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Text(
                    'No requests yet. Earn points in Games and request an accessory here.',
                    style: TextStyle(
                      color: AppTheme.ink.withAlpha(145),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  for (int i = 0; i < docs.length; i++) ...[
                    _RedemptionRow(data: docs[i].data()),
                    if (i != docs.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: Colors.black.withAlpha(18)),
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RedemptionRow extends StatelessWidget {
  const _RedemptionRow({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final title = (data['itemTitle'] ?? 'Accessory').toString();
    final pointsCost = _asInt(data['pointsCost']);
    final status = (data['status'] ?? 'pending').toString();
    final ownerNote = (data['ownerNote'] ?? '').toString().trim();
    final dt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : null;

    Color chipBg;
    Color chipFg;
    IconData chipIcon;
    switch (status) {
      case 'approved':
        chipBg = const Color(0xFFEFF8F2);
        chipFg = const Color(0xFF15803D);
        chipIcon = Icons.check_circle_outline;
        break;
      case 'fulfilled':
        chipBg = const Color(0xFFEAF4FF);
        chipFg = const Color(0xFF1D4ED8);
        chipIcon = Icons.inventory_2_outlined;
        break;
      case 'declined':
      case 'canceled':
        chipBg = const Color(0xFFFFEFEF);
        chipFg = const Color(0xFFC0392B);
        chipIcon = Icons.cancel_outlined;
        break;
      default:
        chipBg = const Color(0xFFFFF3E8);
        chipFg = const Color(0xFFB45309);
        chipIcon = Icons.hourglass_top_rounded;
    }

    String timeText = '—';
    if (dt != null) {
      String two(int v) => v.toString().padLeft(2, '0');
      timeText =
          '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.orange.withAlpha(12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$pointsCost pts · $timeText',
                    style: TextStyle(
                      color: AppTheme.ink.withAlpha(140),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chipIcon, size: 13, color: chipFg),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: TextStyle(
                      color: chipFg,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (ownerNote.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Text(
                ownerNote,
                style: TextStyle(
                  color: AppTheme.ink.withAlpha(150),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.ink, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.ink.withAlpha(140),
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.1,
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

class _AccessoryDoc {
  _AccessoryDoc({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.cashPriceText,
    required this.pointsCost,
    required this.imageUrl,
    required this.emoji,
    required this.iconKey,
    required this.category,
    required this.sortOrder,
    required this.stock,
    required this.isPublished,
    required this.isRedeemable,
    required this.colorHex,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String cashPriceText;
  final int pointsCost;
  final String imageUrl;
  final String emoji;
  final String iconKey;
  final String category;
  final int sortOrder;
  final int stock;
  final bool isPublished;
  final bool isRedeemable;
  final String colorHex;

  factory _AccessoryDoc.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    return _AccessoryDoc(
      id: doc.id,
      title: (d['title'] ?? 'Accessory').toString(),
      subtitle: (d['subtitle'] ?? '').toString(),
      description: (d['description'] ?? '').toString(),
      cashPriceText: (d['cashPriceText'] ?? d['priceText'] ?? '').toString(),
      pointsCost: _asInt(d['pointsCost']),
      imageUrl: (d['imageUrl'] ?? '').toString(),
      emoji: (d['emoji'] ?? '').toString(),
      iconKey: (d['iconKey'] ?? '').toString(),
      category: (d['category'] ?? '').toString(),
      sortOrder: _asInt(d['sortOrder']),
      stock: _asInt(d['stock']),
      isPublished: d['isPublished'] == true,
      isRedeemable: d['isRedeemable'] != false,
      colorHex: (d['colorHex'] ?? '').toString(),
    );
  }

  Color get fallbackColor {
    final c = _parseHexColor(colorHex);
    if (c != null) return c;
    return AppTheme.orange.withAlpha(10);
  }

  IconData get iconData => _iconFromKey(iconKey);
}

Color? _parseHexColor(String input) {
  final s = input.trim().replaceAll('#', '');
  if (s.length != 6 && s.length != 8) return null;
  final normalized = s.length == 6 ? 'FF$s' : s;
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return null;
  return Color(value);
}

IconData _iconFromKey(String key) {
  switch (key) {
    case 'collar':
      return Icons.pets_outlined;
    case 'leash':
      return Icons.linear_scale;
    case 'bowl':
      return Icons.ramen_dining_outlined;
    case 'toy':
      return Icons.sports_baseball_outlined;
    case 'bed':
      return Icons.bed_outlined;
    case 'carrier':
      return Icons.work_outline;
    case 'shampoo':
      return Icons.soap_outlined;
    case 'brush':
      return Icons.cleaning_services_outlined;
    default:
      return Icons.shopping_bag_outlined;
  }
}
