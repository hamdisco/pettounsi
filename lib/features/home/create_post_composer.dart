import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/media_presets.dart';
import '../../core/url_utils.dart';
import '../../ui/app_theme.dart';
import '../../ui/premium_cards.dart';
import 'create_post_sheet.dart';

class CreatePostComposer extends StatefulWidget {
  const CreatePostComposer({super.key});

  @override
  State<CreatePostComposer> createState() => _CreatePostComposerState();
}

class _CreatePostComposerState extends State<CreatePostComposer> {
  final _auth = FirebaseAuth.instance;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openSheet({List<File> images = const []}) async {
    final user = _auth.currentUser;
    if (user == null) {
      _toast('Please sign in to create a post.');
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePostSheet(initialImages: images),
    );
  }

  Future<void> _galleryAndOpen() async {
    if (_auth.currentUser == null) {
      _toast('Please sign in to add photos.');
      return;
    }

    try {
      final picker = ImagePicker();
      final p = MediaPresets.forKind(SocialImageKind.post);
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: p.quality,
        maxWidth: p.maxWidth,
        maxHeight: p.maxHeight,
      );
      if (x == null) return;
      await _openSheet(images: [File(x.path)]);
    } catch (e) {
      _toast('Could not open photos: $e');
    }
  }

  Future<void> _cameraAndOpen() async {
    if (_auth.currentUser == null) {
      _toast('Please sign in to use the camera.');
      return;
    }

    try {
      final picker = ImagePicker();
      final p = MediaPresets.forKind(SocialImageKind.post);
      final x = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: p.quality,
        maxWidth: p.maxWidth,
        maxHeight: p.maxHeight,
      );
      if (x == null) return;
      await _openSheet(images: [File(x.path)]);
    } catch (e) {
      _toast('Could not open camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.userChanges(),
      builder: (context, aSnap) {
        final user = aSnap.data;
        if (user == null) {
          return _ComposerCard(
            name: 'New user',
            photoUrl: '',
            onOpen: () => _toast('Please sign in to create a post.'),
            onPhotos: () => _toast('Please sign in to add photos.'),
            onCamera: () => _toast('Please sign in to use the camera.'),
          );
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, uSnap) {
            final d = uSnap.data?.data() ?? {};

            final username = (d['username'] ?? '').toString().trim();
            final authName = (user.displayName ?? '').trim();
            final name = username.isNotEmpty
                ? username
                : (authName.isNotEmpty ? authName : 'You');

            final photoRaw = (d['photoUrl'] ?? user.photoURL ?? '').toString();
            final photo = UrlUtils.normalizeMediaUrl(photoRaw);

            return _ComposerCard(
              name: name,
              photoUrl: photo,
              onOpen: () => _openSheet(),
              onPhotos: _galleryAndOpen,
              onCamera: _cameraAndOpen,
            );
          },
        );
      },
    );
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({
    required this.name,
    required this.photoUrl,
    required this.onOpen,
    required this.onPhotos,
    required this.onCamera,
  });

  final String name;
  final String photoUrl;
  final VoidCallback onOpen;
  final VoidCallback onPhotos;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();

    return PremiumCardSurface(
      radius: BorderRadius.circular(26),
      padding: const EdgeInsets.all(12),
      shadowOpacity: 0.14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(photoUrl: photoUrl, initials: initial),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onOpen,
                  child: Ink(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: AppTheme.mist,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'What\'s on your mind ?',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 13.2,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const PremiumCardBadge(
                          label: 'Write',
                          icon: Icons.edit_rounded,
                          bg: AppTheme.lilac,
                          fg: Color(0xFF6B56C9),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MiniAction(
                        icon: Icons.photo_library_rounded,
                        label: 'Photos',
                        subtitle: 'Gallery',
                        bg: AppTheme.sky,
                        fg: const Color(0xFF4C79C8),
                        onTap: onPhotos,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniAction(
                        icon: Icons.photo_camera_rounded,
                        label: 'Camera',
                        subtitle: 'Capture',
                        bg: AppTheme.mint,
                        fg: const Color(0xFF2F9A6A),
                        onTap: onCamera,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white),
                ),
                child: Icon(icon, size: 18, color: fg),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.3,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.muted.withAlpha(210),
                        fontWeight: FontWeight.w700,
                        fontSize: 11.3,
                        height: 1.0,
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.initials});
  final String photoUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.trim().isNotEmpty;

    return Container(
      width: 46,
      height: 46,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.outline),
      ),
      child: CircleAvatar(
        backgroundColor: AppTheme.lilac,
        backgroundImage: hasPhoto ? NetworkImage(photoUrl.trim()) : null,
        child: !hasPhoto
            ? Text(
                initials.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }
}
