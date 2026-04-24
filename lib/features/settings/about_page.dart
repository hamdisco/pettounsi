import 'package:flutter/material.dart';

import '../../core/legal_links.dart';
import '../../ui/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const Color _pink = Color(0xFFFFE4EF);
  static const Color _pinkDeep = Color(0xFFFF78A8);
  static const Color _pinkAccent = Color(0xFFFFA8C8);
  static const Color _cream = Color(0xFFFFFCF7);
  static const Color _berry = Color(0xFF8A4D6B);
  static const Color _lavender = Color(0xFFF0E7FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.transparent,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF8FC), Color(0xFFFFF0F6), Color(0xFFF8F2FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          children: const [
            _AboutHero(),
            SizedBox(height: 12),
            _AboutHighlightsCard(),
            SizedBox(height: 12),
            _AboutUseCasesCard(),
          ],
        ),
      ),
    );
  }
}

class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F7), Color(0xFFFFF8FC), Color(0xFFF7F1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF7C9DA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFAD6B8A).withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFF7C9DA),
                    width: 1.2,
                  ),
                ),
                child: const _HelloKittyLogo(size: 46),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      LegalLinks.appName,
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        height: 1.05,
                      ),
                    ),

                    SizedBox(height: 6),
                    Text(
                      'Playful pet space for sharing, helping, and staying connected.',
                      style: TextStyle(
                        color: Color(0xFF7F6A7A),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        height: 1.22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutHighlightsCard extends StatelessWidget {
  const _AboutHighlightsCard();

  @override
  Widget build(BuildContext context) {
    return _CuteSectionCard(
      title: 'What you can do here',
      icon: Icons.auto_awesome_rounded,
      iconBg: AboutPage._lavender,
      iconFg: const Color(0xFF8663D1),
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
    return _CuteSectionCard(
      title: 'Why Pettounsi is useful',
      icon: Icons.favorite_outline_rounded,
      iconBg: AboutPage._pink,
      iconFg: AboutPage._pinkDeep,
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

class _CuteSectionCard extends StatelessWidget {
  const _CuteSectionCard({
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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF2D7E2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB57C97).withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white),
                ),
                child: Icon(icon, color: iconFg, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _HelloKittyLogo extends StatelessWidget {
  const _HelloKittyLogo({required this.size});

  static const String _logoUrl =
      'https://raw.githubusercontent.com/szxmsu/css3-hello-kitty/master/1024px-Hello_Kitty_logo.svg.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(size * 0.02),
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.28),
          child: Image.network(
            _logoUrl,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.pets_rounded,
                  size: 30,
                  color: Color(0xFFFF78A8),
                ),
              );
            },
          ),
        ),
      ),
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
        color: AboutPage._cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF2D7E2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AboutPage._pink,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white),
            ),
            child: Icon(icon, color: AboutPage._berry, size: 20),
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
                  style: const TextStyle(
                    color: Color(0xFF7F6A7A),
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
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF2D7E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.stars_rounded,
                color: AboutPage._pinkAccent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF7F6A7A),
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
