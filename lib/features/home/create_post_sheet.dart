import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../ui/app_theme.dart';
import '../../ui/premium_cards.dart';
import '../../ui/premium_pills.dart';
import '../../ui/premium_sheet.dart';
import '../../ui/user_avatar.dart';
import 'posts_repository.dart';

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({super.key, this.initialImages = const []});
  final List<File> initialImages;

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  static const int _maxImages = 4;
  static const int _maxText = 2000;

  final _txt = TextEditingController();
  final List<File> _images = [];

  bool _loading = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _images.addAll(widget.initialImages.take(_maxImages));
    _txt.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _txt.removeListener(_handleTextChanged);
    _txt.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickFromGallery() async {
    if (_loading || _images.length >= _maxImages) return;

    final picker = ImagePicker();
    try {
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (x == null || !mounted) return;

      setState(() => _images.add(File(x.path)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open gallery: $e')));
    }
  }

  Future<void> _cameraAdd() async {
    if (_loading || _images.length >= _maxImages) return;

    final picker = ImagePicker();
    try {
      final x = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (x == null || !mounted) return;

      setState(() => _images.add(File(x.path)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open camera: $e')));
    }
  }

  Future<void> _submit() async {
    final text = _txt.text.trim();
    if (_loading) return;
    if (text.isEmpty && _images.isEmpty) return;

    setState(() => _loading = true);
    try {
      final postId = FirebaseFirestore.instance.collection('posts').doc().id;
      final clientCreatedAt = DateTime.now();

      await PostsRepository.instance.createPost(
        text: text,
        imageFiles: _images,
        postId: postId,
        clientCreatedAt: clientCreatedAt,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not publish: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _maxText - _txt.text.characters.length;
    final canPost =
        !_loading &&
        remaining >= 0 &&
        (_txt.text.trim().isNotEmpty || _images.isNotEmpty);

    return PremiumBottomSheetFrame(
      icon: Icons.edit_note_rounded,
      iconColor: const Color(0xFF7C62D7),
      iconBg: AppTheme.lilac,
      title: 'Create post',
      subtitle: 'Add text or photos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ComposerCard(
            uid: _uid,
            remaining: remaining,
            controller: _txt,
            images: _images,
            loading: _loading,
            onRemoveImage: (i) => setState(() => _images.removeAt(i)),
            onPickGallery: _pickFromGallery,
            onPickCamera: _cameraAdd,
          ),
          const SizedBox(height: 12),
          const PremiumSheetInfoCard(
            icon: Icons.public_rounded,
            iconBg: AppTheme.sky,
            iconFg: Color(0xFF4C79C8),
            title: 'Public post',
            subtitle:
                'Posts and comments are visible to other users in the app.',
            compact: true,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canPost ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orangeDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'Publish post',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({
    required this.uid,
    required this.remaining,
    required this.controller,
    required this.images,
    required this.loading,
    required this.onRemoveImage,
    required this.onPickGallery,
    required this.onPickCamera,
  });

  final String uid;
  final int remaining;
  final TextEditingController controller;
  final List<File> images;
  final bool loading;
  final void Function(int index) onRemoveImage;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;

  @override
  Widget build(BuildContext context) {
    final maxReached = images.length >= _CreatePostSheetState._maxImages;

    return PremiumCardSurface(
      radius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(14),
      shadowOpacity: 0.10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(uid: uid, radius: 18, fallbackName: 'You'),
              const SizedBox(width: 10),
              Expanded(
                child: UserName(
                  uid: uid,
                  fallback: 'You',
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.6,
                    height: 1,
                  ),
                ),
              ),
              PremiumCardBadge(
                label: remaining < 0 ? '0 left' : '$remaining left',
                icon: Icons.text_fields_rounded,
                bg: remaining < 0 ? const Color(0xFFFFECEC) : AppTheme.blush,
                fg: remaining < 0
                    ? const Color(0xFFD64545)
                    : AppTheme.orangeDark,
                borderColor: AppTheme.outline,
                fontSize: 11.1,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.mist,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.outline),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: TextField(
              controller: controller,
              minLines: 4,
              maxLines: 8,
              maxLength: _CreatePostSheetState._maxText,
              enabled: !loading,
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w700,
                height: 1.28,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: 'Share something helpful, warm, or important…',
                hintStyle: TextStyle(
                  color: AppTheme.muted.withAlpha(200),
                  fontWeight: FontWeight.w700,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.transparent,
                filled: false,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ImageGrid(images: images, onRemove: onRemoveImage),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PremiumPill(
                label: maxReached ? 'Max photos' : 'Add photo',
                icon: Icons.photo_library_rounded,
                onTap: loading || maxReached ? null : onPickGallery,
                selected: false,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              PremiumPill(
                label: maxReached ? 'Limit reached' : 'Camera',
                icon: Icons.photo_camera_rounded,
                onTap: loading || maxReached ? null : onPickCamera,
                selected: false,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              PremiumToneChip(
                label:
                    '${images.length}/${_CreatePostSheetState._maxImages} photos',
                icon: Icons.collections_rounded,
                bg: AppTheme.sky,
                fg: const Color(0xFF4C79C8),
                borderColor: AppTheme.outline,
                fontSize: 11.6,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.images, required this.onRemove});

  final List<File> images;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final itemCount = images.length.clamp(1, 4);

    return GridView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, i) {
        final file = images[i];

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(file, fit: BoxFit.cover),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.white.withAlpha(235),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onRemove(i),
                    child: const SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(Icons.close_rounded, color: AppTheme.ink),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
