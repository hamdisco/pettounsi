import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../repositories/block_repository.dart';
import '../../repositories/follow_repository.dart';
import '../../services/user_mini_cache.dart';
import '../../ui/app_theme.dart';
import '../../ui/user_avatar.dart';
import '../adopt_rescue/adopt_rescue_page.dart';
import '../map/pet_reports_page.dart';
import '../pet_babysitting/pet_babysitting_page.dart';
import '../vets/vets_page.dart';
import '../profile/profile_page.dart';
import 'create_post_sheet.dart';
import 'post_card.dart';
import 'post_model.dart';
import 'posts_repository.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<String>>(
      stream: BlockRepository.instance.streamBlockedUids(),
      builder: (context, blockedSnap) {
        final blocked = blockedSnap.data ?? const <String>{};

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: PostsRepository.instance.streamLatestSnap(limit: 50),
          builder: (context, snap) {
            final posts = <PostModel>[];
            if (snap.hasData) {
              for (final doc in snap.data!.docs) {
                try {
                  final post = PostModel.fromDoc(doc);
                  if (!blocked.contains(post.authorId)) posts.add(post);
                } catch (_) {
                  // Keep the home page safe if one old document is malformed.
                }
              }
            }

            return RefreshIndicator(
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 450));
              },
              color: AppTheme.orangeDark,
              backgroundColor: Colors.white,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  _HomeHeader(user: FirebaseAuth.instance.currentUser),
                  const SizedBox(height: 16),
                  _ComposerCard(onTap: () => _openCreatePost(context)),
                  const SizedBox(height: 12),
                  const _QuickActionsStrip(),
                  if (snap.hasData && posts.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _FollowSuggestions(posts: posts),
                  ],
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'Community',
                    actionLabel: snap.hasData && posts.isNotEmpty
                        ? '${posts.length} posts'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  if (snap.hasError)
                    const _FeedErrorState()
                  else if (!snap.hasData)
                    const _FeedLoadingSkeleton()
                  else if (posts.isEmpty)
                    _EmptyCommunityState(
                      onCreatePost: () => _openCreatePost(context),
                    )
                  else ...[
                    ...posts.map(
                      (post) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: PostCard(post: post),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const _CaughtUpNotice(),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCreatePost(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreatePostSheet(),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    final uid = user?.uid ?? '';
    final fallbackRaw =
        (user?.displayName ?? user?.email?.split('@').first ?? 'friend').trim();

    return StreamBuilder<UserMini?>(
      stream: uid.isEmpty ? null : UserMiniCache.instance.stream(uid),
      initialData: uid.isEmpty ? null : UserMiniCache.instance.peek(uid),
      builder: (context, snap) {
        final rawName = (snap.data?.name.trim().isNotEmpty == true)
            ? snap.data!.name.trim()
            : fallbackRaw;
        final first = rawName.isEmpty ? 'friend' : rawName.split(' ').first;
        final name = first.isEmpty
            ? 'friend'
            : first.substring(0, 1).toUpperCase() + first.substring(1);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.ink,
                      height: 1.05,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Latest posts from the PetTounsi community',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (uid.isNotEmpty) ...[const SizedBox(width: 12)],
          ],
        );
      },
    );
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'local_user';
    final fallbackName = user?.displayName ?? user?.email ?? 'User';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.outline.withAlpha(210)),
            boxShadow: AppTheme.softShadows(0.04),
          ),
          child: Row(
            children: [
              UserAvatar(
                uid: uid,
                radius: 19,
                fallbackName: fallbackName,
                fallbackPhotoUrl: user?.photoURL,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Share an update, question, or pet photo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.8,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.muted,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEE8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Post',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.orangeDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsStrip extends StatelessWidget {
  const _QuickActionsStrip();

  @override
  Widget build(BuildContext context) {
    final actions = <_HomeActionData>[
      _HomeActionData(
        title: 'Sitters',
        subtitle: 'Trusted care',
        icon: Icons.pets_rounded,
        iconColor: const Color(0xFFFF6D4D),
        background: const Color(0xFFFFF0EA),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PetBabysittingPage()),
        ),
      ),
      _HomeActionData(
        title: 'Lost pet',
        subtitle: 'Post an alert',
        icon: Icons.location_searching_rounded,
        iconColor: const Color(0xFF7C62D7),
        background: const Color(0xFFF3EFFF),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PetReportsPage()),
        ),
      ),
      _HomeActionData(
        title: 'Adopt',
        subtitle: 'Give a home',
        icon: Icons.favorite_rounded,
        iconColor: const Color(0xFFDA5C8D),
        background: const Color(0xFFFFEEF5),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdoptRescuePage()),
        ),
      ),
      _HomeActionData(
        title: 'Vets',
        subtitle: 'Clinics nearby',
        icon: Icons.medical_services_rounded,
        iconColor: const Color(0xFF26976B),
        background: const Color(0xFFEAF8F0),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VetsPage()),
        ),
      ),
    ];

    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.82,
      ),
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.94, end: 1),
          duration: Duration(milliseconds: 220 + (index * 45)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 18),
              child: child,
            ),
          ),
          child: _ActionCard(data: actions[index]),
        );
      },
    );
  }
}

class _HomeActionData {
  const _HomeActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color background;
  final VoidCallback onTap;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.data});

  final _HomeActionData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: data.background,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: data.onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(210)),
            boxShadow: AppTheme.softShadows(0.08),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(235),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(data.icon, color: data.iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.muted,
                        height: 1.1,
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

class _FollowSuggestions extends StatelessWidget {
  const _FollowSuggestions({required this.posts});

  final List<PostModel> posts;

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return const SizedBox.shrink();

    return StreamBuilder<Set<String>>(
      stream: FollowRepository.instance.streamMyFollowingUids(),
      builder: (context, followingSnap) {
        final following = followingSnap.data ?? const <String>{};

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(me)
              .snapshots(),
          builder: (context, profileSnap) {
            final profile =
                profileSnap.data?.data() ?? const <String, dynamic>{};
            final myCity = _profileText(profile, const [
              'city',
              'locationCity',
              'homeCity',
            ]);
            final myRegion = _profileText(profile, const [
              'governorate',
              'region',
              'state',
              'locationRegion',
            ]);

            final suggestions = _rankCandidates(
              posts: posts,
              me: me,
              following: following,
              myCity: myCity,
              myRegion: myRegion,
            );

            if (suggestions.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  title: 'People to follow',
                  actionLabel: 'Suggested for you',
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 124,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return _FollowSuggestionCard(
                        candidate: suggestions[index],
                        myFollowing: following,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static List<_FollowCandidate> _rankCandidates({
    required List<PostModel> posts,
    required String me,
    required Set<String> following,
    required String myCity,
    required String myRegion,
  }) {
    final byAuthor = <String, _FollowCandidate>{};
    final now = DateTime.now();
    final dayKey = _dayKey(now);

    for (final post in posts) {
      final authorId = post.authorId.trim();
      if (authorId.isEmpty || authorId == me) continue;
      if (following.contains(authorId)) continue;

      final existing = byAuthor[authorId];
      final activity = post.activityAt;
      final locationMatch = _matchesLocation(post, myCity, myRegion);

      if (existing == null) {
        byAuthor[authorId] = _FollowCandidate(
          uid: authorId,
          samplePost: post,
          postCount: 1,
          engagement: post.likeCount + post.commentCount,
          locationMatch: locationMatch,
          latestActivity: activity,
          dailyScore: _dailyScore('$me|$dayKey|$authorId'),
        );
      } else {
        existing.postCount += 1;
        existing.engagement += post.likeCount + post.commentCount;
        existing.locationMatch = existing.locationMatch || locationMatch;
        if (_isAfter(activity, existing.latestActivity)) {
          existing.latestActivity = activity;
          existing.samplePost = post;
        }
      }
    }

    final candidates = byAuthor.values.toList();
    for (final candidate in candidates) {
      candidate.score = _candidateScore(candidate, now);
      candidate.reason = _candidateReason(candidate);
    }

    candidates.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return b.uid.compareTo(a.uid);
    });

    return candidates.take(8).toList(growable: false);
  }

  static String _profileText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim().toLowerCase();
      }
    }
    return '';
  }

  static bool _matchesLocation(PostModel post, String myCity, String myRegion) {
    if (myCity.isEmpty && myRegion.isEmpty) return false;
    final postCity = post.city.trim().toLowerCase();
    final postRegion = post.region.trim().toLowerCase();
    final postLocation = post.locationText.trim().toLowerCase();
    return (myCity.isNotEmpty &&
            (postCity == myCity || postLocation.contains(myCity))) ||
        (myRegion.isNotEmpty &&
            (postRegion == myRegion || postLocation.contains(myRegion)));
  }

  static bool _isAfter(DateTime? a, DateTime? b) {
    if (a == null) return false;
    if (b == null) return true;
    return a.isAfter(b);
  }

  static int _candidateScore(_FollowCandidate candidate, DateTime now) {
    final activity = candidate.latestActivity;
    var recency = 8;
    if (activity != null) {
      final hours = now.difference(activity).inHours;
      if (hours <= 24) {
        recency = 58;
      } else if (hours <= 72) {
        recency = 44;
      } else if (hours <= 168) {
        recency = 32;
      } else if (hours <= 336) {
        recency = 18;
      }
    }

    final engagement = candidate.engagement.clamp(0, 40).toInt();
    final activityDepth = (candidate.postCount * 7).clamp(0, 28).toInt();
    final localBoost = candidate.locationMatch ? 34 : 0;

    return recency +
        engagement +
        activityDepth +
        localBoost +
        candidate.dailyScore;
  }

  static String _candidateReason(_FollowCandidate candidate) {
    if (candidate.locationMatch) return 'Near your area';
    if (candidate.postCount >= 2) return 'Shared community';
    return 'Suggested profile';
  }

  static int _dailyScore(String input) {
    var hash = 0;
    for (final unit in input.codeUnits) {
      hash = 0x1fffffff & (hash * 31 + unit);
    }
    return hash % 36;
  }

  static String _dayKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class _FollowCandidate {
  _FollowCandidate({
    required this.uid,
    required this.samplePost,
    required this.postCount,
    required this.engagement,
    required this.locationMatch,
    required this.latestActivity,
    required this.dailyScore,
  });

  final String uid;
  PostModel samplePost;
  int postCount;
  int engagement;
  bool locationMatch;
  DateTime? latestActivity;
  final int dailyScore;
  int score = 0;
  String reason = 'Fresh pick';
}

class _FollowSuggestionCard extends StatelessWidget {
  const _FollowSuggestionCard({
    required this.candidate,
    required this.myFollowing,
  });

  final _FollowCandidate candidate;
  final Set<String> myFollowing;

  @override
  Widget build(BuildContext context) {
    final post = candidate.samplePost;
    return Container(
      width: 242,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline.withAlpha(210)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          UserAvatar(
            uid: candidate.uid,
            radius: 24,
            fallbackName: 'PetTounsi user',
            fallbackPhotoUrl: null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(uid: candidate.uid),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                UserName(
                  uid: candidate.uid,
                  fallback: 'PetTounsi user',
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 13.6,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 5),
                StreamBuilder<_FollowSocialStats>(
                  stream: _socialStatsStream(candidate.uid, myFollowing),
                  builder: (context, snap) {
                    final stats = snap.data;
                    final headline = _socialHeadline(stats, candidate);
                    final details = _socialDetails(post, stats, candidate);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              (stats?.mutualFollowers ?? 0) > 0
                                  ? Icons.group_rounded
                                  : candidate.locationMatch
                                  ? Icons.place_rounded
                                  : Icons.person_add_alt_1_rounded,
                              size: 13,
                              color: AppTheme.orangeDark,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                headline,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.4,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.2,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.muted.withAlpha(210),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 9),
                StreamBuilder<bool>(
                  stream: FollowRepository.instance.streamIsFollowing(
                    candidate.uid,
                  ),
                  builder: (context, snap) {
                    final isFollowing = snap.data ?? false;
                    return InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: isFollowing
                          ? null
                          : () async {
                              try {
                                await FollowRepository.instance.follow(
                                  targetUid: candidate.uid,
                                );
                              } catch (_) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not follow this user.',
                                    ),
                                  ),
                                );
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isFollowing
                              ? AppTheme.mist
                              : AppTheme.orangeDark,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isFollowing ? AppTheme.muted : Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Stream<_FollowSocialStats> _socialStatsStream(
    String uid,
    Set<String> myFollowing,
  ) {
    return FirebaseFirestore.instance
        .collection('follows')
        .doc(uid)
        .collection('followers')
        .snapshots()
        .map((snap) {
          var mutual = 0;
          for (final doc in snap.docs) {
            if (myFollowing.contains(doc.id)) mutual += 1;
          }
          return _FollowSocialStats(
            followers: snap.size,
            mutualFollowers: mutual,
          );
        });
  }

  static String _socialHeadline(
    _FollowSocialStats? stats,
    _FollowCandidate candidate,
  ) {
    if (stats == null) return candidate.reason;
    if (stats.mutualFollowers > 0) {
      return '${stats.mutualFollowers} mutual ${stats.mutualFollowers == 1 ? 'follower' : 'followers'}';
    }
    if (stats.followers > 0) {
      return '${stats.followers} ${stats.followers == 1 ? 'follower' : 'followers'}';
    }
    return candidate.reason;
  }

  static String _socialDetails(
    PostModel post,
    _FollowSocialStats? stats,
    _FollowCandidate candidate,
  ) {
    final location = post.city.trim().isNotEmpty
        ? post.city.trim()
        : post.locationText.trim();
    final parts = <String>[
      if ((stats?.mutualFollowers ?? 0) > 0 && (stats?.followers ?? 0) > 0)
        '${stats!.followers} total followers',
      if ((stats?.mutualFollowers ?? 0) == 0 && candidate.postCount > 1)
        '${candidate.postCount} recent posts',
      if (location.isNotEmpty) location,
    ];
    if (parts.isEmpty) return 'Suggested from the community';
    return parts.take(2).join(' • ');
  }
}

class _FollowSocialStats {
  const _FollowSocialStats({
    required this.followers,
    required this.mutualFollowers,
  });

  final int followers;
  final int mutualFollowers;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    // ignore: unused_element_parameter
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final action = actionLabel;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16.2,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
        ),
        if (action != null)
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onActionTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Text(
                action,
                style: TextStyle(
                  fontSize: 12.8,
                  fontWeight: FontWeight.w900,
                  color: onActionTap == null
                      ? AppTheme.muted
                      : AppTheme.orangeDark,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyCommunityState extends StatelessWidget {
  const _EmptyCommunityState({required this.onCreatePost});

  final VoidCallback onCreatePost;

  @override
  Widget build(BuildContext context) {
    return _NoticeCard(
      icon: Icons.forum_rounded,
      title: 'No posts yet',
      subtitle: 'Be the first to post today.',
      action: 'Create post',
      onTap: onCreatePost,
    );
  }
}

class _FeedErrorState extends StatelessWidget {
  const _FeedErrorState();

  @override
  Widget build(BuildContext context) {
    return const _StaticNoticeCard(
      icon: Icons.wifi_off_rounded,
      title: 'Could not load posts',
      subtitle: 'Check your connection and refresh.',
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: _NoticeBody(
          icon: icon,
          title: title,
          subtitle: subtitle,
          trailing: Text(
            action,
            style: const TextStyle(
              fontSize: 12.8,
              fontWeight: FontWeight.w900,
              color: AppTheme.orangeDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _StaticNoticeCard extends StatelessWidget {
  const _StaticNoticeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _NoticeBody(icon: icon, title: title, subtitle: subtitle);
  }
}

class _NoticeBody extends StatelessWidget {
  const _NoticeBody({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline.withAlpha(210)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEE8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: AppTheme.orangeDark, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.6,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.muted,
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class _CaughtUpNotice extends StatelessWidget {
  const _CaughtUpNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline.withAlpha(180)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppTheme.orangeDark,
            size: 22,
          ),
          SizedBox(height: 8),
          Text(
            "You're caught up",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.2,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'You have seen the latest community posts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.4,
              fontWeight: FontWeight.w600,
              color: AppTheme.muted,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedLoadingSkeleton extends StatelessWidget {
  const _FeedLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _PostSkeletonCard(),
        SizedBox(height: 12),
        _PostSkeletonCard(),
        SizedBox(height: 12),
        _PostSkeletonCard(),
      ],
    );
  }
}

class _PostSkeletonCard extends StatelessWidget {
  const _PostSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline.withAlpha(150)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonDot(size: 42),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(widthFactor: 0.46, height: 12),
                    SizedBox(height: 8),
                    _SkeletonLine(widthFactor: 0.28, height: 10),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _SkeletonLine(widthFactor: 0.92, height: 12),
          SizedBox(height: 8),
          _SkeletonLine(widthFactor: 0.72, height: 12),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF0E8DF),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SkeletonDot extends StatelessWidget {
  const _SkeletonDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF0E8DF),
      ),
    );
  }
}
