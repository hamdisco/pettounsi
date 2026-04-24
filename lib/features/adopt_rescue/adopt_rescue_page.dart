import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/date_formatters.dart';
import '../../features/home/post_model.dart';
import '../../features/home/posts_repository.dart';
import '../../features/messages/chat_page.dart';
import '../../features/messages/messages_repository.dart';
import '../../features/profile/profile_page.dart';
import '../../ui/app_theme.dart';
import '../../ui/premium_cards.dart';
import '../../ui/premium_page_header.dart';
import '../../ui/premium_pills.dart';
import '../../ui/skeleton.dart';
import '../../ui/user_avatar.dart';
import '../../ui/widgets/app_states.dart';

// Post type values stored in Firestore under the 'postType' field
const _kAdopt = 'adopt';
const _kRescue = 'rescue';

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------
class AdoptRescuePage extends StatefulWidget {
  const AdoptRescuePage({super.key});

  @override
  State<AdoptRescuePage> createState() => _AdoptRescuePageState();
}

class _AdoptRescuePageState extends State<AdoptRescuePage> {
  // null = show all (adopt + rescue)
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final bool showAppBar = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: showAppBar
          ? AppBar(
              title: const Text('Adopt & Rescue'),
              backgroundColor: AppTheme.bg,
              foregroundColor: AppTheme.ink,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        top: !showAppBar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: PremiumPageHeader(
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFD94F70),
                title: 'Adopt & Rescue',
                subtitle: 'Give a pet a home or help a stray in need',
                chips: [
                  const PremiumHeaderChip(
                    icon: Icons.verified_user_rounded,
                    label: 'Safe rehoming',
                    bg: Color(0xFFFFE8EC),
                    fg: Color(0xFFD94F70),
                  ),
                  const PremiumHeaderChip(
                    icon: Icons.volunteer_activism_rounded,
                    label: 'Community',
                    bg: AppTheme.mint,
                    fg: Color(0xFF26A06F),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Filter pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  _FilterPill(
                    label: 'All',
                    icon: Icons.pets_rounded,
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Adopt',
                    icon: Icons.favorite_rounded,
                    selected: _filter == _kAdopt,
                    onTap: () => setState(() => _filter = _kAdopt),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Rescue',
                    icon: Icons.campaign_rounded,
                    selected: _filter == _kRescue,
                    onTap: () => setState(() => _filter = _kRescue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _AdoptRescueFeed(key: ValueKey(_filter), filter: _filter),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter pill — local widget, consistent with PremiumPill style
// ---------------------------------------------------------------------------
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumPill(
      label: label,
      icon: icon,
      selected: selected,
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Feed — realtime first page + paginated load more
// ---------------------------------------------------------------------------
class _AdoptRescueFeed extends StatefulWidget {
  const _AdoptRescueFeed({super.key, required this.filter});
  // null = all, 'adopt' or 'rescue' = filtered
  final String? filter;

  @override
  State<_AdoptRescueFeed> createState() => _AdoptRescueFeedState();
}

class _AdoptRescueFeedState extends State<_AdoptRescueFeed> {
  static const _pageSize = 20;

  final _db = FirebaseFirestore.instance;
  final _scroll = ScrollController();

  List<PostModel> _posts = [];
  bool _loading = true;
  bool _hasMore = true;
  bool _loadingMore = false;
  String? _error;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _startStream();
  }

  @override
  void didUpdateWidget(covariant _AdoptRescueFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      setState(() {
        _posts = [];
        _loading = true;
        _hasMore = true;
        _loadingMore = false;
        _error = null;
        _lastDoc = null;
      });
      _startStream();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _sub?.cancel();
    super.dispose();
  }

  Query<Map<String, dynamic>> _baseQuery() {
    Query<Map<String, dynamic>> q =
        _db.collection('posts').orderBy('createdAt', descending: true);

    final f = widget.filter;
    if (f == _kAdopt || f == _kRescue) {
      q = q.where('postType', isEqualTo: f);
    } else {
      // Show both adopt and rescue
      q = q.where('postType', whereIn: [_kAdopt, _kRescue]);
    }

    return q.limit(_pageSize);
  }

  void _startStream() {
    _sub?.cancel();
    _sub = _baseQuery().snapshots().listen(
      (snap) {
        if (!mounted) return;
        final docs = snap.docs;
        setState(() {
          _posts = docs
              .map((d) =>
                  PostModel.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
              .toList();
          _loading = false;
          _hasMore = docs.length >= _pageSize;
          _lastDoc = docs.isNotEmpty
              ? docs.last as DocumentSnapshot<Map<String, dynamic>>
              : null;
          _error = null;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      },
    );
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _lastDoc == null) return;
    setState(() => _loadingMore = true);
    try {
      final snap = await _baseQuery().startAfterDocument(_lastDoc!).get();
      if (!mounted) return;
      final ids = _posts.map((p) => p.id).toSet();
      final more = snap.docs
          .map((d) =>
              PostModel.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
          .where((p) => !ids.contains(p.id))
          .toList();
      setState(() {
        _posts.addAll(more);
        _hasMore = snap.docs.length >= _pageSize;
        if (snap.docs.isNotEmpty) {
          _lastDoc = snap.docs.last as DocumentSnapshot<Map<String, dynamic>>;
        }
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SkeletonPulse(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => _SkeletonCard(),
        ),
      );
    }

    if (_error != null) {
      return AppErrorStateCard(errorText: _error!, onRetry: _startStream);
    }

    if (_posts.isEmpty) {
      return AppEmptyStateCard(
        icon: Icons.favorite_border_rounded,
        title: widget.filter == _kRescue
            ? 'No rescue posts yet'
            : widget.filter == _kAdopt
                ? 'No adoption posts yet'
                : 'No posts yet',
        subtitle: 'Be the first to share an adoption or rescue post.\n'
            'When creating a post, select the "Adopt" or "Rescue" type.',
      );
    }

    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      itemCount: _posts.length + (_loadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        if (i == _posts.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _AdoptRescueCard(post: _posts[i]);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Card
// ---------------------------------------------------------------------------
class _AdoptRescueCard extends StatelessWidget {
  const _AdoptRescueCard({required this.post});
  final PostModel post;

  bool get _isMine =>
      FirebaseAuth.instance.currentUser?.uid == post.authorId;

  bool get _isRescue => post.postType == _kRescue;

  Color get _typeColor =>
      _isRescue ? const Color(0xFFE86C4F) : const Color(0xFFD94F70);

  Color get _typeBg =>
      _isRescue ? const Color(0xFFFFECE7) : const Color(0xFFFFE8EC);

  String get _typeLabel => _isRescue ? 'Rescue' : 'Adopt';

  IconData get _typeIcon =>
      _isRescue ? Icons.campaign_rounded : Icons.favorite_rounded;

  String _safeUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('//')) url = 'https:$url';
    if (url.startsWith('http://')) url = 'https://${url.substring(7)}';
    url = url.replaceAll(' ', '%20');
    if (url.contains('res.cloudinary.com') && url.contains('/image/upload/')) {
      final split = url.split('/image/upload/');
      if (split.length == 2) {
        final rest = split[1];
        if (!(rest.startsWith('f_') ||
            rest.startsWith('q_') ||
            rest.startsWith('c_'))) {
          url = '${split[0]}/image/upload/f_jpg,q_auto,w_800/$rest';
        }
      }
    }
    try {
      url = Uri.encodeFull(url);
    } catch (_) {}
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final urls =
        post.imageUrls.map(_safeUrl).where((u) => u.isNotEmpty).toList();
    final created = AppDateFmt.dMyHm(post.createdAt);

    return PremiumCardSurface(
      radius: BorderRadius.circular(28),
      padding: EdgeInsets.zero,
      shadowOpacity: 0.13,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
            child: Row(
              children: [
                UserAvatar(
                  uid: post.authorId,
                  radius: 20,
                  fallbackName: post.authorName,
                  fallbackPhotoUrl: (post.authorPhotoUrl ?? '').isEmpty
                      ? null
                      : _safeUrl(post.authorPhotoUrl!),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(uid: post.authorId),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserName(
                        uid: post.authorId,
                        fallback: post.authorName,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.8,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        created.isEmpty ? 'Community post' : created,
                        style: TextStyle(
                          color: AppTheme.muted.withAlpha(210),
                          fontWeight: FontWeight.w800,
                          fontSize: 11.2,
                        ),
                      ),
                    ],
                  ),
                ),
                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _typeBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _typeColor.withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_typeIcon, size: 13, color: _typeColor),
                      const SizedBox(width: 5),
                      Text(
                        _typeLabel,
                        style: TextStyle(
                          color: _typeColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 11.4,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Photo ---
          if (urls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: CachedNetworkImage(
                    imageUrl: urls.first,
                    fit: BoxFit.cover,
                    memCacheWidth: 800,
                    memCacheHeight: 600,
                    placeholder: (_, __) => Container(
                      color: AppTheme.mist,
                      child: const Center(
                        child: Icon(Icons.pets_rounded,
                            color: AppTheme.outline, size: 40),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.mist,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: AppTheme.muted),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // --- Text ---
          if (post.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                post.text.trim(),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  fontSize: 14.2,
                ),
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Divider(height: 1, color: AppTheme.outline),
          ),

          _CardActions(post: post, isMine: _isMine),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card actions — like + "I can help" DM
// ---------------------------------------------------------------------------
class _CardActions extends StatelessWidget {
  const _CardActions({required this.post, required this.isMine});
  final PostModel post;
  final bool isMine;

  Future<void> _contactPoster(BuildContext context) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    if (me.uid == post.authorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("That's your own post.")),
      );
      return;
    }

    try {
      // ensureDm checks follow status and creates/gets conversation
      await MessagesRepository.instance.ensureDm(
        otherUid: post.authorId,
        otherName: post.authorName,
        otherPhoto: post.authorPhotoUrl,
      );

      if (!context.mounted) return;

      // Navigate to ChatPage with the poster's info
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            otherUid: post.authorId,
            otherName: post.authorName,
            otherPhoto: post.authorPhotoUrl,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Row(
        children: [
          // Like button
          StreamBuilder<bool>(
            stream: PostsRepository.instance.streamIsLiked(post.id),
            builder: (ctx, snap) {
              final liked = snap.data ?? false;
              return GestureDetector(
                onTap: () => PostsRepository.instance.toggleLike(post.id),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18,
                      color:
                          liked ? const Color(0xFFD94F70) : AppTheme.muted,
                    ),
                    if (post.likeCount > 0) ...[
                      const SizedBox(width: 5),
                      Text(
                        '${post.likeCount}',
                        style: TextStyle(
                          color: liked
                              ? const Color(0xFFD94F70)
                              : AppTheme.muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const Spacer(),
          // "I can help" button — only shown to other users
          if (!isMine)
            GestureDetector(
              onTap: () => _contactPoster(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8EC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: const Color(0xFFD94F70).withAlpha(60)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 14, color: Color(0xFFD94F70)),
                    SizedBox(width: 6),
                    Text(
                      'I can help',
                      style: TextStyle(
                        color: Color(0xFFD94F70),
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton card
// ---------------------------------------------------------------------------
class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PremiumCardSurface(
      radius: BorderRadius.circular(28),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 40, height: 40, radius: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 130, height: 12),
                    const SizedBox(height: 6),
                    SkeletonBox(width: 90, height: 10),
                  ],
                ),
              ),
              SkeletonBox(width: 62, height: 26, radius: 999),
            ],
          ),
          const SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 190),
          const SizedBox(height: 12),
          SkeletonBox(width: double.infinity, height: 14),
          const SizedBox(height: 6),
          SkeletonBox(width: 210, height: 14),
        ],
      ),
    );
  }
}
