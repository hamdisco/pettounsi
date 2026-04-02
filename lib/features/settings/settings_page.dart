import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';
import '../../ui/premium_settings.dart';
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
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName ?? 'Pettounsi').trim();
    final email = (user?.email ?? '').trim();
    final photo = (user?.photoURL ?? '').trim();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          _HeaderCard(
            name: name.isEmpty ? "Pettounsi" : name,
            email: email,
            photoUrl: photo,
            onAccount: () => _push(context, const AccountSettingsPage()),
          ),
          const SizedBox(height: 12),

          _Section(
            title: "Account",
            subtitle: "Profile & security",
            icon: Icons.person_rounded,
            iconBg: AppTheme.lilac,
            iconFg: const Color(0xFF7C62D7),
            children: [
              _Tile(
                title: "Edit profile",
                subtitle: "Name, bio, phone, and photo",
                icon: Icons.edit_rounded,
                tint: const Color(0xFF7C62D7),
                bg: AppTheme.lilac,
                onTap: () => _push(context, const AccountSettingsPage()),
              ),
              _Tile(
                title: "Security",
                subtitle: "Password and sign-in settings",
                icon: Icons.lock_rounded,
                tint: const Color(0xFF2F9A6A),
                bg: AppTheme.mint,
                onTap: () => _push(context, const SecuritySettingsPage()),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _Section(
            title: "Privacy & safety",
            subtitle: "Control what others can see",
            icon: Icons.shield_rounded,
            iconBg: AppTheme.mint,
            iconFg: const Color(0xFF2F9A6A),
            children: [
              _Tile(
                title: "Privacy",
                subtitle: "Manage phone visibility",
                icon: Icons.lock_rounded,
                tint: const Color(0xFF2F9A6A),
                bg: AppTheme.mint,
                onTap: () => _push(context, const PrivacySettingsPage()),
              ),
              _Tile(
                title: "Blocked users",
                subtitle: "Review and manage blocked accounts",
                icon: Icons.block_rounded,
                tint: const Color(0xFFE05555),
                bg: const Color(0xFFFFEBEB),
                onTap: () => _push(context, const BlockedUsersPage()),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _Section(
            title: "App",
            subtitle: "Support, legal, and app information",
            icon: Icons.info_rounded,
            iconBg: AppTheme.sky,
            iconFg: const Color(0xFF4C79C8),
            children: [
              _Tile(
                title: "Support & contact",
                subtitle: "Get help, review privacy links, and manage requests",
                icon: Icons.support_agent_rounded,
                tint: const Color(0xFF4C79C8),
                bg: AppTheme.sky,
                onTap: () => _push(context, const SupportPage()),
              ),
              _Tile(
                title: "Terms & privacy",
                subtitle: "Read community rules and privacy information",
                icon: Icons.article_rounded,
                tint: const Color(0xFF2F9A6A),
                bg: AppTheme.mint,
                onTap: () => _push(context, const LegalPage()),
              ),
              _Tile(
                title: "About",
                subtitle: "App details and quick links",
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.onAccount,
  });

  final String name;
  final String email;
  final String photoUrl;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsHero(
      leading: Container(
        width: 52,
        height: 52,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(230),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white),
        ),
        child: CircleAvatar(
          backgroundColor: AppTheme.lilac,
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty
              ? Text(
                  name.isEmpty ? 'P' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : null,
        ),
      ),
      title: name.isEmpty ? "Pettounsi" : name,
      subtitle: email.isNotEmpty ? email : 'Signed in',
      trailing: _PillButton(label: "Account", onTap: onAccount),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsSectionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconBg: iconBg,
      iconFg: iconFg,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      children: children,
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
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

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsPillButton(label: label, onTap: onTap);
  }
}
