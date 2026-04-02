import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/media_presets.dart';

import '../../services/cloudinary_service.dart';
import '../../ui/app_theme.dart';
import '../../core/url_utils.dart';
import 'profile_repository.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _auth = FirebaseAuth.instance;

  final userC = TextEditingController();
  final bioC = TextEditingController();
  final phoneC = TextEditingController();

  File? _newAvatar;
  String? _photoUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final u = _auth.currentUser;
    userC.text = u?.displayName ?? "";
    _photoUrl = u?.photoURL;

    if (u != null) {
      ProfileRepository.instance.streamUser(u.uid).first.then((doc) {
        final d = doc.data();
        if (d == null || !mounted) return;
        setState(() {
          userC.text = (d['username'] ?? userC.text).toString();
          bioC.text = (d['bio'] ?? "").toString();
          phoneC.text = (d['phone'] ?? "").toString();
          final p = d['photoUrl'];
          if (p != null) _photoUrl = p.toString();
        });
      });
    }
  }

  @override
  void dispose() {
    userC.dispose();
    bioC.dispose();
    phoneC.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final p = MediaPresets.forKind(SocialImageKind.avatar);
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: p.quality,
        maxWidth: p.maxWidth,
        maxHeight: p.maxHeight,
      );
      if (x == null) return;
      setState(() => _newAvatar = File(x.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open photos: $e')));
    }
  }

  Future<void> _save() async {
    final u = _auth.currentUser;
    if (u == null) return;

    final username = userC.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Username required.")));
      return;
    }

    setState(() => _saving = true);
    try {
      String? finalPhotoUrl = _photoUrl;

      if (_newAvatar != null) {
        final uploaded = await CloudinaryService.instance.uploadImage(
          _newAvatar!,
        );
        finalPhotoUrl = uploaded.secureUrl;
      }

      await ProfileRepository.instance.updateProfile(
        uid: u.uid,
        username: username,
        bio: bioC.text,
        phone: phoneC.text,
        photoUrl: finalPhotoUrl,
      );

      await u.updateDisplayName(username);
      await u.updatePhotoURL(finalPhotoUrl);
      await u.reload();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _auth.currentUser;
    final fallback = (u?.displayName ?? "U").trim();
    final initial = fallback.isEmpty ? "U" : fallback[0].toUpperCase();

    final ImageProvider? img = _newAvatar != null
        ? FileImage(_newAvatar!)
        : ((_photoUrl != null && _photoUrl!.isNotEmpty)
              ? NetworkImage(UrlUtils.normalizeMediaUrl(_photoUrl!))
              : null);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text("Edit profile"),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Save"),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundColor: AppTheme.orange.withAlpha(25),
                  backgroundImage: img,
                  child: img == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton.filled(
                    onPressed: _pickAvatar,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          TextField(
            controller: userC,
            decoration: const InputDecoration(
              labelText: "Username",
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: bioC,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Bio",
              prefixIcon: Icon(Icons.info_outline),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: phoneC,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: "Phone",
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
