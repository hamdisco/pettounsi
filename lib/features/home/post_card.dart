import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/date_formatters.dart';
import '../../repositories/block_repository.dart';
import '../../ui/adaptive_cached_image.dart';
import '../../ui/app_theme.dart';
import '../../ui/premium_cards.dart';
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
    final createdLabel = AppDateFmt.dMyHm(post.createdAt);
    final normalizedUrls = post.imageUrls
        .map(_safeMediaUrl)
        .where((e) => e.isNotEmpty)
        .toList();

    return PremiumCardSurface(
      radius: BorderRadius.circular(28),
      padding: EdgeInsets.zero,
      shadowOpacity: 0.14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(post: post, createdLabel: createdLabel, isMine: _isMine),
          if (post.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                post.text.trim(),
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w700,
                  height: 1.32,
                  fontSize: 14.2,
                ),
              ),
            ),
          if (normalizedUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Divider(height: 1, color: AppTheme.outline),
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
  });

  final PostModel post;
  final String createdLabel;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final photoFallback = (post.authorPhotoUrl ?? '').trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      child: Row(
        children: [
          UserAvatar(
            uid: post.authorId,
            radius: 20,
            fallbackName: post.authorName,
            fallbackPhotoUrl: photoFallback.isEmpty
                ? null
                : _safeMediaUrl(photoFallback),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(uid: post.authorId),
              ),
            ),
          ),
          const SizedBox(width: 10),
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
                  const SizedBox(height: 4),
                  Text(
                    createdLabel.isEmpty
                        ? 'Community update'
                        : ' $createdLabel',
                    style: TextStyle(
                      color: AppTheme.muted.withAlpha(210),
                      fontWeight: FontWeight.w800,
                      fontSize: 11.4,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if ((post.postType ?? '').isNotEmpty) ...[
            const SizedBox(width: 6),
            _PostTypeBadge(postType: post.postType!),
          ],
          _MenuButton(post: post, isMine: isMine),
        ],
      ),
    );
  }
}

/// Small pill badge shown in the post header for adopt / rescue posts.
class _PostTypeBadge extends StatelessWidget {
  const _PostTypeBadge({required this.postType});
  final String postType;

  bool get _isRescue => postType == 'rescue';

  Color get _bg =>
      _isRescue ? const Color(0xFFFFECE7) : const Color(0xFFFFE8EC);
  Color get _fg =>
      _isRescue ? const Color(0xFFE86C4F) : const Color(0xFFD94F70);
  IconData get _icon =>
      _isRescue ? Icons.campaign_rounded : Icons.favorite_rounded;
  String get _label => _isRescue ? 'Rescue' : 'Adopt';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _fg.withAlpha(55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: _fg),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: _fg,
              fontWeight: FontWeight.w900,
              fontSize: 10.8,
              height: 1,
            ),
          ),
        ],
      ),
    );
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
          items.add(
            const PopupMenuItem(value: 'report', child: Text('Report')),
          );
          items.add(
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
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
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
                fontWeight: FontWeight.w800,
                height: 1.15,
              );

              if ((likerUid ?? '').trim().isEmpty) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.likeCount == 1
                            ? 'Liked by 1 person'
                            : 'Liked by ${post.likeCount} people',
                        style: labelStyle,
                      ),
                    ),
                    const SizedBox.shrink(),
                  ],
                );
              }

              final likerId = likerUid!.trim();

              return Row(
                children: [
                  Expanded(
                    child: Wrap(
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
                    ),
                  ),
                  const SizedBox.shrink(),
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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.64,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.outline,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.lilac,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFE85D7A),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Likes',
                            style: TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            post.likeCount == 1
                                ? '1 person liked this post'
                                : '${post.likeCount} people liked this post',
                            style: TextStyle(
                              color: AppTheme.muted.withAlpha(220),
                              fontWeight: FontWeight.w700,
                              fontSize: 12.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
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
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Divider(height: 1, color: AppTheme.outline),
              ),
              Expanded(
                child: StreamBuilder<List<String>>(
                  stream: PostsRepository.instance.streamRecentLikerUids(
                    post.id,
                  ),
                  builder: (context, snap) {
                    final likerUids = snap.data ?? const <String>[];
                    if (likerUids.isEmpty) {
                      return Center(
                        child: Text(
                          'No likes yet.',
                          style: TextStyle(
                            color: AppTheme.muted.withAlpha(220),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      itemCount: likerUids.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final uid = likerUids[index];
                        return _LikeUserTile(uid: uid);
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

class _LikeUserTile extends StatelessWidget {
  const _LikeUserTile({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfilePage(uid: uid)),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Row(
            children: [
              UserAvatar(uid: uid, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: UserName(
                  uid: uid,
                  fallback: 'User',
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.2,
                  ),
                ),
              ),
              const SizedBox.shrink(),
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
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
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
                  accent: liked
                      ? const Color(0xFFE85D7A)
                      : const Color(0xFF7C62D7),
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
          const SizedBox(width: 8),
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
      color: selected ? const Color(0xFFFFEEF4) : AppTheme.mist,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? const Color(0xFFFFD6E2) : AppTheme.outline,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.white.withAlpha(220),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFFFD6E2)
                        : AppTheme.outline,
                  ),
                ),
                child: Icon(icon, color: accent, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.ink.withAlpha(210),
                    fontWeight: FontWeight.w900,
                    fontSize: 12.2,
                    height: 1.0,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Text(
                  count,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 11.4,
                    height: 1.0,
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

class _PostMediaGrid extends StatelessWidget {
  const _PostMediaGrid({required this.urls, required this.onOpen});
  final List<String> urls;
  final void Function(int index) onOpen;

  @override
  Widget build(BuildContext context) {
    final count = urls.length;
    if (count <= 0) return const SizedBox.shrink();

    if (count == 1) {
      return _MediaTile(
        url: urls.first,
        borderRadius: BorderRadius.circular(24),
        onTap: () => onOpen(0),
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
          return _MediaTile(
            url: urls[i],
            borderRadius: BorderRadius.circular(20),
            onTap: () => onOpen(i),
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
            placeholder: Container(
              decoration: BoxDecoration(color: AppTheme.outline.withAlpha(70)),
            ),
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
