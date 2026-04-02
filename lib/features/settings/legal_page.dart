import 'package:flutter/material.dart';

import '../../core/store_compliance.dart';
import '../../ui/app_theme.dart';
import '../../ui/premium_settings.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Terms & privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          const SizedBox(height: 12),
          _Card(
            title: 'Community guidelines',
            icon: Icons.groups_rounded,
            iconBg: AppTheme.lilac,
            iconFg: const Color(0xFF7C62D7),
            children: const [
              _Bullet('Be kind and respectful.'),
              _Bullet('No harassment, hate speech, or scams.'),
              _Bullet('Do not share someone else’s private info.'),
              _Bullet('For lost/found posts: include last seen area and date.'),
              _Bullet('Report inappropriate content using the report button.'),
              _Bullet('Repeat abuse may lead to content removal or account action.'),
            ],
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'Content that is not allowed',
            icon: Icons.gpp_bad_rounded,
            iconBg: const Color(0xFFFFEBEB),
            iconFg: const Color(0xFFE05555),
            children: [
              for (final line in StoreCompliance.prohibitedContent) _Bullet(line),
            ],
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'Privacy note',
            icon: Icons.privacy_tip_rounded,
            iconBg: AppTheme.mint,
            iconFg: const Color(0xFF2F9A6A),
            children: const [
              _Bullet(
                'If you add a phone number, you can hide it in Privacy settings.',
              ),
              _Bullet(
                'Posts, comments, map reports, chats, and babysitting requests may be processed to operate the app and enforce safety rules.',
              ),
              _Bullet(
                'Public posts, comments, map reports, and listings are visible to other users of the app.',
              ),
              _Bullet(
                'You can block users anytime from their profile or in settings.',
              ),
              _Bullet(
                'Account deletion requests can be submitted from Account settings or Support.',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'Safety disclaimer',
            icon: Icons.warning_rounded,
            iconBg: const Color(0xFFFFF2DB),
            iconFg: const Color(0xFFDA8A1F),
            children: const [
              _Bullet(
                'Pettounsi is a community app, not a veterinary service.',
              ),
              _Bullet(
                'In emergencies, contact a vet or local rescue immediately.',
              ),
              _Bullet(
                'Users are responsible for the content they publish and for interactions arranged through the app.',
              ),
            ],
          ),
        ],
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
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsSectionCard(
      title: title,
      subtitle: '',
      icon: icon,
      iconBg: iconBg,
      iconFg: iconFg,
      children: children,
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsBullet(text);
  }
}
