import 'dart:io';
import '../../ui/premium_cards.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/media_presets.dart';

import '../../repositories/block_repository.dart';
import '../../repositories/follow_repository.dart';
import '../../services/cloudinary_service.dart';
import '../../ui/app_theme.dart';
import '../../ui/skeleton.dart';
import '../follow/followers_page.dart';
import '../follow/following_page.dart';
import '../home/post_card.dart';
import '../home/post_model.dart';
import '../home/posts_repository.dart';
import '../messages/chat_page.dart';
import '../moderation/report_sheet.dart';
import '../../ui/premium_feedback.dart';
import '../../ui/premium_sections.dart';

// --- Media URL normalization ---
// Keeps UI unchanged. Fixes release-only failures due to unsafe URL characters,
// protocol-relative URLs, or http links stored in Firestore.
String _safeMediaUrl(String raw) {
  var url = raw.trim();
  if (url.isEmpty) return '';
  if (url.startsWith('//')) url = 'https:$url';
  if (url.startsWith('http://')) url = 'https://${url.substring(7)}';
  url = url.replaceAll(' ', '%20');

  // Cloudinary: force a universally-decodable output format to avoid device-specific decode issues.
  // Insert f_jpg,q_auto right after /image/upload/ when possible.
  if (url.contains('res.cloudinary.com') && url.contains('/image/upload/')) {
    final split = url.split('/image/upload/');
    if (split.length == 2) {
      final prefix = split[0];
      final rest = split[1];
      // If rest already starts with a transform chain, don't duplicate.
      if (!(rest.startsWith('f_') ||
          rest.startsWith('q_') ||
          rest.startsWith('c_'))) {
        url = '$prefix/image/upload/f_jpg,q_auto/$rest';
      }
    }
  }

  // Make sure it's a valid URI string (encodes remaining unsafe chars).
  try {
    url = Uri.encodeFull(url);
  } catch (_) {}

  return url;
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    final isMe = (me != null && me == uid);

    return StreamBuilder<Set<String>>(
      stream: BlockRepository.instance.streamBlockedUids(),
      builder: (context, bSnap) {
        final blocked = bSnap.data ?? {};
        final isBlocked = blocked.contains(uid);

        return Scaffold(
          backgroundColor: AppTheme.bg,
          body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (context, uSnap) {
              final data = uSnap.data?.data() ?? {};
              final username = (data['username'] as String?)?.trim() ?? 'User';
              final bio = (data['bio'] as String?)?.trim() ?? '';
              final phone = (data['phone'] as String?)?.trim() ?? '';
              final showPhone = (data['showPhone'] as bool?) ?? true;

              final photoUrl = _safeMediaUrl(
                (data['photoUrl'] as String?) ?? '',
              );
              // ✅ FIX: cover is NOT the same as profile photo
              final coverPhotoUrl = _safeMediaUrl(
                (data['coverPhotoUrl'] as String?) ?? '',
              );

              // Stream once so we can show posts count + list.
              final postsStream = PostsRepository.instance.streamByAuthor(
                uid,
                limit: 60,
              );

              return StreamBuilder<List<PostModel>>(
                stream: postsStream,
                builder: (context, pSnap) {
                  final posts = pSnap.data ?? const <PostModel>[];

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                    children: [
                      _PremiumProfileHeader(
                        uid: uid,
                        isMe: isMe,
                        isBlocked: isBlocked,
                        username: username,
                        bio: bio,
                        phone: phone,
                        showPhone: showPhone,
                        photoUrl: photoUrl,
                        coverPhotoUrl: coverPhotoUrl,
                        postsCount: posts.length,
                        onEdit: isMe
                            ? () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => Container(
                                    decoration: const BoxDecoration(
                                      color: AppTheme.bg,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(28),
                                      ),
                                    ),
                                    child: _EditProfileSheet(uid: uid),
                                  ),
                                );
                              }
                            : null,
                      ),

                      const SizedBox(height: 12),

                      if (!isMe && isBlocked) ...[
                        _BlockedNoticeCard(
                          onUnblock: () =>
                              BlockRepository.instance.unblock(uid),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (isMe || !isBlocked) ...[
                        _PostsSectionHeader(isMe: isMe),
                        const SizedBox(height: 10),

                        if (!pSnap.hasData) const _PostsLoadingState(),

                        if (pSnap.hasData && posts.isEmpty)
                          _EmptyPostsCard(isMe: isMe),

                        if (pSnap.hasData && posts.isNotEmpty)
                          Column(
                            children: [
                              for (final p in posts) ...[
                                PostCard(post: p),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _PremiumProfileHeader extends StatelessWidget {
  const _PremiumProfileHeader({
    required this.uid,
    required this.isMe,
    required this.isBlocked,
    required this.username,
    required this.bio,
    required this.phone,
    required this.showPhone,
    required this.photoUrl,
    required this.coverPhotoUrl,
    required this.postsCount,
    this.onEdit,
  });

  final String uid;
  final bool isMe;
  final bool isBlocked;
  final String username;
  final String bio;
  final String phone;
  final bool showPhone;
  final String photoUrl;
  final String coverPhotoUrl;
  final int postsCount;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final title = username.isEmpty ? 'User' : username;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.outline),
        color: Colors.white.withAlpha(245),
        boxShadow: AppTheme.softShadows(0.55),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Column(
          children: [
            SizedBox(
              height: 168,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: _Cover(url: coverPhotoUrl, seed: uid),
                  ),

                  // soft overlay for readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withAlpha(18),
                            Colors.white.withAlpha(120),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // top actions
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Row(
                      children: [
                        if (canPop)
                          _GlassIcon(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.of(context).maybePop(),
                            tooltip: 'Back',
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Row(
                      children: [
                        if (!isMe)
                          _GlassIcon(
                            icon: Icons.more_horiz_rounded,
                            onTap: () => _openProfileActionsSheet(
                              context,
                              uid: uid,
                              isBlocked: isBlocked,
                            ),
                            tooltip: 'More',
                          ),
                        if (isMe)
                          _GlassIcon(
                            icon: Icons.edit_rounded,
                            onTap: onEdit,
                            tooltip: 'Edit profile',
                          ),
                      ],
                    ),
                  ),

                  // avatar
                  Positioned(
                    left: 14,
                    bottom: -28,
                    child: _Avatar(
                      photoUrl: photoUrl,
                      username: username,
                      size: 92,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 36, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppTheme.ink,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (bio.isNotEmpty)
                    Text(
                      bio,
                      style: TextStyle(
                        color: AppTheme.ink.withAlpha(185),
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    )
                  else
                    Text(
                      isMe
                          ? 'Add a short bio to help people know you.'
                          : 'No bio yet',
                      style: TextStyle(
                        color: AppTheme.muted.withAlpha(220),
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                  if (showPhone && phone.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _ContactChip(phone: phone),
                  ],

                  const SizedBox(height: 12),

                  // stats row (IG-like)
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          value: postsCount,
                          label: 'Posts',
                          onTap: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatStream(
                          label: 'Followers',
                          stream: FollowRepository.instance
                              .streamFollowersCount(uid),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowersPage(uid: uid),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatStream(
                          label: 'Following',
                          stream: FollowRepository.instance
                              .streamFollowingCount(uid),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowingPage(uid: uid),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // actions row (Follow + Message like Instagram)
                  if (isMe)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Edit profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.orange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    )
                  else
                    _FollowAndMessageRow(
                      targetUid: uid,
                      targetName: username,
                      targetPhoto: photoUrl,
                      disabled: isBlocked,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openProfileActionsSheet(
  BuildContext context, {
  required String uid,
  required bool isBlocked,
}) async {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: const BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(30),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Options',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              _SheetTile(
                icon: Icons.flag_rounded,
                title: 'Report user',
                subtitle: 'Tell us what’s going on',
                danger: true,
                onTap: () async {
                  Navigator.pop(ctx);
                  await showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.bg,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(26),
                        ),
                      ),
                      child: ReportSheet(type: 'user', targetUid: uid),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              _SheetTile(
                icon: isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                title: isBlocked ? 'Unblock' : 'Block',
                subtitle: isBlocked
                    ? 'You will be able to see posts and chat again'
                    : 'Hide posts and prevent chat',
                danger: !isBlocked,
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    if (isBlocked) {
                      await BlockRepository.instance.unblock(uid);
                    } else {
                      await BlockRepository.instance.block(uid);
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url, required this.seed});
  final String url;
  final String seed;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF1E8), Color(0xFFF4EEFF), Color(0xFFEEF7FF)],
          ),
        ),
        child: Align(
          alignment: const Alignment(0.9, -0.7),
          child: Icon(
            Icons.pets_rounded,
            size: 72,
            color: AppTheme.ink.withAlpha(30),
          ),
        ),
      );
    }

    final placeholder = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF1E8), Color(0xFFF4EEFF), Color(0xFFEEF7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );

    if (kReleaseMode) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        alignment: const Alignment(0.0, -0.2),
        headers: const {'User-Agent': 'Mozilla/5.0'},
        errorBuilder: (context, error, stack) {
          debugPrint('[IMG_FAIL][cover] $url -> $error');
          return placeholder;
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder;
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      alignment: const Alignment(0.0, -0.2),
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => placeholder,
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.photoUrl,
    required this.username,
    this.size = 84,
  });

  final String photoUrl;
  final String username;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = username.isEmpty ? 'U' : username[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD6C9), Color(0xFFF0E9FF), Color(0xFFEEF7FF)],
        ),
        border: Border.all(color: Colors.white),
        boxShadow: AppTheme.softShadows(0.12),
      ),
      child: ClipOval(
        child: Container(
          color: Colors.white,
          child: photoUrl.isEmpty
              ? Center(
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      color: AppTheme.ink,
                    ),
                  ),
                )
              : (kReleaseMode
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        headers: const {'User-Agent': 'Mozilla/5.0'},
                        errorBuilder: (context, error, stack) {
                          debugPrint('[IMG_FAIL][avatar] $photoUrl -> $error');
                          return Center(
                            child: Text(
                              letter,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                                color: AppTheme.ink,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: Text(
                              letter,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                                color: AppTheme.ink,
                              ),
                            ),
                          );
                        },
                      )
                    : CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 180),
                        errorWidget: (_, __, ___) => Center(
                          child: Text(
                            letter,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),
                      )),
        ),
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  const _GlassIcon({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(220),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white),
            boxShadow: AppTheme.softShadows(0.10),
          ),
          child: Icon(icon, color: AppTheme.ink.withAlpha(190), size: 20),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.text,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 11.2,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({required this.phone});
  final String phone;

  @override
  Widget build(BuildContext context) {
    return PremiumCardBadge(
      label: phone,
      icon: Icons.phone_rounded,
      bg: AppTheme.mist,
      fg: const Color(0xFF6B56C9),
      borderColor: AppTheme.outline,
      fontSize: 11.8,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.onTap});
  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCardSurface(
      onTap: onTap,
      radius: BorderRadius.circular(18),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      shadowOpacity: 0.06,
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: AppTheme.ink,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.ink.withAlpha(165),
              fontWeight: FontWeight.w800,
              fontSize: 11.6,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatStream extends StatelessWidget {
  const _StatStream({
    required this.label,
    required this.stream,
    required this.onTap,
  });

  final String label;
  final Stream<int> stream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snap) {
        final v = snap.data ?? 0;
        return _Stat(value: v, label: label, onTap: onTap);
      },
    );
  }
}

class _FollowAndMessageRow extends StatelessWidget {
  const _FollowAndMessageRow({
    required this.targetUid,
    required this.targetName,
    required this.targetPhoto,
    required this.disabled,
  });

  final String targetUid;
  final String targetName;
  final String targetPhoto;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FollowRepository.instance.streamIsFollowing(targetUid),
      builder: (context, snap) {
        final isFollowing = snap.data ?? false;

        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: disabled
                    ? null
                    : () async {
                        try {
                          if (isFollowing) {
                            await FollowRepository.instance.unfollow(targetUid);
                          } else {
                            await FollowRepository.instance.follow(
                              targetUid: targetUid,
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      },
                icon: Icon(
                  isFollowing
                      ? Icons.check_rounded
                      : Icons.person_add_alt_1_rounded,
                  size: 18,
                ),
                label: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing
                      ? AppTheme.lilac
                      : AppTheme.orange,
                  foregroundColor: isFollowing
                      ? const Color(0xFF6B56C9)
                      : Colors.white,
                  elevation: 0,
                  side: isFollowing
                      ? BorderSide(color: AppTheme.outline)
                      : BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (!disabled && isFollowing)
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              otherUid: targetUid,
                              otherName: targetName,
                              otherPhoto: targetPhoto.isEmpty
                                  ? null
                                  : targetPhoto,
                            ),
                          ),
                        );
                      }
                    : () {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Follow this user to send a message.',
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                label: const Text(
                  'Message',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.ink,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: AppTheme.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BlockedNoticeCard extends StatelessWidget {
  const _BlockedNoticeCard({required this.onUnblock});
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return PremiumCardSurface(
      radius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(14),
      shadowOpacity: 0.10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFEF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.block_rounded,
                  color: Color(0xFFD64545),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Blocked user',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'You blocked this user. Unblock to view their posts or start chatting again.',
            style: TextStyle(
              color: AppTheme.ink.withAlpha(175),
              fontWeight: FontWeight.w700,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onUnblock,
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('Unblock'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? const Color(0xFFD64545) : AppTheme.ink;
    final bg = danger ? const Color(0xFFFFF1F1) : Colors.white.withAlpha(245);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.outline),
          boxShadow: AppTheme.softShadows(0.18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: danger ? const Color(0xFFFFE9E9) : AppTheme.lilac,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: fg, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.w900, color: fg),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.ink.withAlpha(150),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: fg.withAlpha(140)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Posts section ----

class _PostsSectionHeader extends StatelessWidget {
  const _PostsSectionHeader({required this.isMe});
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return PremiumCardSurface(
      radius: BorderRadius.circular(22),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      shadowOpacity: 0.08,
      child: PremiumSectionHeader(
        title: isMe ? 'My posts' : 'Posts',
        subtitle: isMe
            ? 'Your latest updates and photo posts.'
            : 'Recent updates shared on this profile.',
        compact: true,
        trailing: const PremiumCardBadge(
          label: 'Latest',
          bg: AppTheme.lilac,
          fg: Color(0xFF6B56C9),
        ),
      ),
    );
  }
}

class _PostsLoadingState extends StatelessWidget {
  const _PostsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SkeletonPostCard(),
        SkeletonPostCard(showImage: false),
        SkeletonPostCard(),
      ],
    );
  }
}

class _EmptyPostsCard extends StatelessWidget {
  const _EmptyPostsCard({required this.isMe});
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return PremiumEmptyStateCard(
      icon: Icons.post_add_rounded,
      iconColor: AppTheme.orangeDark,
      iconBg: const Color(0xFFFFF1E8),
      title: isMe ? 'You haven’t posted yet' : 'No posts yet',
      subtitle: isMe
          ? 'Create your first post to start sharing updates.'
          : 'This user has not published any posts yet.',
      compact: true,
    );
  }
}

// ---- Edit Profile Sheet ----

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.uid});
  final String uid;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _username = TextEditingController();
  final _bio = TextEditingController();
  final _phone = TextEditingController();

  bool _loading = false;
  String? _photoUrl;
  String? _coverUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get();
    final d = doc.data() ?? {};
    _username.text = (d['username'] ?? '') as String;
    _bio.text = (d['bio'] ?? '') as String;
    _phone.text = (d['phone'] ?? '') as String;
    setState(() {
      _photoUrl = (d['photoUrl'] as String?)?.trim();
      _coverUrl = (d['coverPhotoUrl'] as String?)?.trim();
    });
  }

  @override
  void dispose() {
    _username.dispose();
    _bio.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<String?> _pickAndUpload({required SocialImageKind kind}) async {
    final XFile? x;
    try {
      final picker = ImagePicker();
      final p = MediaPresets.forKind(kind);
      x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: p.quality,
        maxWidth: p.maxWidth,
        maxHeight: p.maxHeight,
      );
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open photos: $e')));
      return null;
    }
    if (x == null) return null;

    setState(() => _loading = true);
    try {
      final uploaded = await CloudinaryService.instance.uploadImage(
        File(x.path),
      );
      return uploaded.secureUrl;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      return null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeAvatar() async {
    final url = await _pickAndUpload(kind: SocialImageKind.avatar);
    if (url == null) return;
    setState(() => _photoUrl = url);
  }

  Future<void> _changeCover() async {
    final url = await _pickAndUpload(kind: SocialImageKind.cover);
    if (url == null) return;
    setState(() => _coverUrl = url);
  }

  Future<void> _save() async {
    final u = _username.text.trim();
    final b = _bio.text.trim();
    final p = _phone.text.trim();

    setState(() => _loading = true);
    try {
      final update = <String, dynamic>{
        'username': u,
        'bio': b,
        'phone': p,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      // Only write media fields if we actually have a value.
      // This prevents accidentally wiping existing URLs when the sheet loads slowly.
      if (_photoUrl != null && _photoUrl!.trim().isNotEmpty) {
        update['photoUrl'] = _photoUrl!.trim();
      }
      if (_coverUrl != null && _coverUrl!.trim().isNotEmpty) {
        update['coverPhotoUrl'] = _coverUrl!.trim();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .set(update, SetOptions(merge: true));

      final me = FirebaseAuth.instance.currentUser;
      if (me != null) {
        if (u.isNotEmpty) await me.updateDisplayName(u);
        if ((_photoUrl ?? '').trim().isNotEmpty) {
          await me.updatePhotoURL(_photoUrl!.trim());
        }
        // Ensures UI that reads currentUser is refreshed (drawer/home composer, etc.)
        await me.reload();
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(30),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                const Text(
                  'Edit profile',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(240),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Column(
                children: [
                  // cover preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: _Cover(
                        url: (_coverUrl ?? '').trim(),
                        seed: widget.uid,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      _Avatar(
                        photoUrl: (_photoUrl ?? '').trim(),
                        username: _username.text.trim(),
                        size: 64,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _loading ? null : _changeAvatar,
                                icon: const Icon(Icons.person_rounded),
                                label: const Text('Change photo'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _loading ? null : _changeCover,
                                icon: const Icon(Icons.image_rounded),
                                label: const Text('Change cover'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _username,
              decoration: const InputDecoration(
                hintText: 'Username',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _bio,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Bio',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _phone,
              decoration: const InputDecoration(
                hintText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _save,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_loading ? 'Saving...' : 'Save changes'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
