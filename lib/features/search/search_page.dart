import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../repositories/block_repository.dart';
import '../../ui/app_theme.dart';
import '../../ui/premium_cards.dart';
import '../../ui/premium_feedback.dart';
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
  String? _postError;
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
      if (_tabs.index == 1 && _q.trim().isNotEmpty && _posts.isEmpty) {
        _loadPosts(reset: true);
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    _tabs.dispose();
    super.dispose();
  }

  String _norm(String value) => value.trim().toLowerCase();

  String _asString(dynamic value) {
    if (value is String) return value.trim();
    return '';
  }

  void _onQueryChanged(String value, {bool immediate = false}) {
    _debounce?.cancel();

    void apply() {
      final next = value.trim();
      if (!mounted || next == _q) return;

      setState(() {
        _q = next;
        _postError = null;
      });

      if (next.isEmpty) {
        _clearPosts();
        return;
      }

      if (_tabs.index == 1) {
        _loadPosts(reset: true);
      } else {
        _resetPostCacheForNextPostsTab();
      }
    }

    if (immediate) {
      apply();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 260), apply);
  }

  void _clearSearch() {
    _debounce?.cancel();
    _input.clear();
    setState(() {
      _q = '';
      _postError = null;
    });
    _clearPosts();
  }

  void _clearPosts() {
    _postSearchToken++;
    if (!mounted) return;
    setState(() {
      _posts.clear();
      _postIds.clear();
      _pCursor = null;
      _pHasMore = false;
      _pLoading = false;
      _postError = null;
    });
  }

  void _resetPostCacheForNextPostsTab() {
    _postSearchToken++;
    _posts.clear();
    _postIds.clear();
    _pCursor = null;
    _pHasMore = false;
    _pLoading = false;
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  bool _matchesUserData(Map<String, dynamic> data, String qLower) {
    if (qLower.isEmpty) return false;

    final username = _asString(data['username']).toLowerCase();
    final usernameLower = _asString(data['usernameLower']).toLowerCase();
    final displayName = _asString(data['displayName']).toLowerCase();
    final bio = _asString(data['bio']).toLowerCase();

    return username.contains(qLower) ||
        usernameLower.contains(qLower) ||
        displayName.contains(qLower) ||
        bio.contains(qLower);
  }

  int _userScore(Map<String, dynamic> data, String qLower) {
    if (qLower.isEmpty) return 99;

    final username = _asString(data['username']).toLowerCase();
    final displayName = _asString(data['displayName']).toLowerCase();
    final bio = _asString(data['bio']).toLowerCase();

    if (username == qLower || displayName == qLower) return 0;
    if (username.startsWith(qLower) || displayName.startsWith(qLower)) {
      return 1;
    }
    if (username.contains(qLower) || displayName.contains(qLower)) return 2;
    if (bio.contains(qLower)) return 3;
    return 99;
  }

  DateTime _userSortDate(Map<String, dynamic> data) {
    return _toDate(data['lastSeenAt']) ??
        _toDate(data['updatedAt']) ??
        _toDate(data['createdAt']) ??
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

  bool _postMatches(
    Map<String, dynamic> data,
    String qLower,
    List<String> queryTokens,
  ) {
    if (qLower.isEmpty) return false;

    final text = _asString(data['text']).toLowerCase();
    final author = _asString(data['authorName']).toLowerCase();
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

  int _postScore(
    Map<String, dynamic> data,
    String qLower,
    List<String> queryTokens,
  ) {
    final text = _asString(data['text']).toLowerCase();
    final author = _asString(data['authorName']).toLowerCase();
    final rawKeywords = data['keywords'];
    final keywords = rawKeywords is List
        ? rawKeywords.whereType<String>().map((e) => e.trim().toLowerCase()).toList()
        : const <String>[];

    if (keywords.contains(qLower)) return 0;
    if (text == qLower || author == qLower) return 0;
    if (text.contains(' $qLower ') ||
        text.startsWith('$qLower ') ||
        text.endsWith(' $qLower')) {
      return 1;
    }
    if (text.contains(qLower) || author.contains(qLower)) return 2;
    if (keywords.any((k) => k.startsWith(qLower))) return 3;
    if (queryTokens.isNotEmpty && queryTokens.every(text.contains)) return 4;
    return 99;
  }

  Future<void> _loadPosts({required bool reset}) async {
    if (_pLoading) return;

    final qLower = _norm(_q);
    final myToken = ++_postSearchToken;

    if (qLower.isEmpty) {
      _clearPosts();
      return;
    }

    if (mounted) {
      setState(() {
        _pLoading = true;
        _postError = null;
        if (reset) {
          _posts.clear();
          _postIds.clear();
          _pCursor = null;
          _pHasMore = true;
        }
      });
    }

    try {
      var cursor = reset ? null : _pCursor;
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
        _postError = 'Posts could not be loaded. Check your connection and try again.';
        _pHasMore = false;
      });
    } finally {
      if (mounted && myToken == _postSearchToken) {
        setState(() => _pLoading = false);
      }
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _buildUserResults(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    Set<String> blocked,
    String qLower,
  ) {
    final results = docs.where((doc) {
      if (qLower.isEmpty) return false;
      if (doc.id == _myUid) return false;
      if (blocked.contains(doc.id)) return false;
      return _matchesUserData(doc.data(), qLower);
    }).toList();

    results.sort((a, b) {
      final as = _userScore(a.data(), qLower);
      final bs = _userScore(b.data(), qLower);
      if (as != bs) return as.compareTo(bs);

      final ad = _userSortDate(a.data());
      final bd = _userSortDate(b.data());
      final byRecent = bd.compareTo(ad);
      if (byRecent != 0) return byRecent;

      final an = (_asString(a.data()['username']).isNotEmpty
              ? _asString(a.data()['username'])
              : _asString(a.data()['displayName']))
          .toLowerCase();
      final bn = (_asString(b.data()['username']).isNotEmpty
              ? _asString(b.data()['username'])
              : _asString(b.data()['displayName']))
          .toLowerCase();
      return an.compareTo(bn);
    });

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final qLower = _norm(_q);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Search')),
      body: SafeArea(
        top: false,
        child: StreamBuilder<Set<String>>(
          stream: BlockRepository.instance.streamBlockedUids(),
          builder: (context, bSnap) {
            final blocked = bSnap.data ?? <String>{};

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db.collection('users').limit(300).snapshots(),
              builder: (context, userSnap) {
                final docs = userSnap.data?.docs ?? const [];
                final users = _buildUserResults(docs, blocked, qLower);
                final visiblePosts = _posts
                    .where((post) => !blocked.contains(post.authorId))
                    .toList();

                final usersLoading = userSnap.connectionState ==
                        ConnectionState.waiting &&
                    docs.isEmpty;
                final usersError = userSnap.hasError;
                final activeCount =
                    _tabs.index == 0 ? users.length : visiblePosts.length;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: _SearchHeader(
                        controller: _input,
                        hasText: _input.text.trim().isNotEmpty,
                        onChanged: _onQueryChanged,
                        onClear: _clearSearch,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _SearchTopControls(
                        controller: _tabs,
                        count: activeCount,
                        hasQuery: qLower.isNotEmpty,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _buildUsersTab(
                            qLower: qLower,
                            users: users,
                            loading: usersLoading,
                            hasError: usersError,
                          ),
                          _buildPostsTab(
                            qLower: qLower,
                            posts: visiblePosts,
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
      ),
    );
  }

  Widget _buildUsersTab({
    required String qLower,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    required bool loading,
    required bool hasError,
  }) {
    if (hasError) {
      return _SearchErrorState(
        title: 'People search is unavailable',
        subtitle: 'Please check your connection and try again.',
        onRetry: () => setState(() {}),
      );
    }

    if (qLower.isEmpty) {
      return const _SearchEmptyState(
        icon: Icons.pets_rounded,
        iconColor: AppTheme.orangeDark,
        iconBg: AppTheme.softOrange,
        title: 'Search people',
        subtitle: 'Type a name or username.',
      );
    }

    if (loading) {
      return const _SearchLoadingState(kind: _SearchLoadingKind.users);
    }

    if (users.isEmpty) {
      return const _SearchEmptyState(
        icon: Icons.person_search_rounded,
        iconColor: AppTheme.orangeDark,
        iconBg: AppTheme.softOrange,
        title: 'No people found',
        subtitle: 'Try another name or username.',
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final doc = users[index];
        return _UserResultCard(data: doc.data(), uid: doc.id);
      },
    );
  }

  Widget _buildPostsTab({
    required String qLower,
    required List<PostModel> posts,
  }) {
    if (qLower.isEmpty) {
      return const _SearchEmptyState(
        icon: Icons.forum_rounded,
        iconColor: AppTheme.orangeDark,
        iconBg: AppTheme.softOrange,
        title: 'Search posts',
        subtitle: 'Type a word from a post.',
      );
    }

    if (_postError != null && posts.isEmpty) {
      return _SearchErrorState(
        title: 'Posts search is unavailable',
        subtitle: _postError!,
        onRetry: () => _loadPosts(reset: true),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 280) {
          if (!_pLoading && _pHasMore) {
            _loadPosts(reset: false);
          }
        }
        return false;
      },
      child: posts.isEmpty && _pLoading
          ? const _SearchLoadingState(kind: _SearchLoadingKind.posts)
          : posts.isEmpty
              ? const _SearchEmptyState(
                  icon: Icons.search_off_rounded,
                  iconColor: AppTheme.orangeDark,
                  iconBg: AppTheme.softOrange,
                  title: 'No posts found',
                  subtitle: 'Try another word.',
                )
              : ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
                  children: [
                    ...List.generate(
                      posts.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PostCard(post: posts[index]),
                      ),
                    ),
                    if (_pLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_postError != null)
                      _InlineSearchNotice(
                        icon: Icons.wifi_off_rounded,
                        text: _postError!,
                        actionLabel: 'Retry',
                        onAction: () => _loadPosts(reset: false),
                      )
                    else if (!_pHasMore)
                      const _InlineSearchNotice(
                        icon: Icons.check_circle_rounded,
                        text: 'You reached the end of these results.',
                      ),
                  ],
                ),
    );
  }
}

class _ScoredPost {
  const _ScoredPost({required this.post, required this.score});

  final PostModel post;
  final int score;
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return PremiumCardSurface(
      padding: const EdgeInsets.all(12),
      radius: BorderRadius.circular(24),
      backgroundColor: Colors.white,
      borderColor: AppTheme.outline,
      shadowOpacity: 0.05,
      child: _SearchFieldCard(
        controller: controller,
        hasText: hasText,
        onChanged: onChanged,
        onClear: onClear,
      ),
    );
  }
}

class _SearchFieldCard extends StatelessWidget {
  const _SearchFieldCard({
    required this.controller,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: AppTheme.ink,
          fontWeight: FontWeight.w800,
          fontSize: 14.2,
        ),
        decoration: InputDecoration(
          hintText: 'Search Pettounsi',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: hasText
              ? IconButton(
                  tooltip: 'Clear search',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppTheme.orange, width: 1.3),
          ),
        ),
      ),
    );
  }
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
        Expanded(child: _SearchTabs(controller: controller)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: !hasQuery
              ? const SizedBox.shrink(key: ValueKey('no-count'))
              : Container(
                  key: ValueKey('${controller.index}-$count'),
                  margin: const EdgeInsets.only(left: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.outline),
                    boxShadow: AppTheme.softShadows(0.05),
                  ),
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      final label = controller.index == 0
                          ? '$count ${count == 1 ? 'person' : 'people'}'
                          : '$count post${count == 1 ? '' : 's'}';
                      return Text(
                        label,
                        style: TextStyle(
                          color: AppTheme.ink.withAlpha(205),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          height: 1,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _SearchTabs extends StatelessWidget {
  const _SearchTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
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
            colors: [AppTheme.orangeDark, AppTheme.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.orangeDark.withAlpha(30),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.ink.withAlpha(175),
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
        tabs: const [
          Tab(child: _CompactTab(icon: Icons.people_alt_rounded, label: 'People')),
          Tab(child: _CompactTab(icon: Icons.forum_rounded, label: 'Posts')),
        ],
      ),
    );
  }
}


class _CompactTab extends StatelessWidget {
  const _CompactTab({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 7),
        Text(label),
      ],
    );
  }
}

class _UserResultCard extends StatelessWidget {
  const _UserResultCard({required this.data, required this.uid});

  final Map<String, dynamic> data;
  final String uid;

  String _asString(dynamic value) {
    if (value is String) return value.trim();
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final username = _asString(data['username']);
    final displayName = _asString(data['displayName']);
    final photo = _asString(data['photoUrl']);
    final bio = _asString(data['bio']);

    final name = displayName.isNotEmpty
        ? displayName
        : username.isNotEmpty
            ? username
            : 'Pettounsi user';
    final handle = username.isNotEmpty && username != name ? '@$username' : '';
    final initial = name.trim().isEmpty ? 'U' : name.trim().characters.first.toUpperCase();

    return PremiumCardSurface(
      radius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(12),
      shadowOpacity: 0.07,
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
              color: AppTheme.softOrange,
              border: Border.all(color: Colors.white),
            ),
            child: CircleAvatar(
              backgroundColor: AppTheme.bg,
              backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
              child: photo.isEmpty
                  ? Text(
                      initial,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 15.6,
                          height: 1.06,
                        ),
                      ),
                    ),
                  ],
                ),
                if (handle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    handle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.muted.withAlpha(220),
                      fontWeight: FontWeight.w800,
                      fontSize: 12.3,
                    ),
                  ),
                ],
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.ink.withAlpha(170),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.2,
                      height: 1.22,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      children: [
        PremiumEmptyStateCard(
          icon: icon,
          iconColor: iconColor,
          iconBg: iconBg,
          title: title,
          subtitle: subtitle,
        ),
      ],
    );
  }
}

class _SearchErrorState extends StatelessWidget {
  const _SearchErrorState({
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      children: [
        PremiumEmptyStateCard(
          icon: Icons.wifi_off_rounded,
          iconColor: AppTheme.orangeDark,
          iconBg: AppTheme.softOrange,
          title: title,
          subtitle: subtitle,
          primaryLabel: 'Try again',
          primaryIcon: Icons.refresh_rounded,
          onPrimary: onRetry,
          compact: true,
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
    final isUsers = kind == _SearchLoadingKind.users;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      children: [
        PremiumMiniEmptyCard(
          icon: isUsers ? Icons.person_search_rounded : Icons.forum_rounded,
          iconColor: AppTheme.orangeDark,
          iconBg: AppTheme.softOrange,
          title: isUsers ? 'Finding people' : 'Finding posts',
          subtitle: isUsers
              ? 'Looking through Pettounsi profiles.'
              : 'Scanning recent community posts.',
        ),
        const SizedBox(height: 12),
        ...List.generate(
          isUsers ? 5 : 3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PremiumSkeletonCard(
              height: isUsers ? 88 : 170,
              radius: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineSearchNotice extends StatelessWidget {
  const _InlineSearchNotice({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.orangeDark, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.ink.withAlpha(175),
                fontWeight: FontWeight.w800,
                fontSize: 12.4,
                height: 1.18,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
