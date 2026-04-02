import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../repositories/block_repository.dart';
import '../../ui/app_theme.dart';
import '../../ui/premium_cards.dart';
import '../../ui/premium_feedback.dart';
import '../../ui/premium_pills.dart';
import '../home/post_card.dart';
import '../home/post_model.dart';
import '../home/posts_repository.dart';
import '../profile/profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _input = TextEditingController();
  Timer? _debounce;

  String _q = '';

  bool _pLoading = false;
  bool _pHasMore = false;
  DocumentSnapshot<Map<String, dynamic>>? _pCursor;
  final List<PostModel> _posts = [];
  final Set<String> _postIds = <String>{};
  int _postSearchToken = 0;

  static const int _pageSize = 20;
  static const int _scanBatchSize = 35;
  static const int _maxScanDocsPerPass = 420;

  String get _myUid => _auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();

    _input.addListener(() {
      if (mounted) setState(() {});
    });

    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      if (_tabs.index == 1 && _q.trim().isNotEmpty && _posts.isEmpty && !_pLoading) {
        _loadPosts(reset: true);
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabs.dispose();
    _input.dispose();
    super.dispose();
  }

  String _norm(String s) => s.trim().toLowerCase();

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      final nq = v.trim();
      if (!mounted) return;
      setState(() => _q = nq);
      _loadPosts(reset: true);
    });
  }

  DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  bool _matchesUserData(Map<String, dynamic> d, String qLower) {
    if (qLower.isEmpty) return false;

    final username = ((d['username'] ?? '') as String).trim().toLowerCase();
    final usernameLower = ((d['usernameLower'] ?? '') as String)
        .trim()
        .toLowerCase();
    final displayName = ((d['displayName'] ?? '') as String)
        .trim()
        .toLowerCase();

    return username.contains(qLower) ||
        usernameLower.contains(qLower) ||
        displayName.contains(qLower);
  }

  int _userScore(Map<String, dynamic> d, String qLower) {
    if (qLower.isEmpty) return 0;

    final username = ((d['username'] ?? '') as String).trim().toLowerCase();
    final displayName = ((d['displayName'] ?? '') as String)
        .trim()
        .toLowerCase();

    if (username == qLower || displayName == qLower) return 0;
    if (username.startsWith(qLower) || displayName.startsWith(qLower)) return 1;
    if (username.contains(qLower) || displayName.contains(qLower)) return 2;
    return 99;
  }

  DateTime _userSortDate(Map<String, dynamic> d) {
    return _toDate(d['updatedAt']) ??
        _toDate(d['lastSeenAt']) ??
        _toDate(d['createdAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<String> _tokens(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s#]+', unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .map((e) => e.trim())
        .where((e) => e.length >= 2)
        .toList();
  }

  int _postScore(Map<String, dynamic> data, String qLower, List<String> queryTokens) {
    final text = ((data['text'] ?? '') as String).trim().toLowerCase();
    final author = ((data['authorName'] ?? '') as String).trim().toLowerCase();
    final rawKeywords = data['keywords'];
    final keywords = rawKeywords is List
        ? rawKeywords.whereType<String>().map((e) => e.trim().toLowerCase()).toList()
        : const <String>[];

    if (keywords.contains(qLower)) return 0;
    if (text == qLower || author == qLower) return 0;
    if (text.contains(' $qLower ') || text.startsWith('$qLower ') || text.endsWith(' $qLower')) {
      return 1;
    }
    if (text.contains(qLower) || author.contains(qLower)) return 2;
    if (keywords.any((k) => k.startsWith(qLower))) return 3;
    if (queryTokens.isNotEmpty && queryTokens.every(text.contains)) return 4;
    return 99;
  }

  bool _postMatches(Map<String, dynamic> data, String qLower, List<String> queryTokens) {
    if (qLower.isEmpty) return false;

    final text = ((data['text'] ?? '') as String).trim().toLowerCase();
    final author = ((data['authorName'] ?? '') as String).trim().toLowerCase();
    final rawKeywords = data['keywords'];
    final keywords = rawKeywords is List
        ? rawKeywords.whereType<String>().map((e) => e.trim().toLowerCase()).toList()
        : const <String>[];

    if (keywords.contains(qLower)) return true;
    if (keywords.any((k) => k.startsWith(qLower))) return true;
    if (text.contains(qLower)) return true;
    if (author.contains(qLower)) return true;
    return queryTokens.isNotEmpty && queryTokens.every(text.contains);
  }

  Future<void> _loadPosts({required bool reset}) async {
    if (_pLoading) return;

    final qLower = _norm(_q);
    final myToken = ++_postSearchToken;

    if (qLower.isEmpty) {
      if (!mounted) return;
      setState(() {
        _posts.clear();
        _postIds.clear();
        _pCursor = null;
        _pHasMore = false;
        _pLoading = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _pLoading = true;
        if (reset) {
          _posts.clear();
          _postIds.clear();
          _pCursor = null;
          _pHasMore = true;
        }
      });
    }

    try {
      var cursor = _pCursor;
      final queryTokens = _tokens(qLower);
      final matches = <_ScoredPost>[];
      var scanned = 0;
      var reachedEnd = false;

      while (matches.length < _pageSize && scanned < _maxScanDocsPerPass) {
        final snap = await PostsRepository.instance.fetchLatestSnap(
          startAfter: cursor,
          limit: _scanBatchSize,
        );
        if (!mounted || myToken != _postSearchToken) return;

        final docs = snap.docs;
        if (docs.isEmpty) {
          reachedEnd = true;
          break;
        }

        cursor = docs.last;
        scanned += docs.length;

        for (final doc in docs) {
          if (_postIds.contains(doc.id)) continue;
          final data = doc.data();
          if (!_postMatches(data, qLower, queryTokens)) continue;
          matches.add(
            _ScoredPost(
              post: PostModel.fromDoc(doc),
              score: _postScore(data, qLower, queryTokens),
            ),
          );
        }

        if (docs.length < _scanBatchSize) {
          reachedEnd = true;
          break;
        }
      }

      matches.sort((a, b) {
        if (a.score != b.score) return a.score.compareTo(b.score);
        final ad = a.post.createdAt;
        final bd = b.post.createdAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });

      if (!mounted || myToken != _postSearchToken) return;

      setState(() {
        for (final item in matches) {
          if (_postIds.add(item.post.id)) {
            _posts.add(item.post);
          }
        }
        _pCursor = cursor;
        _pHasMore = !reachedEnd;
      });
    } catch (_) {
      if (!mounted || myToken != _postSearchToken) return;
      setState(() {
        _pHasMore = false;
      });
    } finally {
      if (mounted && myToken == _postSearchToken) {
        setState(() => _pLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qLower = _norm(_q);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Search')),
      body: StreamBuilder<Set<String>>(
        stream: BlockRepository.instance.streamBlockedUids(),
        builder: (context, bSnap) {
          final blocked = bSnap.data ?? {};

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db.collection('users').limit(300).snapshots(),
            builder: (context, userSnap) {
              final docs = userSnap.data?.docs ?? const [];
              final usersLoading =
                  userSnap.connectionState == ConnectionState.waiting &&
                  docs.isEmpty;

              final users =
                  docs.where((d) {
                    if (qLower.isEmpty) return false;
                    if (d.id == _myUid) return false;
                    if (blocked.contains(d.id)) return false;
                    return _matchesUserData(d.data(), qLower);
                  }).toList()..sort((a, b) {
                    final as = _userScore(a.data(), qLower);
                    final bs = _userScore(b.data(), qLower);
                    if (as != bs) return as.compareTo(bs);

                    final ad = _userSortDate(a.data());
                    final bd = _userSortDate(b.data());
                    final dt = bd.compareTo(ad);
                    if (dt != 0) return dt;

                    final an =
                        ((a.data()['username'] ?? a.data()['displayName'] ?? '')
                                as String)
                            .toLowerCase();
                    final bn =
                        ((b.data()['username'] ?? b.data()['displayName'] ?? '')
                                as String)
                            .toLowerCase();
                    return an.compareTo(bn);
                  });

              final posts = _posts
                  .where((p) => !blocked.contains(p.authorId))
                  .toList();

              final activeCount = _tabs.index == 0 ? users.length : posts.length;

              return Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _SearchFieldCard(
                      controller: _input,
                      onChanged: _onQueryChanged,
                      onClear: () {
                        _input.clear();
                        _onQueryChanged('');
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _SearchTopControls(
                      controller: _tabs,
                      count: activeCount,
                      hasQuery: qLower.isNotEmpty,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        usersLoading && qLower.isNotEmpty
                            ? const _SearchLoadingState(
                                kind: _SearchLoadingKind.users,
                              )
                            : users.isEmpty
                                ? _SearchEmptyState(
                                    icon: Icons.person_search_rounded,
                                    title: qLower.isEmpty
                                        ? 'Search for people'
                                        : 'No users found',
                                    subtitle: qLower.isEmpty
                                        ? 'Type a name or username to begin.'
                                        : 'Try another name or username.',
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      4,
                                      12,
                                      16,
                                    ),
                                    itemCount: users.length,
                                    separatorBuilder: (_, __) => const SizedBox(
                                      height: 10,
                                    ),
                                    itemBuilder: (context, i) => _UserResultCard(
                                      data: users[i].data(),
                                      uid: users[i].id,
                                    ),
                                  ),
                        NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (qLower.isEmpty) return false;
                            if (n.metrics.pixels >=
                                n.metrics.maxScrollExtent - 280) {
                              if (!_pLoading && _pHasMore) {
                                _loadPosts(reset: false);
                              }
                            }
                            return false;
                          },
                          child: posts.isEmpty && _pLoading
                              ? const _SearchLoadingState(
                                  kind: _SearchLoadingKind.posts,
                                )
                              : posts.isEmpty && !_pLoading
                                  ? _SearchEmptyState(
                                      icon: Icons.search_off_rounded,
                                      title: qLower.isEmpty
                                          ? 'Search posts'
                                          : 'No posts found',
                                      subtitle: qLower.isEmpty
                                          ? 'Type a word from the post content.'
                                          : 'Try another word related to the post content.',
                                    )
                                  : ListView(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        4,
                                        12,
                                        12,
                                      ),
                                      children: [
                                        ...List.generate(
                                          posts.length,
                                          (i) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: PostCard(post: posts[i]),
                                          ),
                                        ),
                                        if (_pLoading)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 18,
                                            ),
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          )
                                        else if (!_pHasMore && posts.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'No more matching posts.',
                                                style: TextStyle(
                                                  color: AppTheme.ink.withAlpha(
                                                    140,
                                                  ),
                                                  fontWeight: FontWeight.w800,
                                                ),
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
            },
          );
        },
      ),
    );
  }
}

class _ScoredPost {
  const _ScoredPost({required this.post, required this.score});

  final PostModel post;
  final int score;
}

class _SearchTopControls extends StatelessWidget {
  const _SearchTopControls({
    required this.controller,
    required this.count,
    required this.hasQuery,
  });

  final TabController controller;
  final int count;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _PremiumTabs(controller: controller)),
        if (hasQuery) ...[
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final label = controller.index == 0
                  ? '$count user${count == 1 ? '' : 's'}'
                  : '$count post${count == 1 ? '' : 's'}';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.ink.withAlpha(200),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    height: 1,
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _SearchFieldCard extends StatelessWidget {
  const _SearchFieldCard({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.08),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search people or posts',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: AppTheme.orange, width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _PremiumTabs extends StatelessWidget {
  const _PremiumTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.mist,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.06),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(14),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [AppTheme.orchidDark, AppTheme.roseDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.orchidDark.withAlpha(24),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.ink.withAlpha(185),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12.8,
          height: 1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12.8,
          height: 1,
        ),
        tabs: const [Tab(text: 'Users'), Tab(text: 'Posts')],
      ),
    );
  }
}

class _UserResultCard extends StatelessWidget {
  const _UserResultCard({required this.data, required this.uid});

  final Map<String, dynamic> data;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final username = ((data['username'] ?? '') as String).trim();
    final displayName = ((data['displayName'] ?? '') as String).trim();
    final photo = ((data['photoUrl'] ?? '') as String).trim();

    final primaryName = displayName.isNotEmpty ? displayName : username;
    final secondaryHandle =
        username.isNotEmpty && username != primaryName ? '@$username' : '';

    return PremiumCardSurface(
      radius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(12),
      shadowOpacity: 0.08,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage(uid: uid)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.lilac,
              border: Border.all(color: Colors.white),
            ),
            child: CircleAvatar(
              backgroundColor: AppTheme.bg,
              backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
              child: photo.isEmpty
                  ? Text(
                      (primaryName.isEmpty ? 'U' : primaryName[0]).toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryName.isEmpty ? 'User' : primaryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.2,
                    height: 1.06,
                  ),
                ),
                if (secondaryHandle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    secondaryHandle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.muted.withAlpha(220),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.1,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _UserSocialMeta(uid: uid),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.chevron_right_rounded,
            size: 24,
            color: AppTheme.ink.withAlpha(110),
          ),
        ],
      ),
    );
  }
}

class _UserSocialMeta extends StatelessWidget {
  const _UserSocialMeta({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final me = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db
          .collection('follows')
          .doc(uid)
          .collection('followers')
          .snapshots(),
      builder: (context, followersSnap) {
        final followers = followersSnap.data?.docs.length ?? 0;

        if (me.isEmpty || me == uid) {
          return Align(
            alignment: Alignment.centerLeft,
            child: _UserMetaChip(
              icon: Icons.groups_rounded,
              label: '$followers follower${followers == 1 ? '' : 's'}',
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: db
              .collection('follows')
              .doc(uid)
              .collection('following')
              .doc(me)
              .snapshots(),
          builder: (context, followsMeSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db
                  .collection('follows')
                  .doc(me)
                  .collection('following')
                  .snapshots(),
              builder: (context, myFollowingSnap) {
                final followsMe = followsMeSnap.data?.exists ?? false;
                final myFollowingIds =
                    myFollowingSnap.data?.docs.map((doc) => doc.id).toSet() ??
                        <String>{};

                var mutualFollowers = 0;
                for (final doc
                    in followersSnap.data?.docs ??
                        <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
                  final followerUid = doc.id;
                  if (followerUid == me || followerUid == uid) continue;
                  if (myFollowingIds.contains(followerUid)) {
                    mutualFollowers += 1;
                  }
                }

                late final IconData icon;
                late final String label;
                if (followsMe) {
                  icon = Icons.person_add_alt_1_rounded;
                  label = 'Following you';
                } else if (mutualFollowers > 0) {
                  icon = Icons.group_rounded;
                  label =
                      '$mutualFollowers mutual follower${mutualFollowers == 1 ? '' : 's'}';
                } else {
                  icon = Icons.groups_rounded;
                  label = '$followers follower${followers == 1 ? '' : 's'}';
                }

                return Align(
                  alignment: Alignment.centerLeft,
                  child: _UserMetaChip(icon: icon, label: label),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _UserMetaChip extends StatelessWidget {
  const _UserMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PremiumToneChip(
      label: label,
      icon: icon,
      bg: const Color(0xFFF8F5FF),
      fg: AppTheme.ink.withAlpha(205),
      iconColor: const Color(0xFF7C62D7),
      borderColor: AppTheme.outline,
      fontSize: 11.8,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
      children: [
        PremiumEmptyStateCard(
          icon: icon,
          iconColor: const Color(0xFF4C79C8),
          iconBg: AppTheme.sky,
          title: title,
          subtitle: subtitle,
        ),
      ],
    );
  }
}

enum _SearchLoadingKind { users, posts }

class _SearchLoadingState extends StatelessWidget {
  const _SearchLoadingState({required this.kind});

  final _SearchLoadingKind kind;

  @override
  Widget build(BuildContext context) {
    final title = kind == _SearchLoadingKind.users
        ? 'Loading people'
        : 'Loading posts';

    final subtitle = kind == _SearchLoadingKind.users
        ? 'Fetching profiles that match your search.'
        : 'Bringing in community posts for this search.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
      children: [
        PremiumMiniEmptyCard(
          icon: kind == _SearchLoadingKind.users
              ? Icons.person_search_rounded
              : Icons.feed_rounded,
          iconColor: const Color(0xFF7C62D7),
          iconBg: AppTheme.lilac,
          title: title,
          subtitle: subtitle,
        ),
        const SizedBox(height: 12),
        ...List.generate(
          kind == _SearchLoadingKind.users ? 5 : 3,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PremiumSkeletonCard(
              height: kind == _SearchLoadingKind.users ? 88 : 170,
              radius: 22,
            ),
          ),
        ),
      ],
    );
  }
}
