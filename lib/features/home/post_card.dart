import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/date_formatters.dart';
import '../../repositories/block_repository.dart';
import '../../ui/adaptive_cached_image.dart';
import '../../ui/app_theme.dart';
import '../../ui/user_avatar.dart';
import '../moderation/report_sheet.dart';
import '../profile/profile_page.dart';
import 'comments_sheet.dart';
import 'image_viewer_page.dart';
import 'post_model.dart';
import 'posts_repository.dart';

String _safeMediaUrl(String raw) {
  var url = raw.trim();
  if (url.isEmpty) return '';
  if (url.startsWith('//')) url = 'https:$url';
  if (url.startsWith('http://')) url = 'https://${url.substring(7)}';
  url = url.replaceAll(' ', '%20');

  if (url.contains('res.cloudinary.com') && url.contains('/image/upload/')) {
    final split = url.split('/image/upload/');
    if (split.length == 2) {
      final prefix = split[0];
      final rest = split[1];
      if (!(rest.startsWith('f_') ||
          rest.startsWith('q_') ||
          rest.startsWith('c_'))) {
        url = '$prefix/image/upload/f_jpg,q_auto/$rest';
      }
    }
  }

  try {
    url = Uri.encodeFull(url);
  } catch (_) {}
  return url;
}

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});

  final PostModel post;

  bool get _isMine => FirebaseAuth.instance.currentUser?.uid == post.authorId;

  @override
  Widget build(BuildContext context) {
    final visual = _PostTypeVisual.fromType(post.postType);
    final createdLabel = AppDateFmt.dMyHm(post.createdAt);
    final normalizedUrls = post.imageUrls
        .map(_safeMediaUrl)
        .where((url) => url.isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: visual.borderColor),
        boxShadow: AppTheme.softShadows(0.075),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (visual.isSpecial)
            Container(height: 4, color: visual.fg.withAlpha(175)),
          _Header(
            post: post,
            createdLabel: createdLabel,
            isMine: _isMine,
            visual: visual,
          ),
          if (post.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                post.text.trim(),
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w600,
                  height: 1.38,
                  fontSize: 14.2,
                ),
              ),
            ),
          if (normalizedUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _PostMediaGrid(
                urls: normalizedUrls,
                onOpen: (index) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImageViewerPage(
                        urls: post.imageUrls,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
              ),
            ),
          if (post.likeCount > 0) _LikeSummaryRow(post: post),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppTheme.outline.withAlpha(210)),
          ),
          _ActionsRow(post: post),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.post,
    required this.createdLabel,
    required this.isMine,
    required this.visual,
  });

  final PostModel post;
  final String createdLabel;
  final bool isMine;
  final _PostTypeVisual visual;

  @override
  Widget build(BuildContext context) {
    final location = post.locationText.trim().isNotEmpty
        ? post.locationText.trim()
        : post.city.trim();
    final metaParts = <String>[
      if (location.isNotEmpty) location,
      if (createdLabel.isNotEmpty) createdLabel,
    ];
    final metaLabel = metaParts.isEmpty
        ? 'Community update'
        : metaParts.join(' • ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            uid: post.authorId,
            radius: 21,
            fallbackName: 'PetTounsi user',
            fallbackPhotoUrl: null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(uid: post.authorId),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(uid: post.authorId),
                ),
              ),
              borderRadius: BorderRadius.circular(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: UserName(
                          uid: post.authorId,
                          fallback: 'PetTounsi user',
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 14.2,
                            height: 1.05,
                          ),
                        ),
                      ),
                      if (visual.isSpecial) ...[
                        const SizedBox(width: 8),
                        _PostTypeBadge(visual: visual),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    metaLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.muted.withAlpha(220),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.0,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _MenuButton(post: post, isMine: isMine),
        ],
      ),
    );
  }
}

class _PostTypeBadge extends StatelessWidget {
  const _PostTypeBadge({required this.visual});

  final _PostTypeVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: visual.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: visual.fg.withAlpha(45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, size: 12, color: visual.fg),
          const SizedBox(width: 4),
          Text(
            visual.label,
            style: TextStyle(
              color: visual.fg,
              fontWeight: FontWeight.w900,
              fontSize: 10.6,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostTypeVisual {
  const _PostTypeVisual({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    this.isSpecial = true,
  });

  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final bool isSpecial;

  Color get borderColor =>
      isSpecial ? fg.withAlpha(36) : AppTheme.outline.withAlpha(210);

  static _PostTypeVisual fromType(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'lost':
        return const _PostTypeVisual(
          label: 'Lost Pet',
          icon: Icons.pets_rounded,
          bg: Color(0xFFF2EEFF),
          fg: Color(0xFF7C62D7),
        );
      case 'found':
        return const _PostTypeVisual(
          label: 'Found',
          icon: Icons.volunteer_activism_rounded,
          bg: Color(0xFFEAF8F0),
          fg: Color(0xFF2BA56E),
        );
      case 'rescue':
        return const _PostTypeVisual(
          label: 'Rescue',
          icon: Icons.campaign_rounded,
          bg: Color(0xFFFFECE7),
          fg: Color(0xFFE86C4F),
        );
      case 'adopt':
        return const _PostTypeVisual(
          label: 'Adopt',
          icon: Icons.favorite_rounded,
          bg: Color(0xFFFFE8EC),
          fg: Color(0xFFD94F70),
        );
      default:
        return const _PostTypeVisual(
          label: 'Post',
          icon: Icons.edit_note_rounded,
          bg: Color(0xFFF8F4FB),
          fg: AppTheme.muted,
          isSpecial: false,
        );
    }
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.post, required this.isMine});

  final PostModel post;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded, color: AppTheme.muted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (v) async {
        if (v == 'profile') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfilePage(uid: post.authorId)),
          );
          return;
        }

        if (v == 'report') {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => ReportSheet(
              type: 'post',
              postId: post.id,
              targetUid: post.authorId,
            ),
          );
          return;
        }

        if (v == 'block') {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Block user?'),
              content: const Text(
                'You will no longer see each other’s content.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Block'),
                ),
              ],
            ),
          );
          if (ok == true) {
            await BlockRepository.instance.block(post.authorId);
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('User blocked')));
            }
          }
          return;
        }

        if (v == 'delete') {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Delete post?'),
              content: const Text('This can’t be undone.'),
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
            await PostsRepository.instance.deletePost(post);
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Post deleted')));
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
          }
          return;
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[
          const PopupMenuItem(value: 'profile', child: Text('View profile')),
        ];
        if (!isMine) {
          items
            ..add(const PopupMenuItem(value: 'report', child: Text('Report')))
            ..add(
              const PopupMenuItem(value: 'block', child: Text('Block user')),
            );
        } else {
          items.add(
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          );
        }
        return items;
      },
    );
  }
}

class _LikeSummaryRow extends StatelessWidget {
  const _LikeSummaryRow({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _PostLikesSheet(post: post),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: StreamBuilder<String?>(
            stream: PostsRepository.instance.streamLatestLikerUid(post.id),
            builder: (context, snap) {
              final likerUid = snap.data;
              final othersCount = (post.likeCount - 1).clamp(0, 1 << 30);
              final labelStyle = TextStyle(
                color: AppTheme.muted.withAlpha(230),
                fontSize: 12.4,
                fontWeight: FontWeight.w700,
                height: 1.15,
              );

              if ((likerUid ?? '').trim().isEmpty) {
                return Text(
                  post.likeCount == 1
                      ? 'Liked by 1 person'
                      : 'Liked by ${post.likeCount} people',
                  style: labelStyle,
                );
              }

              final likerId = likerUid!.trim();

              return Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 0,
                runSpacing: 4,
                children: [
                  Text('Liked by ', style: labelStyle),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(uid: likerId),
                      ),
                    ),
                    child: UserName(
                      uid: likerId,
                      fallback: 'User',
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 12.6,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                  if (othersCount > 0)
                    Text(
                      othersCount == 1
                          ? ' and 1 other'
                          : ' and $othersCount others',
                      style: labelStyle,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PostLikesSheet extends StatelessWidget {
  const _PostLikesSheet({required this.post});

  final PostModel post;

  String get _countLabel {
    if (post.likeCount <= 0) return 'No likes yet';
    if (post.likeCount == 1) return '1 like';
    return '${post.likeCount} likes';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.38,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.outline,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Post likes',
                            style: TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.favorite_rounded,
                                  color: Color(0xFFE85D7A),
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _countLabel,
                                  style: TextStyle(
                                    color: AppTheme.muted.withAlpha(235),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1, color: AppTheme.outline),
              ),
              Expanded(
                child: StreamBuilder<List<String>>(
                  stream: PostsRepository.instance.streamRecentLikerUids(
                    post.id,
                  ),
                  builder: (context, snap) {
                    final likerUids = snap.data ?? const <String>[];

                    if (snap.connectionState == ConnectionState.waiting &&
                        likerUids.isEmpty) {
                      return const _LikesLoadingState();
                    }

                    if (likerUids.isEmpty) {
                      return const _LikesEmptyState();
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                      itemCount: likerUids.length + 1,
                      separatorBuilder: (_, index) {
                        if (index == 0) return const SizedBox(height: 10);
                        return const Padding(
                          padding: EdgeInsets.only(left: 58),
                          child: Divider(height: 1, color: AppTheme.outline),
                        );
                      },
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Text(
                            'People who liked this post',
                            style: TextStyle(
                              color: AppTheme.muted.withAlpha(220),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        }
                        return _LikeUserTile(uid: likerUids[index - 1]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LikesLoadingState extends StatelessWidget {
  const _LikesLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppTheme.outline,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.outline.withAlpha(190),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 90,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.outline.withAlpha(150),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LikesEmptyState extends StatelessWidget {
  const _LikesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.outline),
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                color: AppTheme.muted.withAlpha(180),
                size: 27,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No likes yet',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'People who support this post will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.muted.withAlpha(220),
                fontSize: 12.8,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LikeUserTile extends StatelessWidget {
  const _LikeUserTile({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfilePage(uid: uid)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              UserAvatar(uid: uid, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserName(
                      uid: uid,
                      fallback: 'PetTounsi user',
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.6,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('follows')
                          .doc(uid)
                          .collection('followers')
                          .snapshots(),
                      builder: (context, snap) {
                        final count = snap.data?.size ?? 0;

                        return Text(
                          '$count ${count == 1 ? 'follower' : 'followers'}',
                          style: TextStyle(
                            color: AppTheme.muted.withAlpha(210),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.1,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
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
                child: const Text(
                  'Profile',
                  style: TextStyle(
                    color: AppTheme.orangeDark,
                    fontSize: 11.6,
                    fontWeight: FontWeight.w900,
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

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<bool>(
              stream: PostsRepository.instance.streamIsLiked(post.id),
              builder: (context, snap) {
                final liked = snap.data ?? false;
                return _ActionButton(
                  icon: liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  title: liked ? 'Liked' : 'Like',
                  count: post.likeCount.toString(),
                  selected: liked,
                  accent: liked ? const Color(0xFFE85D7A) : AppTheme.muted,
                  onTap: () async {
                    try {
                      await PostsRepository.instance.toggleLike(post.id);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Like failed: $e')),
                      );
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Comments',
              count: post.commentCount.toString(),
              selected: false,
              accent: const Color(0xFF4C79C8),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CommentsSheet(postId: post.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.title,
    required this.count,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String count;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFEEF4) : const Color(0xFFF9F6F9),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFFD6E2)
                  : AppTheme.outline.withAlpha(210),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.8,
                    height: 1.0,
                  ),
                ),
              ),
              if (count != '0') ...[
                const SizedBox(width: 6),
                Text(
                  count,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.0,
                    height: 1.0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PostMediaGrid extends StatelessWidget {
  const _PostMediaGrid({required this.urls, required this.onOpen});

  final List<String> urls;
  final void Function(int index) onOpen;

  @override
  Widget build(BuildContext context) {
    final count = urls.length;
    if (count <= 0) return const SizedBox.shrink();

    if (count == 1) {
      return AspectRatio(
        aspectRatio: 1.18,
        child: _MediaTile(
          url: urls.first,
          borderRadius: BorderRadius.circular(24),
          onTap: () => onOpen(0),
        ),
      );
    }

    final gridCount = count.clamp(2, 4);

    return SizedBox(
      height: 226,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: gridCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, i) {
          final showMoreOverlay = i == 3 && count > 4;
          return Stack(
            fit: StackFit.expand,
            children: [
              _MediaTile(
                url: urls[i],
                borderRadius: BorderRadius.circular(20),
                onTap: () => onOpen(i),
              ),
              if (showMoreOverlay)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onOpen(i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(96),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+${count - 4}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.url,
    required this.borderRadius,
    required this.onTap,
  });

  final String url;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Material(
        color: AppTheme.outline.withAlpha(60),
        child: InkWell(
          onTap: onTap,
          child: AdaptiveCachedImage(
            imageUrl: url,
            fit: BoxFit.cover,
            maxCacheDimension: 1200,
            placeholder: Container(color: AppTheme.outline.withAlpha(70)),
            errorWidget: Container(
              color: AppTheme.outline.withAlpha(80),
              child: const Center(
                child: Icon(Icons.broken_image_rounded, color: AppTheme.muted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
