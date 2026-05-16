import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../ui/app_theme.dart';
import '../../ui/user_avatar.dart';
import 'posts_repository.dart';

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({
    super.key,
    this.initialImages = const [],
    this.initialPostType,
  });

  final List<File> initialImages;
  final String? initialPostType;

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  static const int _maxImages = 4;
  static const int _maxText = 2000;

  final _message = TextEditingController();
  final _petName = TextEditingController();
  final _petType = TextEditingController();
  final _city = TextEditingController();
  final _area = TextEditingController();
  final _contact = TextEditingController();
  final _details = TextEditingController();

  final List<File> _images = [];
  bool _loading = false;
  String? _postType;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  _PostTypeSpec get _spec => _PostTypeSpec.fromType(_postType);

  @override
  void initState() {
    super.initState();
    _postType = _normalizeType(widget.initialPostType);
    _images.addAll(widget.initialImages.take(_maxImages));
    for (final c in [_message, _petName, _petType, _city, _area, _contact, _details]) {
      c.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    for (final c in [_message, _petName, _petType, _city, _area, _contact, _details]) {
      c.removeListener(_refresh);
      c.dispose();
    }
    super.dispose();
  }

  String? _normalizeType(String? value) {
    final v = value?.trim().toLowerCase();
    if (v == 'lost' || v == 'found' || v == 'adopt' || v == 'rescue') return v;
    return null;
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _pickFromGallery() async {
    if (_loading || _images.length >= _maxImages) return;
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (x == null || !mounted) return;
      setState(() => _images.add(File(x.path)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open photos: $e')),
      );
    }
  }

  Future<void> _pickFromCamera() async {
    if (_loading || _images.length >= _maxImages) return;
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (x == null || !mounted) return;
      setState(() => _images.add(File(x.path)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open camera: $e')),
      );
    }
  }

  String _composePostText() {
    final lines = <String>[];
    final spec = _spec;

    if (_postType != null) {
      lines.add(spec.headline);
      void add(String label, TextEditingController c) {
        final v = c.text.trim();
        if (v.isNotEmpty) lines.add('$label: $v');
      }

      add('Pet name', _petName);
      add('Pet type', _petType);
      add('City', _city);
      add('Area', _area);
      add(spec.detailLabel, _details);
      add('Contact', _contact);

      final msg = _message.text.trim();
      if (msg.isNotEmpty) {
        lines.add('');
        lines.add(msg);
      }
      return lines.join('\n').trim();
    }

    return _message.text.trim();
  }

  bool get _hasRequiredSpecialFields {
    if (_postType == null) return true;
    return _city.text.trim().isNotEmpty || _area.text.trim().isNotEmpty || _details.text.trim().isNotEmpty;
  }

  bool get _canPublish {
    final text = _composePostText();
    return !_loading &&
        text.characters.length <= _maxText &&
        _hasRequiredSpecialFields &&
        (text.isNotEmpty || _images.isNotEmpty);
  }

  Future<void> _submit() async {
    if (!_canPublish) return;
    setState(() => _loading = true);
    try {
      await PostsRepository.instance.createPost(
        text: _composePostText(),
        imageFiles: _images,
        postId: FirebaseFirestore.instance.collection('posts').doc().id,
        clientCreatedAt: DateTime.now(),
        postType: _postType,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_spec.successMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not publish post: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _maxText - _composePostText().characters.length;
    final spec = _spec;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFBFD),
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
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(context).viewInsets.bottom + 18,
                  ),
                  children: [
                    _SheetHeader(uid: _uid, spec: spec),
                    const SizedBox(height: 18),
                    _TypeSelector(
                      selected: _postType,
                      onChanged: (value) => setState(() => _postType = value),
                    ),
                    const SizedBox(height: 16),
                    if (_postType != null) ...[
                      _SpecialFields(
                        spec: spec,
                        petName: _petName,
                        petType: _petType,
                        city: _city,
                        area: _area,
                        details: _details,
                        contact: _contact,
                      ),
                      const SizedBox(height: 14),
                    ],
                    _MessageBox(controller: _message, spec: spec),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _MediaButton(
                          icon: Icons.photo_library_rounded,
                          label: 'Photos',
                          color: const Color(0xFF4C79C8),
                          background: const Color(0xFFEEF5FF),
                          onTap: _pickFromGallery,
                        ),
                        const SizedBox(width: 10),
                        _MediaButton(
                          icon: Icons.photo_camera_rounded,
                          label: 'Camera',
                          color: const Color(0xFF2F9A6A),
                          background: const Color(0xFFEAF8F0),
                          onTap: _pickFromCamera,
                        ),
                        const Spacer(),
                        _PhotoCounter(count: _images.length, max: _maxImages),
                      ],
                    ),
                    if (_images.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _ImagePreviewGrid(
                        images: _images,
                        onRemove: (index) => setState(() => _images.removeAt(index)),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _SafetyNote(spec: spec),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            remaining < 0 ? 'Too long' : '$remaining characters left',
                            style: TextStyle(
                              color: remaining < 0 ? const Color(0xFFD64545) : AppTheme.muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        ElevatedButton.icon(
                          onPressed: _canPublish ? _submit : null,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(spec.publishIcon, size: 18),
                          label: Text(spec.publishLabel),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: spec.color,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppTheme.outline,
                            disabledForegroundColor: AppTheme.muted,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
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
      },
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.uid, required this.spec});

  final String uid;
  final _PostTypeSpec spec;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: spec.background,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(spec.icon, color: spec.color, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spec.title,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                spec.subtitle,
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.4,
                  height: 1.34,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  UserAvatar(uid: uid, radius: 15, fallbackName: 'You'),
                  const SizedBox(width: 8),
                  const Text(
                    'Public post',
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <_PostTypeSpec>[
      _PostTypeSpec.general,
      _PostTypeSpec.lost,
      _PostTypeSpec.found,
      _PostTypeSpec.adopt,
      _PostTypeSpec.rescue,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What are you sharing?',
          style: TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              _TypeChip(
                spec: item,
                selected: selected == item.value,
                onTap: () => onChanged(item.value),
              ),
          ],
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.spec, required this.selected, required this.onTap});

  final _PostTypeSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? spec.background : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? spec.color.withAlpha(95) : AppTheme.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(spec.icon, size: 15, color: selected ? spec.color : AppTheme.muted),
            const SizedBox(width: 7),
            Text(
              spec.chipLabel,
              style: TextStyle(
                color: selected ? spec.color : AppTheme.ink,
                fontWeight: FontWeight.w900,
                fontSize: 12.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialFields extends StatelessWidget {
  const _SpecialFields({
    required this.spec,
    required this.petName,
    required this.petType,
    required this.city,
    required this.area,
    required this.details,
    required this.contact,
  });

  final _PostTypeSpec spec;
  final TextEditingController petName;
  final TextEditingController petType;
  final TextEditingController city;
  final TextEditingController area;
  final TextEditingController details;
  final TextEditingController contact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _CleanField(
                  controller: petName,
                  label: 'Pet name',
                  hint: spec.petNameHint,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CleanField(
                  controller: petType,
                  label: 'Pet type',
                  hint: 'Cat, dog...',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CleanField(
                  controller: city,
                  label: 'City',
                  hint: 'Tunis',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CleanField(
                  controller: area,
                  label: 'Area',
                  hint: spec.areaHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CleanField(
            controller: details,
            label: spec.detailLabel,
            hint: spec.detailHint,
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          _CleanField(
            controller: contact,
            label: 'Contact option',
            hint: 'Phone, WhatsApp, or message me here',
          ),
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.controller, required this.spec});

  final TextEditingController controller;
  final _PostTypeSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: TextField(
        controller: controller,
        minLines: spec.value == null ? 5 : 3,
        maxLines: 8,
        maxLength: 2000,
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent,
          filled: false,
          contentPadding: EdgeInsets.zero,
          hintText: spec.messageHint,
        ),
        style: const TextStyle(
          color: AppTheme.ink,
          fontWeight: FontWeight.w700,
          fontSize: 14.6,
          height: 1.38,
        ),
      ),
    );
  }
}

class _CleanField extends StatelessWidget {
  const _CleanField({
    required this.controller,
    required this.label,
    required this.hint,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFFFFBFD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.orangeDark, width: 1.3),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(
        color: AppTheme.ink,
        fontWeight: FontWeight.w700,
        fontSize: 13.6,
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  const _MediaButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoCounter extends StatelessWidget {
  const _PhotoCounter({required this.count, required this.max});

  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Text(
        '$count/$max photos',
        style: const TextStyle(
          color: AppTheme.muted,
          fontWeight: FontWeight.w800,
          fontSize: 12.3,
        ),
      ),
    );
  }
}

class _ImagePreviewGrid extends StatelessWidget {
  const _ImagePreviewGrid({required this.images, required this.onRemove});

  final List<File> images;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(images[index], fit: BoxFit.cover),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.white.withAlpha(235),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onRemove(index),
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

class _SafetyNote extends StatelessWidget {
  const _SafetyNote({required this.spec});

  final _PostTypeSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: spec.background.withAlpha(150),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: spec.color.withAlpha(55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: spec.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              spec.safetyNote,
              style: const TextStyle(
                color: AppTheme.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12.7,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostTypeSpec {
  const _PostTypeSpec({
    required this.value,
    required this.chipLabel,
    required this.title,
    required this.subtitle,
    required this.headline,
    required this.messageHint,
    required this.publishLabel,
    required this.successMessage,
    required this.safetyNote,
    required this.icon,
    required this.publishIcon,
    required this.color,
    required this.background,
    required this.petNameHint,
    required this.areaHint,
    required this.detailLabel,
    required this.detailHint,
  });

  final String? value;
  final String chipLabel;
  final String title;
  final String subtitle;
  final String headline;
  final String messageHint;
  final String publishLabel;
  final String successMessage;
  final String safetyNote;
  final IconData icon;
  final IconData publishIcon;
  final Color color;
  final Color background;
  final String petNameHint;
  final String areaHint;
  final String detailLabel;
  final String detailHint;

  static const general = _PostTypeSpec(
    value: null,
    chipLabel: 'General',
    title: 'Create post',
    subtitle: 'Share a pet moment, question, or useful tip.',
    headline: 'Community update',
    messageHint: 'What would you like to share with pet owners?',
    publishLabel: 'Publish',
    successMessage: 'Post published.',
    safetyNote: 'Keep posts respectful and useful. Reports help us protect the community.',
    icon: Icons.edit_note_rounded,
    publishIcon: Icons.send_rounded,
    color: AppTheme.orangeDark,
    background: Color(0xFFFFEFE8),
    petNameHint: 'Miso',
    areaHint: 'Mutuelleville',
    detailLabel: 'Details',
    detailHint: 'Useful details for the community',
  );

  static const lost = _PostTypeSpec(
    value: 'lost',
    chipLabel: 'Lost Pet',
    title: 'Lost pet alert',
    subtitle: 'Help nearby owners recognize and share the alert.',
    headline: 'Lost pet alert',
    messageHint: 'Add any important details: color, behavior, collar, reward...',
    publishLabel: 'Publish alert',
    successMessage: 'Lost pet alert published.',
    safetyNote: 'For safety, avoid sharing private addresses. Use a clear area and contact option.',
    icon: Icons.pets_rounded,
    publishIcon: Icons.campaign_rounded,
    color: Color(0xFF7C62D7),
    background: Color(0xFFF2EEFF),
    petNameHint: 'Miso',
    areaHint: 'Last seen area',
    detailLabel: 'Last seen details',
    detailHint: 'When and where was the pet last seen?',
  );

  static const found = _PostTypeSpec(
    value: 'found',
    chipLabel: 'Found Pet',
    title: 'Found pet post',
    subtitle: 'Share where the pet was found.',
    headline: 'Found pet',
    messageHint: 'Add visible signs, behavior, and how the owner can prove ownership...',
    publishLabel: 'Publish found post',
    successMessage: 'Found pet post published.',
    safetyNote: 'Ask for proof of ownership before handing over a found pet.',
    icon: Icons.volunteer_activism_rounded,
    publishIcon: Icons.volunteer_activism_rounded,
    color: Color(0xFF2BA56E),
    background: Color(0xFFEAF8F0),
    petNameHint: 'Unknown',
    areaHint: 'Found area',
    detailLabel: 'Found details',
    detailHint: 'Where was the pet found? Any collar or special mark?',
  );

  static const adopt = _PostTypeSpec(
    value: 'adopt',
    chipLabel: 'Adoption',
    title: 'Adoption post',
    subtitle: 'Describe the pet and the home it needs.',
    headline: 'Adoption post',
    messageHint: 'Add age, gender, temperament, vaccination, and adoption conditions...',
    publishLabel: 'Publish adoption',
    successMessage: 'Adoption post published.',
    safetyNote: 'Share honest details and choose adopters carefully. The pet safety comes first.',
    icon: Icons.favorite_rounded,
    publishIcon: Icons.favorite_rounded,
    color: Color(0xFFE26E96),
    background: Color(0xFFFFEEF4),
    petNameHint: 'Luna',
    areaHint: 'Current area',
    detailLabel: 'Adoption details',
    detailHint: 'Age, health, temperament, adoption conditions...',
  );

  static const rescue = _PostTypeSpec(
    value: 'rescue',
    chipLabel: 'Rescue',
    title: 'Rescue request',
    subtitle: 'Ask the community for urgent help.',
    headline: 'Rescue help needed',
    messageHint: 'Explain the situation, urgency, and what help is needed...',
    publishLabel: 'Ask for help',
    successMessage: 'Rescue request published.',
    safetyNote: 'Use rescue posts responsibly. Add enough detail so helpers understand the situation.',
    icon: Icons.campaign_rounded,
    publishIcon: Icons.campaign_rounded,
    color: Color(0xFFFF6A4B),
    background: Color(0xFFFFEFE8),
    petNameHint: 'Unknown',
    areaHint: 'Rescue area',
    detailLabel: 'Situation',
    detailHint: 'Injured, trapped, abandoned, needs transport...',
  );

  static _PostTypeSpec fromType(String? type) {
    switch (type) {
      case 'lost':
        return lost;
      case 'found':
        return found;
      case 'adopt':
        return adopt;
      case 'rescue':
        return rescue;
      default:
        return general;
    }
  }
}
