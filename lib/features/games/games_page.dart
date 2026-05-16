import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';
import '../../ui/premium_page_header.dart';
import '../../services/user_identity_service.dart';
import '../accessories/accessories_page.dart';
import '../home/create_post_sheet.dart';
import '../adopt_rescue/adopt_rescue_page.dart';
import '../map/map_models.dart';
import '../map/map_page.dart';
import '../map/pet_reports_page.dart';
import '../pet_babysitting/pet_babysitting_page.dart';
import '../vets/vets_page.dart';
import 'arcade/catch_the_treat_page.dart';
import 'arcade/pet_memory_page.dart';
import 'arcade/bubble_paws_page.dart';
import 'arcade/pet_quiz_page.dart';
import 'points_history_page.dart';
import 'points_runtime.dart';

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late final String? _uid;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _myClaimsStream;

  int _tabIndex = 0;

  static const List<_PointsMission> _missions = [
    _PointsMission(
      id: 'lost_pet_report',
      title: 'Report a missing pet',
      subtitle: 'Create or update a real lost/found report.',
      reward: 20,
      icon: Icons.manage_search_rounded,
      action: _MissionAction.lostFound,
      actionLabel: 'Continue',
      proofHint: '',
    ),
    _PointsMission(
      id: 'sitter_profile_action',
      title: 'Improve pet sitting trust',
      subtitle: 'Create a listing, complete a request, or leave a review.',
      reward: 30,
      icon: Icons.volunteer_activism_rounded,
      action: _MissionAction.petSitting,
      actionLabel: 'Continue',
      proofHint: '',
    ),
    _PointsMission(
      id: 'business_recommendation',
      title: 'Recommend a pet business',
      subtitle: 'Suggest a useful local pet place.',
      reward: 10,
      icon: Icons.storefront_rounded,
      action: _MissionAction.localServices,
      actionLabel: 'Continue',
      proofHint: '',
    ),
    _PointsMission(
      id: 'adoption_rescue_support',
      title: 'Support adoption or rescue',
      subtitle: 'Share helpful adoption or rescue info.',
      reward: 15,
      icon: Icons.pets_rounded,
      action: _MissionAction.adoptRescue,
      actionLabel: 'Continue',
      proofHint: '',
    ),
    _PointsMission(
      id: 'pet_care_tip',
      title: 'Share a pet care tip',
      subtitle: 'Post a useful care or safety tip.',
      reward: 5,
      icon: Icons.forum_rounded,
      action: _MissionAction.communityPost,
      actionLabel: 'Continue',
      proofHint: '',
    ),
  ];
  String get _todayKey {
    final now = DateTime.now();
    return _dateKey(now);
  }

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;

    if (_uid == null || _uid.isEmpty) {
      _userDocStream =
          const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
      _myClaimsStream =
          const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
      return;
    }

    _userDocStream = _db.collection('users').doc(_uid).snapshots();
    _myClaimsStream = _db
        .collection('game_claims')
        .where('uid', isEqualTo: _uid)
        .snapshots();
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

  _MissionClaimStatus _parseClaimStatus(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'approved':
        return _MissionClaimStatus.approved;
      case 'rejected':
      case 'declined':
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
      reviewNote: (d['reviewNote'] ?? d['ownerNote'] ?? '').toString().trim(),
      sortDate: _readDocDate(d),
    );
  }

  DateTime _readDocDate(Map<String, dynamic> d) {
    final v = d['updatedAt'] ?? d['createdAt'];
    if (v is Timestamp) return v.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _submitMissionClaim(_PointsMission mission) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null || uid.isEmpty) return;

    final identity = await UserIdentityService.instance.getForUid(
      uid,
      authUser: user,
    );
    final displayName = identity.safeName.trim();
    final email = identity.email.trim();
    final claimId = '${uid}_${_todayKey}_${mission.id}';
    final claimRef = _db.collection('game_claims').doc(claimId);

    try {
      await _db.runTransaction((tx) async {
        final existing = await tx.get(claimRef);
        if (existing.exists) {
          final d = existing.data() ?? <String, dynamic>{};
          final status = (d['status'] ?? 'pending').toString().toLowerCase();
          if (status == 'pending') {
            throw _ClaimException('This mission is already pending review.');
          }
          if (status == 'approved') {
            throw _ClaimException('This mission is already approved today.');
          }
          if (status == 'rejected' || status == 'declined') {
            throw _ClaimException('This mission was already reviewed today.');
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
          'source': 'games_page_v2',
          if (displayName.isNotEmpty) 'userDisplayName': displayName,
          if (email.isNotEmpty) 'userEmail': email,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+${mission.reward} pts sent for review')),
      );
    } on _ClaimException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit this claim. Please try again.'),
        ),
      );
    }
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

  void _openCatchTheTreat() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CatchTheTreatPage()));
  }

  void _openPetMemory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PetMemoryPage()));
  }

  void _openBubblePaws() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BubblePawsPage()));
  }

  void _openPetQuiz() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PetQuizPage()));
  }

  void _openMissionAction(_PointsMission mission) {
    switch (mission.action) {
      case _MissionAction.lostFound:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PetReportsPage()));
        break;
      case _MissionAction.petSitting:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PetBabysittingPage()));
        break;
      case _MissionAction.localServices:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const _LocalServicesPickerPage()),
        );
        break;
      case _MissionAction.adoptRescue:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AdoptRescuePage()));
        break;
      case _MissionAction.communityPost:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const CreatePostSheet(),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    final showAppBar = Navigator.of(context).canPop();

    if (uid == null || uid.isEmpty) {
      return _SignedOutGamesState(showAppBar: showAppBar);
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: showAppBar
          ? AppBar(
              title: const Text('PetTounsi Points'),
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
            stream: _myClaimsStream,
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
              final stats = _GameStats.fromClaims(allClaimDocs, todayDocs);
              final rankTitle = _rankTitleForPoints(points);
              final nextMilestone = _nextMilestone(points);
              final claimsByMission = <String, _MissionClaimView>{};
              final arcadePlayedToday = <String>{};

              for (final doc in todayDocs) {
                final data = doc.data();
                final missionId = (data['missionId'] ?? '').toString().trim();
                if (missionId.isEmpty) continue;
                final status = (data['status'] ?? '').toString().trim().toLowerCase();
                final source = (data['source'] ?? '').toString().trim();
                if (status == 'approved' &&
                    (source == 'arcade_game_v3_auto' || missionId.startsWith('arcade_'))) {
                  arcadePlayedToday.add(missionId.replaceFirst('arcade_', ''));
                }

                final nextView = _claimViewFromDoc(data);
                final previous = claimsByMission[missionId];
                if (previous == null ||
                    nextView.sortDate.isAfter(previous.sortDate)) {
                  claimsByMission[missionId] = nextView;
                }
              }

              final tabContent = switch (_tabIndex) {
                0 => _MissionsTab(
                  dateLabel: _friendlyDate(_todayKey),
                  missions: _missions,
                  claimsByMission: claimsByMission,
                  claimsUnavailable: claimsSnap.hasError,
                  onOpenMission: _openMissionAction,
                  onClaimMission: _submitMissionClaim,
                  onOpenCatchTheTreat: _openCatchTheTreat,
                  onOpenPetMemory: _openPetMemory,
                  onOpenBubblePaws: _openBubblePaws,
                  onOpenPetQuiz: _openPetQuiz,
                  arcadePlayedToday: arcadePlayedToday,
                ),
                1 => _RewardsTab(
                  points: points,
                  onOpenAccessories: _openAccessories,
                  onOpenHistory: _openPointsHistory,
                ),
                _ => _RankTab(myUid: uid, myPoints: points),
              };

              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 22),
                children: [
                  const _GamesMiniHeader(),
                  const SizedBox(height: 10),
                  _GamesSummaryCard(
                    points: points,
                    rankTitle: rankTitle,
                    progress: nextMilestone.progress,
                    progressSemanticLabel: nextMilestone.pointsLeft <= 0
                        ? 'Top rank'
                        : '${nextMilestone.pointsLeft} points to ${nextMilestone.label}',
                    stats: stats,
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
    return const Text(
      '     Official Points',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppTheme.ink,
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.45,
      ),
    );
  }
}

class _SignedOutGamesState extends StatelessWidget {
  const _SignedOutGamesState({required this.showAppBar});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: showAppBar
          ? AppBar(
              title: const Text('  Official Points'),
              backgroundColor: AppTheme.bg,
              foregroundColor: AppTheme.ink,
              elevation: 0,
            )
          : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppTheme.outline),
              boxShadow: AppTheme.softShadows(0.24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppTheme.blush,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: const Icon(
                    Icons.emoji_events_outlined,
                    color: AppTheme.orangeDark,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sign in to collect points',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Missions, rewards, and rank are linked to your PetTounsi account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
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

class _GamesSummaryCard extends StatelessWidget {
  const _GamesSummaryCard({
    required this.points,
    required this.rankTitle,
    required this.progress,
    required this.progressSemanticLabel,
    required this.stats,
    required this.onOpenHistory,
    required this.onOpenAccessories,
  });

  final int points;
  final String rankTitle;
  final double progress;
  final String progressSemanticLabel;
  final _GameStats stats;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenAccessories;

  @override
  Widget build(BuildContext context) {
    final statsSemantics =
        '${stats.pendingTotal} pending, ${stats.approvedTotal} approved, '
        '${stats.todayClaimed} claims today, ${stats.pendingTodayPoints} pending mission points';

    return Semantics(
      label: statsSemantics,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.outline),
          boxShadow: AppTheme.softShadows(0.12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.blush,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: AppTheme.outline),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppTheme.orangeDark,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$points pts',
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 29,
                      height: 1,
                      letterSpacing: -0.55,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rankTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Semantics(
                    label: progressSemanticLabel,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFF2EDF5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.orange,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetricChip(
                        icon: Icons.hourglass_bottom_rounded,
                        label: '${stats.pendingTotal} pending',
                        bg: const Color(0xFFFFF7E8),
                        fg: const Color(0xFFAA6A00),
                      ),
                      _MetricChip(
                        icon: Icons.verified_rounded,
                        label: '${stats.approvedTotal} approved',
                        bg: const Color(0xFFEAF8F0),
                        fg: const Color(0xFF1F8A4C),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                _IconAction(
                  icon: Icons.receipt_long_outlined,
                  tooltip: 'History',
                  onTap: onOpenHistory,
                ),
                const SizedBox(height: 8),
                _IconAction(
                  icon: Icons.redeem_rounded,
                  tooltip: 'Rewards',
                  onTap: onOpenAccessories,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayTab extends StatelessWidget {
  const _PlayTab({
    required this.onOpenCatchTheTreat,
    required this.onOpenPetMemory,
    required this.onOpenBubblePaws,
    required this.onOpenPetQuiz,
    required this.playedTodayGameIds,
  });

  final VoidCallback onOpenCatchTheTreat;
  final VoidCallback onOpenPetMemory;
  final VoidCallback onOpenBubblePaws;
  final VoidCallback onOpenPetQuiz;
  final Set<String> playedTodayGameIds;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Play',
      trailing: const _TinyBadge(label: 'Arcade'),
      child: Column(
        children: [
          _ArcadeGameTile(
            title: 'Catch the Treat',
            rewardLabel: '+1 point',
            playedToday: playedTodayGameIds.contains('catch_treat'),
            icon: Icons.cookie_rounded,
            colors: const [Color(0xFFFF8A67), Color(0xFFFFC47D)],
            onTap: onOpenCatchTheTreat,
          ),
          const SizedBox(height: 10),
          _ArcadeGameTile(
            title: 'Pet Memory',
            rewardLabel: '+1 point',
            playedToday: playedTodayGameIds.contains('pet_memory'),
            icon: Icons.grid_view_rounded,
            colors: const [Color(0xFF7C62D7), Color(0xFF8FD9FF)],
            onTap: onOpenPetMemory,
          ),
          const SizedBox(height: 10),
          _ArcadeGameTile(
            title: 'Paw Maze',
            rewardLabel: '+1 point',
            playedToday: playedTodayGameIds.contains('bubble_paws'),
            icon: Icons.travel_explore_rounded,
            colors: const [Color(0xFF2E7D5B), Color(0xFF9CCC65)],
            onTap: onOpenBubblePaws,
          ),
          const SizedBox(height: 10),
          _ArcadeGameTile(
            title: 'Pet Quiz',
            rewardLabel: '+1 point',
            playedToday: playedTodayGameIds.contains('pet_quiz'),
            icon: Icons.quiz_rounded,
            colors: const [Color(0xFF355C7D), Color(0xFFA6D8FF)],
            onTap: onOpenPetQuiz,
          ),
        ],
      ),
    );
  }
}

class _ArcadeGameTile extends StatelessWidget {
  const _ArcadeGameTile({
    required this.title,
    required this.rewardLabel,
    required this.playedToday,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String rewardLabel;
  final bool playedToday;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: playedToday
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This game already counted today. Come back tomorrow.')),
                )
            : onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          height: 138,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withAlpha(230)),
            boxShadow: AppTheme.softShadows(0.18),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                Positioned(
                  right: -22,
                  top: -22,
                  child: _ArcadeBubble(size: 96, opacity: 0.18),
                ),
                Positioned(
                  right: 50,
                  bottom: -32,
                  child: _ArcadeBubble(size: 82, opacity: 0.12),
                ),
                Positioned(
                  left: 18,
                  top: 18,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(235),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, color: colors.first, size: 30),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 86,
                  bottom: 18,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.35,
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(240),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      playedToday ? Icons.check_rounded : Icons.play_arrow_rounded,
                      color: colors.first,
                      size: 28,
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      playedToday ? 'Played today' : rewardLabel,
                      style: TextStyle(
                        color: colors.first,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.2,
                      ),
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

class _ArcadeBubble extends StatelessWidget {
  const _ArcadeBubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha((255 * opacity).round()),
      ),
    );
  }
}

class _MissionsTab extends StatelessWidget {
  const _MissionsTab({
    required this.dateLabel,
    required this.missions,
    required this.claimsByMission,
    required this.claimsUnavailable,
    required this.onOpenMission,
    required this.onClaimMission,
    required this.onOpenCatchTheTreat,
    required this.onOpenPetMemory,
    required this.onOpenBubblePaws,
    required this.onOpenPetQuiz,
    required this.arcadePlayedToday,
  });

  final String dateLabel;
  final List<_PointsMission> missions;
  final Map<String, _MissionClaimView> claimsByMission;
  final bool claimsUnavailable;
  final ValueChanged<_PointsMission> onOpenMission;
  final ValueChanged<_PointsMission> onClaimMission;
  final VoidCallback onOpenCatchTheTreat;
  final VoidCallback onOpenPetMemory;
  final VoidCallback onOpenBubblePaws;
  final VoidCallback onOpenPetQuiz;
  final Set<String> arcadePlayedToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('missions'),
      children: [
        _SectionCard(
          title: 'Missions',
          trailing: _TinyBadge(label: dateLabel),
          child: Column(
            children: [
              if (claimsUnavailable) ...[
                const _InfoBox(
                  icon: Icons.wifi_off_rounded,
                  message: 'Mission status could not refresh.',
                  tone: _InfoTone.warning,
                ),
                const SizedBox(height: 8),
              ],
              for (int i = 0; i < missions.length; i++) ...[
                _MissionTile(
                  mission: missions[i],
                  claimView:
                      claimsByMission[missions[i].id] ?? _MissionClaimView.none,
                  onOpen: () => onOpenMission(missions[i]),
                  onClaim: () => onClaimMission(missions[i]),
                ),
                if (i != missions.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PlayTab(
          onOpenCatchTheTreat: onOpenCatchTheTreat,
          onOpenPetMemory: onOpenPetMemory,
          onOpenBubblePaws: onOpenBubblePaws,
          onOpenPetQuiz: onOpenPetQuiz,
          playedTodayGameIds: arcadePlayedToday,
        ),
      ],
    );
  }
}

class _RewardsTab extends StatelessWidget {
  const _RewardsTab({
    required this.points,
    required this.onOpenAccessories,
    required this.onOpenHistory,
  });

  final int points;
  final VoidCallback onOpenAccessories;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('rewards'),
      children: [
        _RewardsWalletCard(
          points: points,
          onOpenAccessories: onOpenAccessories,
          onOpenHistory: onOpenHistory,
        ),
        const SizedBox(height: 12),
        _RewardsCard(points: points),
        const SizedBox(height: 12),
        const _PartnerRewardsPreviewCard(),
      ],
    );
  }
}

class _RankTab extends StatelessWidget {
  const _RankTab({required this.myUid, required this.myPoints});

  final String myUid;
  final int myPoints;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('rank'),
      children: [_LeaderboardCard(myUid: myUid, myPoints: myPoints)],
    );
  }
}

class _RewardsWalletCard extends StatelessWidget {
  const _RewardsWalletCard({
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final leading = Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.blush,
                  borderRadius: BorderRadius.circular(16),
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
                      'Reward wallet',
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$points official points available for approved rewards.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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

          final actions = Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 7,
            runSpacing: 7,
            children: [
              ElevatedButton.icon(
                onPressed: onOpenAccessories,
                icon: const Icon(Icons.redeem_rounded, size: 18),
                label: const Text('Open rewards'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
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

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: leading),
              const SizedBox(width: 10),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _PartnerRewardsPreviewCard extends StatelessWidget {
  const _PartnerRewardsPreviewCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Coming reward ideas',
      trailing: const _TinyBadge(label: 'V2.1'),
      child: Column(
        children: const [
          _PreviewRewardTile(
            icon: Icons.local_hospital_rounded,
            title: 'Vet checkup offers',
            subtitle: 'Discounts from trusted local clinics.',
          ),
          SizedBox(height: 9),
          _PreviewRewardTile(
            icon: Icons.storefront_rounded,
            title: 'Shop partner deals',
            subtitle: 'Food, grooming, and accessories.',
          ),
          SizedBox(height: 9),
          _PreviewRewardTile(
            icon: Icons.volunteer_activism_rounded,
            title: 'Rescue support rewards',
            subtitle: 'Support future rescue campaigns.',
          ),
        ],
      ),
    );
  }
}

class _PreviewRewardTile extends StatelessWidget {
  const _PreviewRewardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.mint,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Icon(icon, color: const Color(0xFF2F8F62), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.18,
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
            icon: Icons.leaderboard_rounded,
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
    final iconColor = selected ? Colors.white : AppTheme.orangeDark;

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
                      colors: [AppTheme.orange, AppTheme.orangeDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.4,
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
    required this.onOpen,
    required this.onClaim,
  });

  final _PointsMission mission;
  final _MissionClaimView claimView;
  final VoidCallback onOpen;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final status = claimView.status;
    final locked = status != _MissionClaimStatus.none;
    final colors = _missionColors(status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.tileBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.iconBg,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Icon(colors.icon, color: colors.iconColor, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink,
                        fontSize: 14.5,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      mission.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.muted,
                        fontSize: 12.2,
                        height: 1.22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TinyBadge(label: '+${mission.reward} pts'),
            ],
          ),
          const SizedBox(height: 11),
          Row(children: [_StatusChip.forStatus(status), const Spacer()]),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpen,
                  icon: Icon(
                    mission.action == _MissionAction.communityPost
                        ? Icons.edit_note_rounded
                        : Icons.open_in_new_rounded,
                    size: 17,
                  ),
                  label: Text(mission.actionLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.ink,
                    side: const BorderSide(color: AppTheme.outline),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: locked
                    ? _ClaimStateButton(status: status)
                    : _SmallClaimButton(onTap: onClaim),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _MissionVisuals _missionColors(_MissionClaimStatus status) {
    switch (status) {
      case _MissionClaimStatus.pending:
        return const _MissionVisuals(
          icon: Icons.hourglass_top_rounded,
          iconBg: Color(0xFFFFF5E6),
          iconColor: Color(0xFFD97706),
          tileBg: Color(0xFFFFFCF6),
          border: Color(0xFFFDE0B2),
        );
      case _MissionClaimStatus.approved:
        return const _MissionVisuals(
          icon: Icons.check_circle_rounded,
          iconBg: Color(0xFFEAFBF3),
          iconColor: Color(0xFF15803D),
          tileBg: Color(0xFFFCFFFD),
          border: Color(0xFFCBEBD7),
        );
      case _MissionClaimStatus.rejected:
        return const _MissionVisuals(
          icon: Icons.cancel_outlined,
          iconBg: Color(0xFFFFECEC),
          iconColor: Color(0xFFDC2626),
          tileBg: Color(0xFFFFFCFC),
          border: Color(0xFFFECACA),
        );
      case _MissionClaimStatus.none:
        return _MissionVisuals(
          icon: mission.icon,
          iconBg: AppTheme.butter,
          iconColor: const Color(0xFFC97A11),
          tileBg: Colors.white,
          border: AppTheme.outline,
        );
    }
  }
}

class _SmallClaimButton extends StatelessWidget {
  const _SmallClaimButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.orangeDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Claim points',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionVisuals {
  const _MissionVisuals({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.tileBg,
    required this.border,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color tileBg;
  final Color border;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.text,
    required this.fg,
    required this.bg,
    required this.border,
  });

  factory _StatusChip.forStatus(_MissionClaimStatus status) {
    switch (status) {
      case _MissionClaimStatus.pending:
        return const _StatusChip(
          text: 'Pending review',
          fg: Color(0xFFB45309),
          bg: Color(0xFFFFF7E8),
          border: Color(0xFFFDE0B2),
        );
      case _MissionClaimStatus.approved:
        return const _StatusChip(
          text: 'Approved',
          fg: Color(0xFF15803D),
          bg: Color(0xFFEFF8F2),
          border: Color(0xFFCBEBD7),
        );
      case _MissionClaimStatus.rejected:
        return const _StatusChip(
          text: 'Reviewed',
          fg: Color(0xFFB91C1C),
          bg: Color(0xFFFFEEEE),
          border: Color(0xFFFECACA),
        );
      case _MissionClaimStatus.none:
        return const _StatusChip(
          text: 'Available',
          fg: AppTheme.muted,
          bg: Color(0xFFF8F5FA),
          border: AppTheme.outline,
        );
    }
  }

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
        label = 'Reviewed';
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      alignment: Alignment.center,
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
      const _RewardTier(100, 'Starter Helper', Icons.pets_outlined),
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
      title: 'Community badges',
      trailing: _TinyBadge(label: '$unlockedCount/${rewards.length}'),
      child: Column(
        children: [
          for (int i = 0; i < rewards.length; i++) ...[
            _RewardTile(
              tier: rewards[i],
              unlocked: points >= rewards[i].points,
            ),
            if (i != rewards.length - 1) const SizedBox(height: 9),
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
      padding: const EdgeInsets.all(9),
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
          _TinyBadge(label: unlocked ? 'Unlocked' : 'Locked'),
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
      title: 'Community leaderboard',
      trailing: const _TinyBadge(label: 'Top 20'),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: claimsStream,
        builder: (context, claimsSnap) {
          if (claimsSnap.hasError) {
            return const _InfoBox(
              icon: Icons.info_outline_rounded,
              message: 'Could not load approved claims yet. Please try again.',
              tone: _InfoTone.warning,
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
            return const _InfoBox(
              icon: Icons.emoji_events_outlined,
              message:
                  'No approved points yet. Complete useful missions to appear here.',
              tone: _InfoTone.neutral,
            );
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: usersStream,
            builder: (context, usersSnap) {
              if (usersSnap.hasError) {
                return const _InfoBox(
                  icon: Icons.info_outline_rounded,
                  message:
                      'Could not load player details yet. Please try again.',
                  tone: _InfoTone.warning,
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
                    if (i != topEntries.length - 1) const SizedBox(height: 8),
                  ],
                ],
              );
            },
          );
        },
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
  return uid == myUid ? 'You' : 'Pettounsi member';
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

    final rankBg = switch (rank) {
      1 => const Color(0xFFFFF0C2),
      2 => const Color(0xFFEFEFEF),
      3 => const Color(0xFFFFE2C7),
      _ => const Color(0xFFF3ECE7),
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.blush : const Color(0xFFFFFEFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? AppTheme.orange.withAlpha(90) : AppTheme.outline,
        ),
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
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo.isEmpty
                ? Text(
                    displayName.isEmpty ? 'P' : displayName[0].toUpperCase(),
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
                  const _TinyBadge(label: 'You'),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$shownPoints pts',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13.4,
              color: AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalServicesPickerPage extends StatelessWidget {
  const _LocalServicesPickerPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Local pet services')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          const PremiumPageHeader(
            icon: Icons.storefront_rounded,
            iconColor: AppTheme.orangeDark,
            title: 'Find useful places',
            subtitle: 'Open a local service before submitting this mission.',
            badgeLabel: 'Service tip',
          ),
          const SizedBox(height: 12),
          _ServiceActionTile(
            icon: Icons.local_hospital_rounded,
            title: 'Vets',
            subtitle: 'Browse clinics and animal doctors.',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const VetsPage())),
          ),
          const SizedBox(height: 10),
          _ServiceActionTile(
            icon: Icons.map_rounded,
            title: 'Map discovery',
            subtitle: 'Open vets, shops, events, and reports.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MapPage(
                  initialFilter: MapPinType.petshop,
                  standalone: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceActionTile extends StatelessWidget {
  const _ServiceActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.outline),
            boxShadow: AppTheme.softShadows(0.12),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.blush,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Icon(icon, color: AppTheme.orangeDark),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.message,
    required this.tone,
  });

  final IconData icon;
  final String message;
  final _InfoTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _InfoTone.warning => (
        const Color(0xFFFFF6E9),
        const Color(0xFFB45309),
        const Color(0xFFFFE1B2),
      ),
      _InfoTone.neutral => (
        const Color(0xFFF8F6FB),
        AppTheme.ink.withAlpha(160),
        AppTheme.outline,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.$3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.$2),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppTheme.ink.withAlpha(165),
                fontWeight: FontWeight.w800,
                fontSize: 12.2,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppTheme.ink.withAlpha(190),
          fontWeight: FontWeight.w900,
          fontSize: 11.2,
          height: 1,
        ),
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

enum _InfoTone { warning, neutral }

enum _MissionClaimStatus { none, pending, approved, rejected }

enum _MissionAction {
  lostFound,
  petSitting,
  localServices,
  adoptRescue,
  communityPost,
}

class _MissionClaimView {
  const _MissionClaimView({
    required this.status,
    required this.reviewNote,
    required this.sortDate,
  });

  final _MissionClaimStatus status;
  final String reviewNote;
  final DateTime sortDate;

  static final none = _MissionClaimView(
    status: _MissionClaimStatus.none,
    reviewNote: '',
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
    required this.action,
    required this.actionLabel,
    required this.proofHint,
  });

  final String id;
  final String title;
  final String subtitle;
  final int reward;
  final IconData icon;
  final _MissionAction action;
  final String actionLabel;
  final String proofHint;
}

class _RewardTier {
  const _RewardTier(this.points, this.label, this.icon);

  final int points;
  final String label;
  final IconData icon;
}

class _GameStats {
  const _GameStats({
    required this.pendingTotal,
    required this.approvedTotal,
    required this.todayClaimed,
    required this.pendingTodayPoints,
  });

  final int pendingTotal;
  final int approvedTotal;
  final int todayClaimed;
  final int pendingTodayPoints;

  factory _GameStats.fromClaims(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> todayDocs,
  ) {
    var pendingTotal = 0;
    var approvedTotal = 0;
    var pendingTodayPoints = 0;

    for (final doc in allDocs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().trim().toLowerCase();
      if (status == 'pending') pendingTotal++;
      if (status == 'approved') approvedTotal++;
    }

    for (final doc in todayDocs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().trim().toLowerCase();
      if (status == 'pending') {
        final reward = data['missionReward'];
        if (reward is num) pendingTodayPoints += reward.toInt();
      }
    }

    return _GameStats(
      pendingTotal: pendingTotal,
      approvedTotal: approvedTotal,
      todayClaimed: todayDocs.length,
      pendingTodayPoints: pendingTodayPoints,
    );
  }
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
