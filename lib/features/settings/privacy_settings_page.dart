import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../ui/premium_settings.dart';
import '../../ui/app_theme.dart';
import 'blocked_users_page.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _loading = true;
  bool _showPhone = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = _auth.currentUser;
    if (u == null) return;
    final doc = await _db.collection('users').doc(u.uid).get();
    final d = doc.data() ?? {};
    _showPhone = (d['showPhone'] as bool?) ?? true;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _setShowPhone(bool v) async {
    final u = _auth.currentUser;
    if (u == null) return;
    setState(() {
      _showPhone = v;
      _loading = true;
    });
    try {
      await _db.collection('users').doc(u.uid).set({
        'showPhone': v,
      }, SetOptions(merge: true));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          PremiumSettingsSectionCard(
            title: 'Visibility',
            subtitle: 'Control what others can see on your profile',
            icon: Icons.lock_rounded,
            iconBg: AppTheme.mint,
            iconFg: const Color(0xFF2F9A6A),
            children: [
              _SwitchTile(
                title: 'Show phone on profile',
                subtitle: 'If off, your phone number won’t be shown publicly.',
                value: _showPhone,
                loading: _loading,
                onChanged: _setShowPhone,
              ),
            ],
          ),
          const SizedBox(height: 12),
          PremiumSettingsSectionCard(
            title: 'Safety',
            subtitle: 'Manage blocked accounts and protection settings',
            icon: Icons.block_rounded,
            iconBg: const Color(0xFFFFEBEB),
            iconFg: const Color(0xFFE05555),
            children: [
              _NavTile(
                title: 'Blocked users',
                subtitle: 'Review and manage blocked accounts',
                icon: Icons.block_rounded,
                tint: const Color(0xFFE05555),
                bg: const Color(0xFFFFEBEB),
                onTap: () => _push(context, const BlockedUsersPage()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.loading,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool loading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsSwitchTile(
      title: title,
      subtitle: subtitle,
      value: value,
      loading: loading,
      onChanged: onChanged,
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.bg,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsNavTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      tint: tint,
      bg: bg,
      onTap: onTap,
    );
  }
}
