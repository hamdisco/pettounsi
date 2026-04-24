import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';
import '../../ui/brand_widgets.dart';

class FirstStepsGuidePage extends StatefulWidget {
  const FirstStepsGuidePage({super.key});

  @override
  State<FirstStepsGuidePage> createState() => _FirstStepsGuidePageState();
}

class _FirstStepsGuidePageState extends State<FirstStepsGuidePage> {
  late final PageController _controller;
  int _page = 0;

  static const List<_GuidePageData> _pages = [
    _GuidePageData(
      icon: Icons.dynamic_feed_rounded,
      accent: AppTheme.orangeDark,
      cardColor: Color(0xFFFFF2EC),
      eyebrow: 'Community',
      title: 'Follow what matters first',
      subtitle:
          'Discover pet posts, reactions, comments, and everyday community activity from Home.',
      bullets: [
        'Browse new posts',
        'React and comment',
        'Follow pet profiles',
      ],
    ),
    _GuidePageData(
      icon: Icons.map_rounded,
      accent: AppTheme.orchidDark,
      cardColor: Color(0xFFF3EEFF),
      eyebrow: 'Nearby',
      title: 'Use the map for local essentials',
      subtitle:
          'Find lost and found reports, vets, petshops, and events around you in one place.',
      bullets: [
        'Lost & found reports',
        'Vets and petshops',
        'Nearby events',
      ],
    ),
    _GuidePageData(
      icon: Icons.chat_bubble_rounded,
      accent: AppTheme.roseDark,
      cardColor: Color(0xFFFFEEF5),
      eyebrow: 'Messages',
      title: 'Follow before you start a chat',
      subtitle:
          'Messaging opens after you follow the other profile, so conversations stay relevant and safer.',
      bullets: [
        'Follow first',
        'Then open Messages',
        'Keep chats focused',
      ],
    ),
    _GuidePageData(
      icon: Icons.shield_outlined,
      accent: Color(0xFF2F8F6B),
      cardColor: Color(0xFFEDF9F3),
      eyebrow: 'Control',
      title: 'Keep your account under control',
      subtitle:
          'Settings gives you privacy details, support, reporting tools, blocked users, and account actions.',
      bullets: [
        'Report content',
        'Block users',
        'Manage account settings',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLastPage => _page == _pages.length - 1;

  Future<void> _next() async {
    if (_isLastPage) {
      Navigator.of(context).pop();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _pages[_page];

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.outline),
                      boxShadow: AppTheme.softShadows(0.05),
                    ),
                    alignment: Alignment.center,
                    child: const AppLogo(size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Pettounsi',
                          style: TextStyle(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 19,
                            height: 1.05,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Start with the essentials.',
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  return _GuidePageView(data: _pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      ...List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: EdgeInsets.only(
                            right: index == _pages.length - 1 ? 0 : 8,
                          ),
                          width: _page == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _page == index
                                ? current.accent
                                : AppTheme.outline,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_page + 1}/${_pages.length}',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: current.accent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(_isLastPage ? 'Get started' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidePageView extends StatelessWidget {
  const _GuidePageView({required this.data});

  final _GuidePageData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuideHeroCard(data: data),
          const SizedBox(height: 18),
          Text(
            data.eyebrow.toUpperCase(),
            style: TextStyle(
              color: data.accent,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 28,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.subtitle,
            style: const TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          ...data.bullets.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _GuideBulletCard(data: data, label: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideHeroCard extends StatelessWidget {
  const _GuideHeroCard({required this.data});

  final _GuidePageData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            data.cardColor,
            Colors.white,
            data.cardColor.withAlpha(230),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(235),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white),
                ),
                alignment: Alignment.center,
                child: Icon(data.icon, color: data.accent, size: 30),
              ),
              const Spacer(),
              _MiniBadge(label: data.eyebrow, accent: data.accent),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: data.bullets
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(225),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: data.accent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          item,
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _GuideBulletCard extends StatelessWidget {
  const _GuideBulletCard({required this.data, required this.label});

  final _GuidePageData data;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.05),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(data.icon, color: data.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
                fontSize: 14.2,
                height: 1.15,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: data.accent, size: 20),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(225),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _GuidePageData {
  const _GuidePageData({
    required this.icon,
    required this.accent,
    required this.cardColor,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.bullets,
  });

  final IconData icon;
  final Color accent;
  final Color cardColor;
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<String> bullets;
}
