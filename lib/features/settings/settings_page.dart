import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';
import '../../ui/user_avatar.dart';
import 'about_page.dart';
import 'account_settings_page.dart';
import 'blocked_users_page.dart';
import 'legal_page.dart';
import 'privacy_settings_page.dart';
import 'security_settings_page.dart';
import 'support_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.bg,
        foregroundColor: AppTheme.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
        children: [
          _AccountHeader(
            uid: uid,
            onEdit: () => _push(context, const AccountSettingsPage()),
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            title: 'Account',
            children: [
              _SettingsTile(
                title: 'Edit profile',
                subtitle: 'Name, photo, bio and phone',
                icon: Icons.person_rounded,
                tint: AppTheme.orangeDark,
                bg: AppTheme.blush,
                onTap: () => _push(context, const AccountSettingsPage()),
              ),
              _SettingsTile(
                title: 'Security',
                subtitle: 'Password and sign-in',
                icon: Icons.lock_rounded,
                tint: const Color(0xFF2F9A6A),
                bg: AppTheme.mint,
                onTap: () => _push(context, const SecuritySettingsPage()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            title: 'Privacy',
            children: [
              _SettingsTile(
                title: 'Privacy settings',
                subtitle: 'Phone visibility',
                icon: Icons.shield_rounded,
                tint: const Color(0xFF2F9A6A),
                bg: AppTheme.mint,
                onTap: () => _push(context, const PrivacySettingsPage()),
              ),
              _SettingsTile(
                title: 'Blocked users',
                subtitle: 'Manage blocked accounts',
                icon: Icons.block_rounded,
                tint: const Color(0xFFE05555),
                bg: const Color(0xFFFFEBEB),
                onTap: () => _push(context, const BlockedUsersPage()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            title: 'App',
            children: [
              _SettingsTile(
                title: 'Support',
                subtitle: 'Contact and account requests',
                icon: Icons.support_agent_rounded,
                tint: const Color(0xFF4C79C8),
                bg: AppTheme.sky,
                onTap: () => _push(context, const SupportPage()),
              ),
              _SettingsTile(
                title: 'Terms & privacy',
                subtitle: 'Rules and policies',
                icon: Icons.article_rounded,
                tint: const Color(0xFF2F9A6A),
                bg: AppTheme.mint,
                onTap: () => _push(context, const LegalPage()),
              ),
              _SettingsTile(
                title: 'About PetTounsi',
                subtitle: 'Version and app details',
                icon: Icons.pets_rounded,
                tint: const Color(0xFF7C62D7),
                bg: AppTheme.lilac,
                onTap: () => _push(context, const AboutPage()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.uid, required this.onEdit});

  final String uid;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.12),
      ),
      child: Row(
        children: [
          UserAvatar(uid: uid, radius: 28, fallbackName: 'PetTounsi user'),
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
                    fontSize: 16.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email.isEmpty ? 'Signed in' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.orangeDark,
              backgroundColor: AppTheme.blush,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: const BorderSide(color: AppTheme.outline),
              ),
            ),
            child: const Text(
              'Edit',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.mist,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Icon(icon, color: tint, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
