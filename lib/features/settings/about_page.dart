import 'package:flutter/material.dart';

import '../../core/legal_links.dart';
import '../../ui/app_theme.dart';
import '../../ui/premium_settings.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: const [
          _AboutHero(),
          SizedBox(height: 12),
          _AboutHighlightsCard(),
          SizedBox(height: 12),
          _AboutUseCasesCard(),
        ],
      ),
    );
  }
}

class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsHero(
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFA57D), AppTheme.orangeDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.pets_rounded, color: Colors.white, size: 26),
      ),
      title: LegalLinks.appName,
      subtitle:
          'A social pet community built for local help, useful updates, and everyday pet life in one place.',
    );
  }
}

class _AboutHighlightsCard extends StatelessWidget {
  const _AboutHighlightsCard();

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsSectionCard(
      title: 'What you can do here',
      icon: Icons.auto_awesome_rounded,
      iconBg: AppTheme.lilac,
      iconFg: const Color(0xFF7C62D7),
      children: const [
        _FeatureRow(
          icon: Icons.pets_outlined,
          title: 'Share posts',
          subtitle:
              'Publish pet photos, lost & found updates, and community posts.',
        ),
        _FeatureRow(
          icon: Icons.map_outlined,
          title: 'Explore the map',
          subtitle: 'Browse reports, vets, petshops, and events near you.',
        ),
        _FeatureRow(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Message people',
          subtitle: 'Chat with other users and follow community activity.',
        ),
        _FeatureRow(
          icon: Icons.volunteer_activism_outlined,
          title: 'Use pet services',
          subtitle:
              'Discover babysitting, accessories, games, podcasts, and more.',
        ),
      ],
    );
  }
}

class _AboutUseCasesCard extends StatelessWidget {
  const _AboutUseCasesCard();

  @override
  Widget build(BuildContext context) {
    return PremiumSettingsSectionCard(
      title: 'Why Pettounsi is useful',
      icon: Icons.favorite_outline_rounded,
      iconBg: AppTheme.mint,
      iconFg: const Color(0xFF2F9A6A),
      children: const [
        _MiniNote(
          title: 'Local first',
          body:
              'Made for Tunisia with nearby discovery and local community use in mind.',
        ),
        SizedBox(height: 10),
        _MiniNote(
          title: 'Community driven',
          body:
              'Profiles, follows, comments, reports, and chats keep pet owners connected.',
        ),
        SizedBox(height: 10),
        _MiniNote(
          title: 'Practical daily use',
          body:
              'Useful for missing pets, helpful updates, discovery, and care-related tools.',
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.mist,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Icon(icon, color: AppTheme.ink.withAlpha(190), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.2,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(220),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniNote extends StatelessWidget {
  const _MiniNote({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: TextStyle(
              color: AppTheme.muted.withAlpha(220),
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.18,
            ),
          ),
        ],
      ),
    );
  }
}
