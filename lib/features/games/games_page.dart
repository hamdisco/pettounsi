import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../ui/premium_page_header.dart';
import '../../ui/app_theme.dart';
import '../accessories/accessories_page.dart';
import 'points_history_page.dart';
import 'points_runtime.dart';

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  late final String? _uid;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _allClaimsStream;

  static final List<_PointsMission> _missions = [
    _PointsMission(
      id: 'post_report',
      title: 'Post a street pet report',
      subtitle: 'Share a lost/found report or helpful post',
      reward: 15,
      icon: Icons.campaign_outlined,
    ),
    _PointsMission(
      id: 'map_help',
      title: 'Add a map location',
      subtitle: 'Pin a vet, petshop, or event location',
      reward: 10,
      icon: Icons.add_location_alt_outlined,
    ),
    _PointsMission(
      id: 'babysitting_help',
      title: 'Help with babysitting request',
      subtitle: 'Accept or complete one babysitting request',
      reward: 30,
      icon: Icons.volunteer_activism_outlined,
    ),
    _PointsMission(
      id: 'helpful_comment',
      title: 'Comment helpful advice',
      subtitle: 'Leave a useful comment for the community',
      reward: 5,
      icon: Icons.chat_bubble_outline,
    ),
  ];

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;

    if (_uid == null || _uid.isEmpty) {
      _userDocStream =
          const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
      _allClaimsStream =
          const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
      return;
    }

    _userDocStream = _db.collection('users').doc(_uid).snapshots();
    _allClaimsStream = _db
        .collection('game_claims')
        .where('uid', isEqualTo: _uid)
        .snapshots();
  }

  int _tabIndex = 0;
  String get _todayKey {
    final now = DateTime.now();
    return _dateKey(now);
  }

  String _dateKey(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
  }

  String _friendlyDate(String key) {
    try {
      final p = key.split('-');
      if (p.length != 3) return key;
      final y = int.parse(p[0]);
      final m = int.parse(p[1]);
      final d = int.parse(p[2]);
      final dt = DateTime(y, m, d);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month - 1]} $d, $y';
    } catch (_) {
      return key;
    }
  }

  String _rankTitleForPoints(int points) {
    if (points >= 1500) return 'Legend Rescuer';
    if (points >= 800) return 'Community Hero';
    if (points >= 350) return 'Trusted Helper';
    if (points >= 120) return 'Active Friend';
    return 'New Helper';
  }

  Future<void> _submitMissionClaim(_PointsMission mission) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null || uid.isEmpty) return;

    final displayName = (user?.displayName ?? '').trim();

    final claimId = '${uid}_${_todayKey}_${mission.id}';
    final claimRef = _db.collection('game_claims').doc(claimId);

    try {
      await _db.runTransaction((tx) async {
        final existing = await tx.get(claimRef);
        if (existing.exists) {
          final d = existing.data() ?? <String, dynamic>{};
          final status = (d['status'] ?? 'pending').toString();
          if (status == 'pending') {
            throw _ClaimException(
              'Mission claim already submitted and pending review.',
            );
          }
          if (status == 'approved') {
            throw _ClaimException('Mission already approved today.');
          }
          if (status == 'rejected') {
            throw _ClaimException(
              'This mission claim was rejected today. Please contact support if this is a mistake.',
            );
          }
          throw _ClaimException('Mission already claimed today.');
        }

        tx.set(claimRef, {
          'uid': uid,
          'dayKey': _todayKey,
          'missionId': mission.id,
          'missionTitle': mission.title,
          'missionReward': mission.reward,
          'status': 'pending',
          'source': 'games_page',
          if (displayName.isNotEmpty) 'userDisplayName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Claim sent for review (${mission.reward} pts pending approval)',
          ),
        ),
      );
    } on _ClaimException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not submit claim: $e')));
    }
  }

  _MissionClaimStatus _parseClaimStatus(String raw) {
    switch (raw) {
      case 'approved':
        return _MissionClaimStatus.approved;
      case 'rejected':
        return _MissionClaimStatus.rejected;
      case 'pending':
        return _MissionClaimStatus.pending;
      default:
        return _MissionClaimStatus.none;
    }
  }

  _MissionClaimView _claimViewFromDoc(Map<String, dynamic>? data) {
    final d = data ?? const <String, dynamic>{};
    return _MissionClaimView(
      status: _parseClaimStatus((d['status'] ?? '').toString()),
      reviewNote: (d['reviewNote'] ?? '').toString().trim(),
      reviewedBy: (d['reviewedBy'] ?? '').toString().trim(),
      sortDate: _readDocDate(d),
    );
  }

  DateTime _readDocDate(Map<String, dynamic> d) {
    final v = d['updatedAt'] ?? d['createdAt'];
    if (v is Timestamp) return v.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _openAccessories() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AccessoriesPage()));
  }

  void _openPointsHistory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PointsHistoryPage()));
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    final bool showAppBar = Navigator.of(context).canPop();

    if (uid == null || uid.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: showAppBar
            ? AppBar(
                title: const Text('Games'),
                backgroundColor: AppTheme.bg,
                foregroundColor: AppTheme.ink,
                elevation: 0,
              )
            : null,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.orange.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events_outlined, size: 34),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sign in to use points',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your missions, rewards, and leaderboard rank are linked to your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.ink.withAlpha(150)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: showAppBar
          ? AppBar(
              title: const Text('Games'),
              backgroundColor: AppTheme.bg,
              foregroundColor: AppTheme.ink,
              elevation: 0,
            )
          : null,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userDocStream,
        builder: (context, userSnap) {
          final userData = userSnap.data?.data() ?? <String, dynamic>{};
          final syncedPoints = (userData['pointsBalance'] is num)
              ? (userData['pointsBalance'] as num).toInt()
              : 0;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _allClaimsStream,
            builder: (context, claimsSnap) {
              final allClaimDocs =
                  claimsSnap.data?.docs ??
                  const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              final todayDocs = allClaimDocs
                  .where(
                    (doc) =>
                        (doc.data()['dayKey'] ?? '').toString() == _todayKey,
                  )
                  .toList();

              final points = officialPointsFromData(
                syncedPoints: syncedPoints,
                claimDocs: allClaimDocs,
              );
              final nextMilestone = _nextMilestone(points);
              final rankTitle = _rankTitleForPoints(points);

              final claimsByMission = <String, _MissionClaimView>{};

              for (final doc in todayDocs) {
                final d = doc.data();
                final missionId = (d['missionId'] ?? '').toString().trim();
                if (missionId.isEmpty) continue;

                final nextView = _claimViewFromDoc(d);
                final prev = claimsByMission[missionId];
                if (prev == null || nextView.sortDate.isAfter(prev.sortDate)) {
                  claimsByMission[missionId] = nextView;
                }
              }

              final pendingTodayPoints = () {
                var sum = 0;
                for (final doc in todayDocs) {
                  final d = doc.data();
                  if ((d['status'] ?? '').toString().toLowerCase() ==
                      'pending') {
                    final r = d['missionReward'];
                    if (r is num) sum += r.toInt();
                  }
                }
                return sum;
              }();

              Widget tabContent;
              if (_tabIndex == 0) {
                tabContent = Column(
                  key: const ValueKey('missions'),
                  children: [
                    _SectionCard(
                      title: 'Daily missions',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lilac,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        child: Text(
                          _friendlyDate(_todayKey),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (claimsSnap.hasError)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF6E9),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFFFE1B2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: Color(0xFFB45309),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Claim history is temporarily unavailable. Please try again later.',
                                      style: TextStyle(
                                        color: AppTheme.ink.withAlpha(160),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          for (int i = 0; i < _missions.length; i++) ...[
                            _MissionTile(
                              mission: _missions[i],
                              claimView:
                                  claimsByMission[_missions[i].id] ??
                                  _MissionClaimView.none,
                              onClaim: () => _submitMissionClaim(_missions[i]),
                            ),
                            if (i != _missions.length - 1)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Divider(
                                  color: Colors.black.withAlpha(18),
                                ),
                              ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F6FB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.outline),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: AppTheme.ink.withAlpha(160),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Approved mission points are added to your official balance after review.',
                                    style: TextStyle(
                                      color: AppTheme.ink.withAlpha(145),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.2,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else if (_tabIndex == 1) {
                tabContent = Column(
                  key: const ValueKey('rewards'),
                  children: [
                    _AccessoriesOnlyCard(
                      points: points,
                      onOpenAccessories: _openAccessories,
                      onOpenHistory: _openPointsHistory,
                    ),
                    const SizedBox(height: 12),
                    _RewardsCard(points: points),
                  ],
                );
              } else {
                tabContent = Column(
                  key: const ValueKey('rank'),
                  children: [_LeaderboardCard(myUid: uid, myPoints: points)],
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                children: [
                  const _GamesMiniHeader(),
                  const SizedBox(height: 10),
                  _GamesSummaryCard(
                    points: points,
                    rankTitle: rankTitle,
                    progressToNext: nextMilestone.progress,
                    nextLabel: nextMilestone.label,
                    pointsToNext: nextMilestone.pointsLeft,
                    pendingTodayPoints: pendingTodayPoints,
                    onOpenHistory: _openPointsHistory,
                    onOpenAccessories: _openAccessories,
                  ),
                  const SizedBox(height: 10),
                  _GamesTabs(
                    index: _tabIndex,
                    onChanged: (i) => setState(() => _tabIndex = i),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: tabContent,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _GamesMiniHeader extends StatelessWidget {
  const _GamesMiniHeader();

  @override
  Widget build(BuildContext context) {
    return const PremiumPageHeader(
      icon: Icons.sports_esports_rounded,
      iconColor: Color(0xFF7C62D7),
      title: 'Games',
      subtitle: 'Complete missions and unlock community rewards.',
      badgeLabel: 'Official points',
      chips: [
        PremiumHeaderChip(
          icon: Icons.task_alt_rounded,
          label: 'Missions',
          bg: AppTheme.lilac,
          fg: Color(0xFF6B56C9),
        ),
        PremiumHeaderChip(
          icon: Icons.card_giftcard_rounded,
          label: 'Rewards',
          bg: AppTheme.blush,
          fg: AppTheme.orangeDark,
        ),
        PremiumHeaderChip(
          icon: Icons.bar_chart_rounded,
          label: 'Rank',
          bg: AppTheme.sky,
          fg: Color(0xFF4C79C8),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(210),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.ink.withAlpha(170)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.ink.withAlpha(180),
              fontWeight: FontWeight.w900,
              fontSize: 11.8,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessoriesOnlyCard extends StatelessWidget {
  const _AccessoriesOnlyCard({
    required this.points,
    required this.onOpenAccessories,
    required this.onOpenHistory,
  });

  final int points;
  final VoidCallback onOpenAccessories;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.45),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final actions = Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              ElevatedButton.icon(
                onPressed: onOpenAccessories,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Open'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  minimumSize: const Size(0, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onOpenHistory,
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('History'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.orangeDark,
                  backgroundColor: const Color(0xFFFFF3EE),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppTheme.outline),
                  ),
                ),
              ),
            ],
          );

          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _walletLeading(points),
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _walletLeading(points)),
                    const SizedBox(width: 8),
                    actions,
                  ],
                );
        },
      ),
    );
  }

  Widget _walletLeading(int points) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.blush,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppTheme.outline),
          ),
          child: const Icon(
            Icons.wallet_giftcard_rounded,
            color: AppTheme.orangeDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rewards',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$points official pts · browse rewards',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _GamesTitleRow extends StatelessWidget {
  const _GamesTitleRow({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.blush,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.outline),
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            size: 18,
            color: AppTheme.orangeDark,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Games',
          style: TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.outline),
            boxShadow: AppTheme.softShadows(0.18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 16,
                color: AppTheme.orangeDark,
              ),
              const SizedBox(width: 6),
              Text(
                '$points pts',
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GamesSummaryCard extends StatelessWidget {
  const _GamesSummaryCard({
    required this.points,
    required this.rankTitle,
    required this.progressToNext,
    required this.nextLabel,
    required this.pointsToNext,
    required this.pendingTodayPoints,
    required this.onOpenHistory,
    required this.onOpenAccessories,
  });

  final int points;
  final String rankTitle;
  final double progressToNext;
  final String nextLabel;
  final int pointsToNext;
  final int pendingTodayPoints;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenAccessories;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (pendingTodayPoints > 0) {
      chips.add(
        _PillChip(
          icon: Icons.hourglass_top_rounded,
          label: '+$pendingTodayPoints pending review',
          bg: const Color(0xFFFFF6E6),
          fg: const Color(0xFFB66B12),
          border: const Color(0xFFF7DEB6),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF3EE), Color(0xFFFFFBFD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFB79E), AppTheme.orange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Official points',
                              style: TextStyle(
                                color: AppTheme.ink.withAlpha(155),
                                fontWeight: FontWeight.w800,
                                fontSize: 12.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$points pts',
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 30,
                                height: 1,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppTheme.outline),
                              ),
                              child: Text(
                                rankTitle,
                                style: TextStyle(
                                  color: AppTheme.ink.withAlpha(210),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11.6,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  _IconAction(
                    icon: Icons.receipt_long_outlined,
                    tooltip: 'History',
                    onTap: onOpenHistory,
                  ),
                  const SizedBox(height: 8),
                  _IconAction(
                    icon: Icons.redeem_outlined,
                    tooltip: 'Accessories',
                    onTap: onOpenAccessories,
                  ),
                ],
              ),
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBFD),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      size: 18,
                      color: AppTheme.orangeDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pointsToNext <= 0 ? 'Top rank reached' : 'Next milestone',
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EAF6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progressToNext.clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.orange, AppTheme.orangeDark],
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  pointsToNext <= 0
                      ? 'You already reached the highest current rank.'
                      : '$pointsToNext points to $nextLabel',
                  style: TextStyle(
                    color: AppTheme.ink.withAlpha(160),
                    fontWeight: FontWeight.w800,
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

class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFFFFBFD),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Icon(icon, color: AppTheme.orangeDark, size: 21),
          ),
        ),
      ),
    );
  }
}

class _GamesTabs extends StatelessWidget {
  const _GamesTabs({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppTheme.mist,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.10),
      ),
      child: Row(
        children: [
          _GamesTabItem(
            selected: index == 0,
            icon: Icons.task_alt_rounded,
            label: 'Missions',
            onTap: () => onChanged(0),
          ),
          _GamesTabItem(
            selected: index == 1,
            icon: Icons.card_giftcard_rounded,
            label: 'Rewards',
            onTap: () => onChanged(1),
          ),
          _GamesTabItem(
            selected: index == 2,
            icon: Icons.bar_chart_rounded,
            label: 'Rank',
            onTap: () => onChanged(2),
          ),
        ],
      ),
    );
  }
}

class _GamesTabItem extends StatelessWidget {
  const _GamesTabItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? Colors.white : AppTheme.ink.withAlpha(180);
    final iconColor = selected ? Colors.white : AppTheme.orchidDark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              gradient: selected
                  ? const LinearGradient(
                      colors: [AppTheme.orchidDark, AppTheme.roseDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: selected ? null : Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.2,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _PendingApprovedCreditsCard extends StatelessWidget {
  const _PendingApprovedCreditsCard({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2DEC1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF2DEC1)),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: AppTheme.orangeDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$points approved points are already included in your official total.',
              style: TextStyle(
                color: AppTheme.ink.withAlpha(185),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _PointsHeroCard extends StatelessWidget {
  const _PointsHeroCard({
    required this.points,
    required this.rankTitle,
    required this.progressToNext,
    required this.nextLabel,
    required this.pointsToNext,
  });

  final int points;
  final String rankTitle;
  final double progressToNext;
  final String nextLabel;
  final int pointsToNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFDED5), Color(0xFFFFEAE2), Color(0xFFF2ECFF)],
        ),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.65),
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
                  color: Colors.white.withAlpha(220),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.outline),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppTheme.orangeDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wallet Points',
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$points',
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 30,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(210),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: AppTheme.orangeDark,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Daily',
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(180),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rankTitle,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.lilac,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progressToNext.clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.orange, Color(0xFFFFBAA4)],
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  pointsToNext <= 0
                      ? 'Top rank reached 🎉'
                      : '$pointsToNext points to $nextLabel',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15.2,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({
    required this.mission,
    required this.claimView,
    required this.onClaim,
  });

  final _PointsMission mission;
  final _MissionClaimView claimView;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final status = claimView.status;
    final locked = status != _MissionClaimStatus.none;

    IconData icon = mission.icon;
    Color iconBg = AppTheme.butter;
    Color iconColor = const Color(0xFFC97A11);
    Color tileBg = const Color(0xFFFFFEFF);

    switch (status) {
      case _MissionClaimStatus.pending:
        icon = Icons.hourglass_top_rounded;
        iconBg = const Color(0xFFFFF5E6);
        iconColor = const Color(0xFFD97706);
        tileBg = const Color(0xFFFFFCF6);
        break;
      case _MissionClaimStatus.approved:
        icon = Icons.check_circle;
        iconBg = const Color(0xFFEAFBF3);
        iconColor = const Color(0xFF1F9D55);
        tileBg = const Color(0xFFFCFFFD);
        break;
      case _MissionClaimStatus.rejected:
        icon = Icons.cancel_outlined;
        iconBg = const Color(0xFFFFECEC);
        iconColor = const Color(0xFFDC2626);
        tileBg = const Color(0xFFFFFCFC);
        break;
      case _MissionClaimStatus.none:
        break;
    }

    final action = locked
        ? _ClaimStateButton(status: status)
        : ElevatedButton(
            onPressed: onClaim,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: const Size(0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Claim'),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 325;

        final content = Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mission.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                mission.subtitle,
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              if (claimView.reviewNote.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: status == _MissionClaimStatus.rejected
                        ? const Color(0xFFFFF1F1)
                        : const Color(0xFFF8F6FB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: status == _MissionClaimStatus.rejected
                          ? const Color(0xFFFECACA)
                          : AppTheme.outline,
                    ),
                  ),
                  child: Text(
                    claimView.reviewNote,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.6,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.blush,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: Text(
                      '+${mission.reward} points',
                      style: const TextStyle(
                        color: AppTheme.orangeDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  if (status == _MissionClaimStatus.pending)
                    const _StatusChip(
                      text: 'Pending review',
                      fg: Color(0xFFB45309),
                      bg: Color(0xFFFFF7E8),
                      border: Color(0xFFFDE0B2),
                    ),
                  if (status == _MissionClaimStatus.approved)
                    const _StatusChip(
                      text: 'Approved',
                      fg: Color(0xFF15803D),
                      bg: Color(0xFFEFF8F2),
                      border: Color(0xFFCBEBD7),
                    ),
                  if (status == _MissionClaimStatus.rejected)
                    const _StatusChip(
                      text: 'Rejected',
                      fg: Color(0xFFB91C1C),
                      bg: Color(0xFFFFEEEE),
                      border: Color(0xFFFECACA),
                    ),
                ],
              ),
            ],
          ),
        );

        final leading = Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Icon(icon, color: iconColor, size: 21),
        );

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outline),
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [leading, const SizedBox(width: 10), content],
                    ),
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: action),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leading,
                    const SizedBox(width: 10),
                    content,
                    const SizedBox(width: 8),
                    action,
                  ],
                ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.text,
    required this.fg,
    required this.bg,
    required this.border,
  });

  final String text;
  final Color fg;
  final Color bg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 11.3,
        ),
      ),
    );
  }
}

class _ClaimStateButton extends StatelessWidget {
  const _ClaimStateButton({required this.status});

  final _MissionClaimStatus status;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color fg;
    late final Color bg;
    late final Color border;

    switch (status) {
      case _MissionClaimStatus.pending:
        label = 'Pending';
        fg = const Color(0xFFB45309);
        bg = const Color(0xFFFFF7E8);
        border = const Color(0xFFFDE0B2);
        break;
      case _MissionClaimStatus.approved:
        label = 'Approved';
        fg = const Color(0xFF15803D);
        bg = const Color(0xFFEFF8F2);
        border = const Color(0xFFCBEBD7);
        break;
      case _MissionClaimStatus.rejected:
        label = 'Rejected';
        fg = const Color(0xFFB91C1C);
        bg = const Color(0xFFFFEEEE);
        border = const Color(0xFFFECACA);
        break;
      case _MissionClaimStatus.none:
        label = 'Claim';
        fg = AppTheme.orangeDark;
        bg = AppTheme.blush;
        border = AppTheme.outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final rewards = <_RewardTier>[
      const _RewardTier(100, 'Starter Badge', Icons.pets_outlined),
      const _RewardTier(300, 'Trusted Helper', Icons.favorite_outline),
      const _RewardTier(700, 'Rescue Star', Icons.star_outline),
      const _RewardTier(
        1200,
        'Community Hero',
        Icons.workspace_premium_outlined,
      ),
    ];

    final unlockedCount = rewards.where((r) => points >= r.points).length;

    return _SectionCard(
      title: 'Rewards & Badges',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.lilac,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Text(
          '$unlockedCount/${rewards.length}',
          style: const TextStyle(
            color: AppTheme.muted,
            fontWeight: FontWeight.w900,
            fontSize: 11.5,
          ),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rewards.length; i++) ...[
            _RewardTile(
              tier: rewards[i],
              unlocked: points >= rewards[i].points,
            ),
            if (i != rewards.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Colors.black.withAlpha(14)),
              ),
          ],
        ],
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.tier, required this.unlocked});

  final _RewardTier tier;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFFFFFEFF) : const Color(0xFFFCFBFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: unlocked ? AppTheme.blush : const Color(0xFFF4F2F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Icon(
              tier.icon,
              color: unlocked
                  ? AppTheme.orangeDark
                  : AppTheme.muted.withAlpha(120),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: unlocked ? AppTheme.ink : AppTheme.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tier.points} points',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: unlocked
                  ? const Color(0xFFEAFBF3)
                  : const Color(0xFFF4F2F7),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: unlocked ? const Color(0xFFCBEBD7) : AppTheme.outline,
              ),
            ),
            child: Text(
              unlocked ? 'Unlocked' : 'Locked',
              style: TextStyle(
                color: unlocked ? const Color(0xFF15803D) : AppTheme.muted,
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.myUid, required this.myPoints});

  final String myUid;
  final int myPoints;

  @override
  Widget build(BuildContext context) {
    final claimsStream = FirebaseFirestore.instance
        .collection('game_claims')
        .where('status', isEqualTo: 'approved')
        .snapshots();

    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .snapshots();

    return _SectionCard(
      title: 'Leaderboard',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.sky,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.outline),
        ),
        child: const Text(
          'Top 20',
          style: TextStyle(
            color: AppTheme.muted,
            fontWeight: FontWeight.w900,
            fontSize: 11.2,
          ),
        ),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: claimsStream,
        builder: (context, claimsSnap) {
          if (claimsSnap.hasError) {
            return const _LeaderboardErrorBox(
              message: 'Could not load approved claims yet. Please try again.',
            );
          }

          if (!claimsSnap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final totals = <String, int>{};
          for (final doc in claimsSnap.data!.docs) {
            final data = doc.data();
            final uid = (data['uid'] ?? '').toString().trim();
            if (uid.isEmpty) continue;
            final reward = (data['missionReward'] is num)
                ? (data['missionReward'] as num).toInt()
                : 0;
            if (reward <= 0) continue;
            totals[uid] = (totals[uid] ?? 0) + reward;
          }

          final ranked = totals.entries.where((e) => e.value > 0).toList();
          if (ranked.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F4F0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Text(
                'No approved points yet.',
                style: TextStyle(
                  color: AppTheme.ink.withAlpha(150),
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: usersStream,
            builder: (context, usersSnap) {
              if (usersSnap.hasError) {
                return const _LeaderboardErrorBox(
                  message:
                      'Could not load player details yet. Please try again.',
                );
              }

              final usersByUid = <String, Map<String, dynamic>>{};
              for (final doc
                  in usersSnap.data?.docs ??
                      const <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
                usersByUid[doc.id] = doc.data();
              }

              ranked.sort((a, b) {
                final byPoints = b.value.compareTo(a.value);
                if (byPoints != 0) return byPoints;
                final aName = _leaderboardDisplayName(
                  usersByUid[a.key],
                  a.key,
                  myUid,
                ).toLowerCase();
                final bName = _leaderboardDisplayName(
                  usersByUid[b.key],
                  b.key,
                  myUid,
                ).toLowerCase();
                return aName.compareTo(bName);
              });

              final topEntries = ranked.take(20).toList();

              return Column(
                children: [
                  for (int i = 0; i < topEntries.length; i++) ...[
                    _LeaderboardRow(
                      rank: i + 1,
                      myUid: myUid,
                      uid: topEntries[i].key,
                      points: topEntries[i].value,
                      userData: usersByUid[topEntries[i].key],
                      myPoints: myPoints,
                    ),
                    if (i != topEntries.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: Colors.black.withAlpha(14)),
                      ),
                  ],
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rank updates from approved mission claims.',
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.6,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _LeaderboardErrorBox extends StatelessWidget {
  const _LeaderboardErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD9D9)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: AppTheme.ink.withAlpha(150),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _leaderboardDisplayName(
  Map<String, dynamic>? data,
  String uid,
  String myUid,
) {
  final d = data ?? const <String, dynamic>{};
  final displayName = (d['displayName'] ?? '').toString().trim();
  if (displayName.isNotEmpty) return displayName;
  final username = (d['username'] ?? '').toString().trim();
  if (username.isNotEmpty) return username;
  return uid == myUid ? 'You' : 'User';
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.myUid,
    required this.uid,
    required this.points,
    required this.userData,
    required this.myPoints,
  });

  final int rank;
  final String myUid;
  final String uid;
  final int points;
  final Map<String, dynamic>? userData;
  final int myPoints;

  @override
  Widget build(BuildContext context) {
    final d = userData ?? const <String, dynamic>{};
    final displayName = _leaderboardDisplayName(d, uid, myUid);
    final photo = (d['photoUrl'] ?? d['photoURL'] ?? '').toString();
    final isMe = uid == myUid;
    final shownPoints = isMe ? myPoints : points;

    Color rankBg;
    if (rank == 1) {
      rankBg = const Color(0xFFFFF0C2);
    } else if (rank == 2) {
      rankBg = const Color(0xFFEFEFEF);
    } else if (rank == 3) {
      rankBg = const Color(0xFFFFE2C7);
    } else {
      rankBg = const Color(0xFFF3ECE7);
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.blush : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isMe ? Border.all(color: AppTheme.outline) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.lilac,
            backgroundImage: (photo.isNotEmpty) ? NetworkImage(photo) : null,
            child: (photo.isEmpty)
                ? Text(
                    displayName.isEmpty ? 'U' : displayName[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.ink,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.softOrange,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: const Text(
                      'You',
                      style: TextStyle(
                        color: AppTheme.orangeDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 10.8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$shownPoints',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _MissionClaimStatus { none, pending, approved, rejected }

class _MissionClaimView {
  const _MissionClaimView({
    required this.status,
    required this.reviewNote,
    required this.reviewedBy,
    required this.sortDate,
  });

  final _MissionClaimStatus status;
  final String reviewNote;
  final String reviewedBy;
  final DateTime sortDate;

  static final none = _MissionClaimView(
    status: _MissionClaimStatus.none,
    reviewNote: '',
    reviewedBy: '',
    sortDate: DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class _PointsMission {
  const _PointsMission({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final int reward;
  final IconData icon;
}

class _RewardTier {
  const _RewardTier(this.points, this.label, this.icon);

  final int points;
  final String label;
  final IconData icon;
}

class _MilestoneProgress {
  const _MilestoneProgress({
    required this.progress,
    required this.label,
    required this.pointsLeft,
  });

  final double progress;
  final String label;
  final int pointsLeft;
}

_MilestoneProgress _nextMilestone(int points) {
  const thresholds = <_MilestoneThreshold>[
    _MilestoneThreshold(120, 'Active Friend'),
    _MilestoneThreshold(350, 'Trusted Helper'),
    _MilestoneThreshold(800, 'Community Hero'),
    _MilestoneThreshold(1500, 'Legend Rescuer'),
  ];

  var previous = 0;
  for (final t in thresholds) {
    if (points < t.target) {
      final span = (t.target - previous).clamp(1, 1 << 30);
      final progressed = (points - previous).clamp(0, span);
      return _MilestoneProgress(
        progress: progressed / span,
        label: t.label,
        pointsLeft: t.target - points,
      );
    }
    previous = t.target;
  }

  return const _MilestoneProgress(
    progress: 1,
    label: 'Top rank',
    pointsLeft: 0,
  );
}

class _MilestoneThreshold {
  const _MilestoneThreshold(this.target, this.label);
  final int target;
  final String label;
}

class _ClaimException implements Exception {
  _ClaimException(this.message);
  final String message;
}
