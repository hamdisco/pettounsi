import 'dart:async';
import 'dart:io';
import '../../ui/premium_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/date_formatters.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../ui/app_theme.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  User? get _user => _auth.currentUser;

  bool get _hasPasswordProvider {
    final u = _user;
    if (u == null) return false;
    return u.providerData.any((p) => p.providerId == 'password');
  }

  final _username = TextEditingController();
  final _bio = TextEditingController();
  final _phone = TextEditingController();

  bool _loading = false;
  String _photoUrl = '';

  DateTime? _lastResetSentAt;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  DateTime? _accountDeletionRequestedAt;
  String _accountDeletionStatus = '';
  String _accountDeletionReason = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _username.dispose();
    _bio.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final next = _cooldownSeconds - 1;
      if (next <= 0) {
        t.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds = next);
      }
    });
  }

  DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  bool get _hasPendingDeletionRequest => _accountDeletionStatus == 'pending';

  String get _deletionRequestSubtitle {
    if (_hasPendingDeletionRequest && _accountDeletionRequestedAt != null) {
      return 'Requested on ${AppDateFmt.dMyHm(_accountDeletionRequestedAt)}. You can update the note if needed.';
    }
    if (_hasPendingDeletionRequest) {
      return 'A deletion request is already pending for this account.';
    }
    return 'Request permanent deletion of your account and associated data.';
  }

  Future<void> _load() async {
    final u = _auth.currentUser;
    if (u == null) return;

    final doc = await _db.collection('users').doc(u.uid).get();
    final d = doc.data() ?? {};

    _username.text = ((d['username'] ?? u.displayName ?? '') as String).trim();
    _bio.text = ((d['bio'] ?? '') as String).trim();
    _phone.text = ((d['phone'] ?? '') as String).trim();
    _photoUrl = ((d['photoUrl'] ?? u.photoURL ?? '') as String).trim();
    _accountDeletionRequestedAt = _readDateTime(
      d['accountDeletionRequestedAt'],
    );
    _accountDeletionStatus = ((d['accountDeletionStatus'] ?? '') as String)
        .trim()
        .toLowerCase();
    _accountDeletionReason = ((d['accountDeletionReason'] ?? '') as String)
        .trim();

    if (mounted) setState(() {});
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;

    setState(() => _loading = true);
    try {
      final uploaded = await CloudinaryService.instance.uploadImage(
        File(x.path),
      );
      _photoUrl = uploaded.secureUrl;
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn\'t upload photo. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final u = _auth.currentUser;
    if (u == null) return;

    final name = _username.text.trim();
    final bio = _bio.text.trim();
    final phone = _phone.text.trim();

    setState(() => _loading = true);
    try {
      await _db.collection('users').doc(u.uid).set({
        'username': name,
        'usernameLower': name.isEmpty ? null : name.toLowerCase(),
        'displayName': name,
        'bio': bio,
        'phone': phone,
        'photoUrl': _photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (name.isNotEmpty) await u.updateDisplayName(name);
      if (_photoUrl.isNotEmpty) await u.updatePhotoURL(_photoUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Couldn\'t save changes. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyAuthError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'wrong-password':
          return 'Current password is incorrect.';
        case 'weak-password':
          return 'New password is too weak (min 6 characters).';
        case 'requires-recent-login':
          return 'For security, please sign in again and retry.';
        case 'provider-not-password':
          return 'This account uses a social sign-in. Use password reset to set a password.';
        case 'user-not-found':
          return 'No account found for that email.';
        case 'invalid-email':
          return 'Invalid email address.';
        default:
          return e.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _showChangePassword() async {
    final u = _auth.currentUser;
    final email = (u?.email ?? '').trim();

    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();

    bool busy = false;
    bool showCurrent = false;
    bool showNext = false;
    bool showConfirm = false;

    Future<void> submit(StateSetter setSheetState) async {
      final c = current.text;
      final n = next.text;
      final k = confirm.text;

      if (c.trim().isEmpty || n.trim().isEmpty || k.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields.')),
        );
        return;
      }
      if (n.trim().length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New password must be at least 6 characters.'),
          ),
        );
        return;
      }
      if (n != k) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')),
        );
        return;
      }

      setSheetState(() => busy = true);
      try {
        await AuthService.instance.changePassword(
          currentPassword: c,
          newPassword: n,
        );
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Password updated')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyAuthError(e))));
      } finally {
        if (mounted) setSheetState(() => busy = false);
      }
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.outline),
                  boxShadow: AppTheme.softShadows(0.24),
                ),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.mint,
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: Color(0xFF2F9A6A),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Change password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: busy ? null : () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (email.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Signed in as $email',
                          style: TextStyle(
                            color: AppTheme.muted.withAlpha(220),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: current,
                      obscureText: !showCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        prefixIcon: const Icon(Icons.password_rounded),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setSheetState(() => showCurrent = !showCurrent),
                          icon: Icon(
                            showCurrent
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: next,
                      obscureText: !showNext,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setSheetState(() => showNext = !showNext),
                          icon: Icon(
                            showNext
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirm,
                      obscureText: !showConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm new password',
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setSheetState(() => showConfirm = !showConfirm),
                          icon: Icon(
                            showConfirm
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: busy ? null : () => submit(setSheetState),
                        child: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Text('Update password'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tip: use a strong password you don\'t reuse elsewhere.',
                      style: TextStyle(
                        color: AppTheme.muted.withAlpha(210),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    current.dispose();
    next.dispose();
    confirm.dispose();
  }

  Future<void> _showResetPassword() async {
    final email = (_auth.currentUser?.email ?? '').trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This account has no email address.')),
      );
      return;
    }

    Future<void> send() async {
      try {
        await AuthService.instance.sendPasswordReset(email);
        _lastResetSentAt = DateTime.now();
        _startCooldown(20);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Reset email sent to $email')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyAuthError(e))));
      }
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.outline),
              boxShadow: AppTheme.softShadows(0.22),
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.lilac,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        color: Color(0xFF7C62D7),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Reset password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'We\'ll send a reset link to:',
                    style: TextStyle(
                      color: AppTheme.muted.withAlpha(220),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Text(
                    email,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Check your inbox and spam folder. If you don\'t receive it in 1–2 minutes, tap resend.',
                    style: TextStyle(
                      color: AppTheme.muted.withAlpha(220),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _loading
                            ? null
                            : () async {
                                await send();
                              },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          (_lastResetSentAt == null)
                              ? 'Send email'
                              : 'Send again',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_cooldownSeconds > 0 || _loading)
                            ? null
                            : () async {
                                await send();
                              },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(
                          _cooldownSeconds > 0
                              ? 'Resend (${_cooldownSeconds}s)'
                              : 'Resend',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDeleteAccountRequestSheet() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final reason = TextEditingController(text: _accountDeletionReason);
    var confirm = false;
    var busy = false;

    Future<void> submit(StateSetter setSheetState) async {
      if (!confirm) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please confirm that you understand this request.'),
          ),
        );
        return;
      }

      final note = reason.text.trim();
      if (note.length > 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please keep the note under 400 characters.'),
          ),
        );
        return;
      }

      setSheetState(() => busy = true);
      try {
        final providerIds = user.providerData
            .map((p) => p.providerId.trim())
            .where((p) => p.isNotEmpty)
            .toList();

        final requestedAtValue =
            _hasPendingDeletionRequest && _accountDeletionRequestedAt != null
            ? Timestamp.fromDate(_accountDeletionRequestedAt!)
            : FieldValue.serverTimestamp();

        await _db.collection('users').doc(user.uid).set({
          'accountDeletionRequestedAt': requestedAtValue,
          'accountDeletionStatus': 'pending',
          'accountDeletionReason': note.isEmpty ? FieldValue.delete() : note,
          'accountDeletionEmail': (user.email ?? '').trim().isEmpty
              ? FieldValue.delete()
              : (user.email ?? '').trim(),
          'accountDeletionProviderIds': providerIds,
          'accountDeletionUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _accountDeletionStatus = 'pending';
        _accountDeletionRequestedAt ??= DateTime.now();
        _accountDeletionReason = note;

        if (!mounted) return;
        setState(() {});
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Deletion request submitted. We usually process requests within 7 days.',
            ),
          ),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Couldn\'t submit the deletion request. Please try again.',
            ),
          ),
        );
      } finally {
        if (mounted) setSheetState(() => busy = false);
      }
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final email = (user.email ?? '').trim();
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.outline),
                  boxShadow: AppTheme.softShadows(0.24),
                ),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFFEBEB),
                          ),
                          child: const Icon(
                            Icons.delete_forever_rounded,
                            color: Color(0xFFE05555),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _hasPendingDeletionRequest
                                ? 'Update deletion request'
                                : 'Request account deletion',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: busy ? null : () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This sends a permanent deletion request for your Pettounsi account. Once processed, your profile and account-related data will be deleted or anonymized, except for information we are legally required to keep or must retain for safety, fraud-prevention, or security reasons.\n\nDeletion requests are usually processed within 7 days.',
                      style: TextStyle(
                        color: AppTheme.muted.withAlpha(220),
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account email',
                              style: TextStyle(
                                color: AppTheme.muted.withAlpha(220),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: reason,
                      maxLines: 4,
                      maxLength: 400,
                      decoration: const InputDecoration(
                        labelText: 'Reason or note (optional)',
                        hintText:
                            'Optional note: tell us anything important about your request. Example: Please also remove my listings and profile photos.',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7F7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFD8D8)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: confirm,
                            onChanged: busy
                                ? null
                                : (v) =>
                                      setSheetState(() => confirm = v ?? false),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'I understand that this request may permanently delete my Pettounsi account and associated data once it is processed.',
                                style: TextStyle(
                                  color: AppTheme.ink.withAlpha(220),
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE05555),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: busy ? null : () => submit(setSheetState),
                        icon: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                        label: Text(
                          _hasPendingDeletionRequest
                              ? 'Update deletion request'
                              : 'Submit deletion request',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    reason.dispose();
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;
    final email = (u?.email ?? '').trim();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          _ProfileCard(
            username: _username.text.trim().isEmpty
                ? 'User'
                : _username.text.trim(),
            email: email,
            photoUrl: _photoUrl,
            loading: _loading,
            onChangePhoto: _loading ? null : _pickAndUploadPhoto,
          ),
          const SizedBox(height: 12),

          _Card(
            title: 'Profile info',
            icon: Icons.badge_rounded,
            iconBg: AppTheme.lilac,
            iconFg: const Color(0xFF7C62D7),
            child: Column(
              children: [
                TextField(
                  controller: _username,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _bio,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Text('Save changes'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _Card(
            title: 'Security',
            icon: Icons.lock_rounded,
            iconBg: AppTheme.mint,
            iconFg: const Color(0xFF2F9A6A),
            child: Column(
              children: [
                _ActionRow(
                  title: 'Change password',
                  subtitle: _hasPasswordProvider
                      ? 'Update your password securely'
                      : 'This account does not use a password',
                  icon: Icons.key_rounded,
                  tint: const Color(0xFF2F9A6A),
                  onTap: (_loading || !_hasPasswordProvider)
                      ? null
                      : _showChangePassword,
                ),
                const SizedBox(height: 8),
                _ActionRow(
                  title: 'Send reset email',
                  subtitle: email.isEmpty
                      ? 'Email account required'
                      : 'Send to $email',
                  icon: Icons.mail_outline_rounded,
                  tint: const Color(0xFF2F9A6A),
                  onTap: (_loading || !_hasPasswordProvider)
                      ? null
                      : _showResetPassword,
                ),
                if (!_hasPasswordProvider) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: Text(
                      'This account uses a social sign-in method. Password changes need to be managed through that sign-in provider.',
                      style: TextStyle(
                        color: AppTheme.muted.withAlpha(220),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          _Card(
            title: 'Danger zone',
            icon: Icons.warning_amber_rounded,
            iconBg: const Color(0xFFFFF2DB),
            iconFg: const Color(0xFFDA8A1F),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasPendingDeletionRequest)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7F7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD8D8)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFE05555),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _accountDeletionRequestedAt == null
                                ? 'A deletion request is already pending for this account.'
                                : 'Deletion request pending since ${AppDateFmt.dMyHm(_accountDeletionRequestedAt)}.',
                            style: const TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                _ActionRow(
                  title: _hasPendingDeletionRequest
                      ? 'Update deletion request'
                      : 'Request account deletion',
                  subtitle: _deletionRequestSubtitle,
                  icon: Icons.delete_forever_rounded,
                  tint: const Color(0xFFE05555),
                  onTap: _loading ? null : _showDeleteAccountRequestSheet,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use this to request permanent deletion of your Pettounsi account and associated data.',
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(215),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _Card(
            title: 'Session',
            icon: Icons.logout_rounded,
            iconBg: const Color(0xFFFFEBEB),
            iconFg: const Color(0xFFE05555),
            child: Column(
              children: [
                _ActionRow(
                  title: 'Sign out',
                  subtitle: 'Log out of your account',
                  icon: Icons.logout_rounded,
                  tint: const Color(0xFFE05555),
                  onTap: _loading ? null : _signOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.username,
    required this.email,
    required this.photoUrl,
    required this.loading,
    required this.onChangePhoto,
  });

  final String username;
  final String email;
  final String photoUrl;
  final bool loading;
  final VoidCallback? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsHero(
      leading: Container(
        width: 58,
        height: 58,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(235),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white),
        ),
        child: CircleAvatar(
          backgroundColor: AppTheme.lilac,
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty
              ? Text(
                  username.isEmpty ? 'U' : username[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : null,
        ),
      ),
      title: username,
      subtitle: email.isEmpty ? 'Signed in' : email,
      trailing: OutlinedButton(
        onPressed: onChangePhoto,
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Photo'),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsSectionCard(
      title: title,
      subtitle: '',
      icon: icon,
      iconBg: iconBg,
      iconFg: iconFg,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      children: [child],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsNavTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      tint: tint,
      bg: tint.withAlpha(24),
      onTap: onTap,
      enabled: onTap != null,
    );
  }
}
