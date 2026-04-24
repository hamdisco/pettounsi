import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../repositories/block_repository.dart';
import '../../repositories/follow_repository.dart';
import '../../ui/app_theme.dart';
import '../../ui/premium_cards.dart';
import '../../ui/premium_feedback.dart';
import '../../ui/premium_sections.dart';
import '../../ui/skeleton.dart';

import '../accessories/accessories_page.dart';
import '../events/events_page.dart';
import '../pet_babysitting/pet_babysitting_page.dart';
import '../vets/vets_page.dart';

import 'create_post_composer.dart';
import 'post_card.dart';
import 'for_you_feed_service.dart';
import 'post_model.dart';
import 'posts_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _FeedSegmentedTabs(controller: _tabs),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [_ForYouPagedFeed(), _FollowingHybridWrapper()],
          ),
        ),
      ],
    );
  }
}

class _FeedSegmentedTabs extends StatelessWidget {
  const _FeedSegmentedTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppTheme.mist,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.10),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.zero,
        splashBorderRadius: BorderRadius.circular(18),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(color: Colors.white.withAlpha(210)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C62D7).withAlpha(18),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        tabs: const [
          _FeedTabChip(
            icon: Icons.explore_rounded,
            title: 'For you',
            subtitle: 'Fresh picks',
          ),
          _FeedTabChip(
            icon: Icons.favorite_rounded,
            title: 'Following',
            subtitle: 'People',
          ),
        ],
      ),
    );
  }
}

class _FeedTabChip extends StatelessWidget {
  const _FeedTabChip({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(180)),
            ),
            child: Icon(icon, size: 17, color: AppTheme.ink),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.6,
                  color: AppTheme.ink,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 10.4,
                  color: AppTheme.muted.withAlpha(210),
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeStackedIntro extends StatelessWidget {
  const _HomeStackedIntro({
    required this.posts,
    required this.followingMode,
    required this.showComposer,
  });

  final List<PostModel> posts;
  final bool followingMode;
  final bool showComposer;

  @override
  Widget build(BuildContext context) {
    final photosCount = posts
        .where(
          (p) =>
              p.imageUrls.isNotEmpty || ((p.imageUrl ?? '').trim().isNotEmpty),
        )
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.outline),
            boxShadow: AppTheme.softShadows(0.32),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: SizedBox(
                  height: 210,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withAlpha(22),
                          BlendMode.darken,
                        ),
                        child: Image.asset(
                          'assets/start.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFFF0E7),
                                    Color(0xFFEFF5FF),
                                    Color(0xFFF3EEFF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.pets_rounded,
                                  size: 44,
                                  color: Color(0xFF9A8FB6),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0x33FFE7DA),
                              Color(0x2AE9E1FF),
                              Color(0x00FFFFFF),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 66),
                          child: Image.asset(
                            'assets/start.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withAlpha(14),
                              Colors.black.withAlpha(62),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        top: 12,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(228),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.white),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    followingMode
                                        ? Icons.favorite_rounded
                                        : Icons.auto_awesome_rounded,
                                    size: 14,
                                    color: followingMode
                                        ? const Color(0xFF7C62D7)
                                        : AppTheme.orangeDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    followingMode
                                        ? 'Following feed'
                                        : 'For you feed',
                                    style: const TextStyle(
                                      color: AppTheme.ink,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11.2,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(214),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withAlpha(190),
                                ),
                              ),
                              child: Text(
                                posts.length == 1
                                    ? '1 post'
                                    : '${posts.length} posts',
                                style: const TextStyle(
                                  color: AppTheme.ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.8,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(232),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withAlpha(200),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quick actions',
                                style: TextStyle(
                                  color: AppTheme.ink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.8,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _SafeTopQuickAction(
                                      icon: Icons.add_rounded,
                                      label: 'Post',
                                      bg: const Color(0xFFFFE7DD),
                                      fg: AppTheme.orangeDark,
                                      onTap: () async {
                                        await showModalBottomSheet<void>(
                                          context: context,
                                          isScrollControlled: true,
                                          showDragHandle: true,
                                          backgroundColor: Colors.white,
                                          builder: (sheetCtx) {
                                            return SafeArea(
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  left: 10,
                                                  right: 10,
                                                  top: 6,
                                                  bottom:
                                                      MediaQuery.of(
                                                        sheetCtx,
                                                      ).viewInsets.bottom +
                                                      10,
                                                ),
                                                child:
                                                    const SingleChildScrollView(
                                                      child:
                                                          CreatePostComposer(),
                                                    ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _SafeTopQuickAction(
                                      icon: Icons.local_hospital_rounded,
                                      label: 'Vets',
                                      bg: const Color(0xFFE6F7EF),
                                      fg: const Color(0xFF1F9C6B),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const VetsPage(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _SafeTopQuickAction(
                                      icon: Icons.event_rounded,
                                      label: 'Events',
                                      bg: const Color(0xFFEFEAFF),
                                      fg: const Color(0xFF7B5BE8),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const EventsPage(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _TopMetricTile(
                        icon: Icons.photo_library_rounded,
                        label: 'Photos',
                        value: photosCount.toString(),
                        bg: const Color(0xFFEAF3FF),
                        fg: const Color(0xFF4C79C8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TopMetricTile(
                        icon: Icons.forum_rounded,
                        label: 'Posts',
                        value: posts.length.toString(),
                        bg: const Color(0xFFFFF1E8),
                        fg: AppTheme.orangeDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TopMetricTile(
                        icon: followingMode
                            ? Icons.favorite_rounded
                            : Icons.explore_rounded,
                        label: 'Mode',
                        value: followingMode ? 'Following' : 'For you',
                        bg: const Color(0xFFF2EEFF),
                        fg: const Color(0xFF7C62D7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ServiceShowcaseGrid(posts: posts),
        if (showComposer) ...[
          const SizedBox(height: 12),
          const _ComposeCardShell(),
        ],
        const SizedBox(height: 10),
        _FeedSectionHeader(
          title: followingMode ? 'Following feed' : 'Community feed',
          count: posts.length,
        ),
      ],
    );
  }
}

class _SafeTopQuickAction extends StatelessWidget {
  const _SafeTopQuickAction({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bg, Color.lerp(bg, Colors.white, 0.55)!],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w900,
                    fontSize: 11.2,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopMetricTile extends StatelessWidget {
  const _TopMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline.withAlpha(180)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: fg),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(210),
                    fontWeight: FontWeight.w700,
                    fontSize: 10.3,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.2,
                    height: 1.0,
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

class _ImageSpotlightCarousel extends StatefulWidget {
  const _ImageSpotlightCarousel({
    required this.posts,
    required this.followingMode,
  });

  final List<PostModel> posts;
  final bool followingMode;

  @override
  State<_ImageSpotlightCarousel> createState() =>
      _ImageSpotlightCarouselState();
}

class _ImageSpotlightCarouselState extends State<_ImageSpotlightCarousel>
    with SingleTickerProviderStateMixin {
  late final PageController _controller = PageController(
    viewportFraction: 0.92,
  );
  late final AnimationController _floatCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat(reverse: true);

  Timer? _timer;
  int _page = 0;

  List<PostModel> get _items =>
      widget.posts.where((p) => p.imageUrls.isNotEmpty).take(8).toList();

  @override
  void initState() {
    super.initState();
    _startAuto();
  }

  @override
  void didUpdateWidget(covariant _ImageSpotlightCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCount = oldWidget.posts
        .where((p) => p.imageUrls.isNotEmpty)
        .take(8)
        .length;
    final newCount = _items.length;

    if (_page >= newCount && newCount > 0) {
      _page = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.jumpToPage(0);
      });
    }
    if (oldCount != newCount) _restartAuto();
  }

  void _startAuto() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      final items = _items;
      if (items.length <= 1) return;
      final next = (_page + 1) % items.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _restartAuto() {
    _timer?.cancel();
    _startAuto();
  }

  Future<void> _openComposer() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 10,
              right: 10,
              top: 6,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 10,
            ),
            child: const SingleChildScrollView(child: CreatePostComposer()),
          ),
        );
      },
    );
  }

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _floatCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final imageCount = items.length;
    final postCount = widget.posts.length;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF7F0), Color(0xFFF8F4FF), Color(0xFFF2F8FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppTheme.outline),
          boxShadow: AppTheme.softShadows(0.28),
        ),
        child: Column(
          children: [
            const _CardSectionTitle(
              icon: Icons.bolt_rounded,
              title: 'Quick actions',
              iconBg: Color(0xFFFFE7DB),
              iconColor: AppTheme.orangeDark,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TopActionButton(
                    label: 'New post',
                    icon: Icons.add_rounded,
                    accent: const Color(0xFFE56E57),
                    bg: const Color(0xFFFFE9E0),
                    onTap: _openComposer,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TopActionButton(
                    label: 'Vets',
                    icon: Icons.local_hospital_rounded,
                    accent: const Color(0xFF1FA875),
                    bg: const Color(0xFFE8FBF3),
                    onTap: () => _push(const VetsPage()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TopActionButton(
                    label: 'Events',
                    icon: Icons.event_rounded,
                    accent: const Color(0xFF7B5BE8),
                    bg: const Color(0xFFF1ECFF),
                    onTap: () => _push(const EventsPage()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const _EmptyPhotoSpotlight(),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _floatCtl,
      builder: (context, _) {
        final t = _floatCtl.value;
        final shift = (t - 0.5) * 18;

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF8F2), Color(0xFFF8F3FF), Color(0xFFF2F8FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppTheme.outline),
            boxShadow: AppTheme.softShadows(0.34),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12 + shift * 0.35,
                top: -18,
                child: _Blob(color: const Color(0xFFFFE1D5), size: 90),
              ),
              Positioned(
                left: -14 - shift * 0.25,
                top: 44,
                child: _Blob(color: const Color(0xFFE7F4FF), size: 68),
              ),
              Positioned(
                right: 26 - shift * 0.2,
                bottom: 8,
                child: _Blob(color: const Color(0xFFEFE7FF), size: 74),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const _CardSectionTitle(
                        icon: Icons.flash_on_rounded,
                        title: 'Quick actions',
                        iconBg: Color(0xFFFFE7DB),
                        iconColor: AppTheme.orangeDark,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(220),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        child: Text(
                          '${_page + 1}/$imageCount',
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 10.8,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 262,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withAlpha(210)),
                      boxShadow: AppTheme.softShadows(0.2),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: PageView.builder(
                              controller: _controller,
                              physics: const BouncingScrollPhysics(),
                              itemCount: items.length,
                              onPageChanged: (i) => setState(() => _page = i),
                              itemBuilder: (context, index) {
                                return AnimatedBuilder(
                                  animation: _controller,
                                  builder: (context, child) {
                                    double scale = 1.0;
                                    if (_controller.hasClients &&
                                        _controller
                                            .position
                                            .hasContentDimensions) {
                                      final current =
                                          _controller.page ?? _page.toDouble();
                                      final diff = (current - index)
                                          .abs()
                                          .clamp(0.0, 1.0);
                                      scale = 1 - (diff * 0.04);
                                    }
                                    return Transform.scale(
                                      scale: scale,
                                      child: child,
                                    );
                                  },
                                  child: _SpotlightSlide(post: items[index]),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          top: 10,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(232),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  widget.followingMode
                                      ? 'Following feed'
                                      : 'Community feed',
                                  style: const TextStyle(
                                    color: AppTheme.ink,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10.8,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(46),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(58),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Live photos',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10.2,
                                        height: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _TopActionButton(
                          label: 'New post',
                          icon: Icons.add_rounded,
                          accent: const Color(0xFFE56E57),
                          bg: const Color(0xFFFFE9E0),
                          onTap: _openComposer,
                          pulse: true,
                          pulsePhase: t,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TopActionButton(
                          label: 'Vets',
                          icon: Icons.local_hospital_rounded,
                          accent: const Color(0xFF1FA875),
                          bg: const Color(0xFFE8FBF3),
                          onTap: () => _push(const VetsPage()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TopActionButton(
                          label: 'Events',
                          icon: Icons.event_rounded,
                          accent: const Color(0xFF7B5BE8),
                          bg: const Color(0xFFF1ECFF),
                          onTap: () => _push(const EventsPage()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(232),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniHubStat(
                            label: 'Photos',
                            value: '$imageCount',
                            icon: Icons.photo_library_rounded,
                            bg: const Color(0xFFEAF4FF),
                            fg: const Color(0xFF4C79C8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MiniHubStat(
                            label: 'Posts',
                            value: '$postCount',
                            icon: Icons.dynamic_feed_rounded,
                            bg: const Color(0xFFFFF1E8),
                            fg: AppTheme.orangeDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MiniHubStat(
                            label: widget.followingMode ? 'Mode' : 'Mode',
                            value: widget.followingMode
                                ? 'Following'
                                : 'For you',
                            icon: widget.followingMode
                                ? Icons.favorite_rounded
                                : Icons.explore_rounded,
                            bg: const Color(0xFFF2EEFF),
                            fg: const Color(0xFF7C62D7),
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
      },
    );
  }
}

String _safePostLocation(PostModel post) {
  try {
    final dynamic any = post;
    final v = any.locationText;
    if (v is String) return v.trim();
  } catch (_) {
    // PostModel in this project may not have a location field.
  }
  return '';
}

class _SpotlightSlide extends StatelessWidget {
  const _SpotlightSlide({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final image = post.imageUrl ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _NetworkCoverImage(url: image),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withAlpha(14),
                    Colors.black.withAlpha(58),
                    Colors.black.withAlpha(165),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.46, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            right: -20,
            top: -12,
            child: _Blob(color: Colors.white.withAlpha(35), size: 86),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(232),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withAlpha(170)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _AvatarChip(
                        name: post.authorName,
                        photoUrl: post.authorPhotoUrl,
                        size: 34,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          post.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.0,
                            height: 1.0,
                          ),
                        ),
                      ),
                      _StatBubble(
                        icon: Icons.favorite_rounded,
                        text: '${post.likeCount}',
                        bg: const Color(0xFFFFEAF3),
                        fg: const Color(0xFFD35A8E),
                      ),
                      const SizedBox(width: 5),
                      _StatBubble(
                        icon: Icons.chat_bubble_outline_rounded,
                        text: '${post.commentCount}',
                        bg: const Color(0xFFEAF4FF),
                        fg: const Color(0xFF4C79C8),
                      ),
                    ],
                  ),
                  if (post.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        post.text.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.ink.withAlpha(205),
                          fontWeight: FontWeight.w700,
                          fontSize: 11.9,
                          height: 1.22,
                        ),
                      ),
                    ),
                  ],
                  if (_safePostLocation(post).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F5FF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.place_rounded,
                              size: 13,
                              color: Color(0xFF7C62D7),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _safePostLocation(post),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.4,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopActionButton extends StatefulWidget {
  const _TopActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.bg,
    required this.onTap,
    this.pulse = false,
    this.pulsePhase = 0,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final Color bg;
  final VoidCallback onTap;
  final bool pulse;
  final double pulsePhase;

  @override
  State<_TopActionButton> createState() => _TopActionButtonState();
}

class _TopActionButtonState extends State<_TopActionButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final glow = widget.pulse ? (0.18 + (widget.pulsePhase * 0.18)) : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _down ? 0.985 : 1,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: widget.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white),
            boxShadow: [
              if (widget.pulse)
                BoxShadow(
                  color: widget.accent.withAlpha((255 * glow).round()),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(226),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 17, color: widget.accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 11.8,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniHubStat extends StatelessWidget {
  const _MiniHubStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 15, color: fg),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.muted.withAlpha(220),
                  fontWeight: FontWeight.w800,
                  fontSize: 9.6,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 11.1,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NetworkCoverImage extends StatelessWidget {
  const _NetworkCoverImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final clean = url.trim();
    if (clean.isEmpty) {
      return Container(
        color: AppTheme.sky.withAlpha(120),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_outlined,
          color: AppTheme.ink.withAlpha(110),
          size: 30,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final dpr = MediaQuery.of(context).devicePixelRatio;

        final w = c.maxWidth.isFinite
            ? c.maxWidth
            : MediaQuery.of(context).size.width;
        final h = c.maxHeight.isFinite ? c.maxHeight : 220.0;

        int clampInt(int v, int min, int max) {
          if (v < min) return min;
          if (v > max) return max;
          return v;
        }

        final cacheW = clampInt((w * dpr).round(), 240, 1600);
        final cacheH = clampInt((h * dpr).round(), 240, 1600);

        final provider = ResizeImage(
          CachedNetworkImageProvider(clean),
          width: cacheW,
          height: cacheH,
        );

        return Image(
          image: provider,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Container(
            color: AppTheme.sky.withAlpha(120),
            alignment: Alignment.center,
            child: Icon(
              Icons.broken_image_outlined,
              color: AppTheme.ink.withAlpha(110),
              size: 28,
            ),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: AppTheme.sky.withAlpha(80)),
                const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AvatarChip extends StatelessWidget {
  const _AvatarChip({
    required this.name,
    required this.photoUrl,
    this.size = 32,
  });

  final String name;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty
        ? name.trim().characters.first.toUpperCase()
        : '?';

    Widget child;
    if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      child = ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initial(initial),
        ),
      );
    } else {
      child = _initial(initial);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white.withAlpha(230), width: 2),
        boxShadow: AppTheme.softShadows(0.15),
      ),
      child: child,
    );
  }

  Widget _initial(String initial) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFFE3D7), Color(0xFFF2EEFF)],
        ),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: AppTheme.ink,
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  const _StatBubble({
    required this.icon,
    required this.text,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 10.8,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPhotoSpotlight extends StatelessWidget {
  const _EmptyPhotoSpotlight();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 164,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
        gradient: LinearGradient(
          colors: [
            AppTheme.softOrange.withAlpha(110),
            AppTheme.lilac.withAlpha(110),
            AppTheme.sky.withAlpha(100),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: _Blob(color: Colors.white.withAlpha(110), size: 92),
          ),
          Positioned(
            left: -14,
            bottom: -14,
            child: _Blob(color: Colors.white.withAlpha(90), size: 82),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(220),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: AppTheme.orangeDark,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'No image posts yet',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.2,
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

class _ServiceShowcaseGrid extends StatelessWidget {
  const _ServiceShowcaseGrid({required this.posts});

  final List<PostModel> posts;

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  List<String> _photoPool() {
    final out = <String>[];
    for (final p in posts) {
      for (final u in p.imageUrls) {
        final v = u.trim();
        if (v.isNotEmpty && !out.contains(v)) out.add(v);
        if (out.length >= 8) return out;
      }
      final single = (p.imageUrl ?? '').trim();
      if (single.isNotEmpty && !out.contains(single)) out.add(single);
      if (out.length >= 8) return out;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    _photoPool();

    final items = <_ServiceItem>[
      _ServiceItem(
        title: 'Pet Sitting',
        subtitle: 'Trusted sitters',
        icon: Icons.volunteer_activism_rounded,
        accent: const Color(0xFF7B5BE8),
        gradient: const [Color(0xFFE2D7FF), Color(0xFFF4F0FF)],
        layerA: const Color(0xFFBCA9FF),
        layerB: const Color(0xFFFBF9FF),
        pillBg: const Color(0xFFF4F0FF),
        photoUrl:
            'https://images.unsplash.com/photo-1652502060260-15b075518034?auto=format&fit=crop&fm=jpg&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&ixlib=rb-4.1.0&q=60&w=1200',
        onTap: () => _push(context, const PetBabysittingPage()),
      ),

      _ServiceItem(
        title: 'Vets',
        subtitle: 'Clinics & emergency',
        icon: Icons.local_hospital_rounded,
        accent: const Color(0xFF26A06F),
        gradient: const [Color(0xFFCFF4E2), Color(0xFFEFFAF4)],
        layerA: const Color(0xFF83DEB2),
        layerB: const Color(0xFFF7FFFB),
        pillBg: const Color(0xFFEAF8F1),
        photoUrl:
            'https://images.unsplash.com/photo-1770836037816-4445dbd449fd?auto=format&fit=crop&fm=jpg&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTh8fHZldGVyaW5hcnklMjBjbGluaWN8ZW58MHx8MHx8fDA%3D&ixlib=rb-4.1.0&q=60&w=1200',
        onTap: () => _push(context, const VetsPage()),
      ),
      _ServiceItem(
        title: 'Accessories',
        subtitle: 'Rewards & points',
        icon: Icons.shopping_bag_rounded,
        accent: const Color(0xFF4679F0),
        gradient: const [Color(0xFFD8E5FF), Color(0xFFEEF4FF)],
        layerA: const Color(0xFF8DB2FF),
        layerB: const Color(0xFFF7FAFF),
        pillBg: const Color(0xFFEFF4FF),
        photoUrl:
            'https://images.unsplash.com/photo-1682969651476-6fb48aba8b03?auto=format&fit=crop&fm=jpg&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTB8fGRvZyUyMGNvbGxhcnxlbnwwfHwwfHx8MA%3D%3D&ixlib=rb-4.1.0&q=60&w=1200',
        onTap: () => _push(context, const AccessoriesPage()),
      ),
      _ServiceItem(
        title: 'Events',
        subtitle: 'Meetups & local help',
        icon: Icons.event_rounded,
        accent: const Color(0xFFE56E57),
        gradient: const [Color(0xFFFFD7C8), Color(0xFFFFEEE6)],
        layerA: const Color(0xFFFFA88D),
        layerB: const Color(0xFFFFF8F4),
        pillBg: const Color(0xFFFFF4EC),
        photoUrl:
            'https://images.unsplash.com/photo-1667230228326-c881966e2a29?auto=format&fit=crop&fm=jpg&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTV8fGRvZyUyMHBhcmt8ZW58MHx8MHx8fDA%3D&ixlib=rb-4.1.0&q=60&w=1200',
        onTap: () => _push(context, const EventsPage()),
      ),
    ];

    Widget row(_ServiceItem a, _ServiceItem b) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(height: 170, child: _PremiumServiceCard(item: a)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(height: 170, child: _PremiumServiceCard(item: b)),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.35),
      ),
      child: Column(
        children: [
          const _CardSectionTitle(
            icon: Icons.widgets_rounded,
            title: 'Services',
            iconBg: Color(0xFFEFEAFF),
            iconColor: Color(0xFF7B5BE8),
          ),
          const SizedBox(height: 10),
          row(items[0], items[1]),
          const SizedBox(height: 10),
          row(items[2], items[3]),
        ],
      ),
    );
  }
}

class _ServiceItem {
  const _ServiceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.gradient,
    required this.layerA,
    required this.layerB,
    required this.pillBg,
    required this.onTap,
    this.photoUrl,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<Color> gradient;
  final Color layerA;
  final Color layerB;
  final Color pillBg;
  final VoidCallback onTap;
  final String? photoUrl;
}

class _PremiumServiceCard extends StatefulWidget {
  const _PremiumServiceCard({required this.item});

  final _ServiceItem item;

  @override
  State<_PremiumServiceCard> createState() => _PremiumServiceCardState();
}

class _PremiumServiceCardState extends State<_PremiumServiceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasPhoto = (item.photoUrl ?? '').trim().isNotEmpty;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: item.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: item.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withAlpha(220)),
            boxShadow: AppTheme.softShadows(_pressed ? 0.18 : 0.28),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasPhoto)
                  Opacity(
                    opacity: 0.28,
                    child: _NetworkCoverImage(url: item.photoUrl!),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withAlpha(18),
                        Colors.white.withAlpha(8),
                        Colors.white.withAlpha(38),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Transform.translate(
                    offset: const Offset(6, -6),
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: item.layerA.withAlpha(130),
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Transform.translate(
                    offset: const Offset(-10, 10),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: item.layerB.withAlpha(170),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(234),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Icon(item.icon, color: item.accent, size: 22),
                      ),
                      const Spacer(),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.muted.withAlpha(215),
                          fontWeight: FontWeight.w700,
                          fontSize: 11.2,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: item.pillBg,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withAlpha(200),
                              ),
                            ),
                            child: Text(
                              'Open',
                              style: TextStyle(
                                color: item.accent,
                                fontWeight: FontWeight.w900,
                                fontSize: 11.2,
                                height: 1.0,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(230),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: Colors.white),
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 17,
                              color: item.accent.withAlpha(220),
                            ),
                          ),
                        ],
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

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.38),
      ),
    );
  }
}

class _ComposeCardShell extends StatelessWidget {
  const _ComposeCardShell();

  @override
  Widget build(BuildContext context) {
    return PremiumCardSurface(
      radius: BorderRadius.circular(26),
      padding: EdgeInsets.zero,
      shadowOpacity: 0.12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.blush, AppTheme.lilac, AppTheme.sky],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              border: const Border(bottom: BorderSide(color: AppTheme.outline)),
            ),
            child: Row(
              children: const [
                Expanded(
                  child: Text(
                    'Create post',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 15.8,
                      height: 1.0,
                    ),
                  ),
                ),
                PremiumCardBadge(
                  label: 'Community',
                  bg: AppTheme.lilac,
                  fg: Color(0xFF6B56C9),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: CreatePostComposer(),
          ),
        ],
      ),
    );
  }
}

class _FeedSectionHeader extends StatelessWidget {
  const _FeedSectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return PremiumCardSurface(
      radius: BorderRadius.circular(22),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      shadowOpacity: 0.06,
      child: PremiumSectionHeader(
        title: title,
        subtitle: count == 1
            ? '1 post in this feed'
            : '$count posts in this feed',
        compact: true,
        trailing: PremiumCardBadge(
          label: '$count',
          icon: Icons.dynamic_feed_rounded,
          bg: AppTheme.butter,
          fg: AppTheme.ink.withAlpha(190),
        ),
      ),
    );
  }
}

class _CardSectionTitle extends StatelessWidget {
  const _CardSectionTitle({
    required this.icon,
    required this.title,
    this.iconBg = AppTheme.sky,
    this.iconColor = const Color(0xFF4C79C8),
  });

  final IconData icon;
  final String title;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13.8,
              color: AppTheme.ink,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

PostModel? _tryParsePost(DocumentSnapshot<Map<String, dynamic>> d) {
  try {
    return PostModel.fromDoc(d);
  } catch (_) {
    return null;
  }
}

class _HomeFeedFallback extends StatelessWidget {
  const _HomeFeedFallback({
    required this.followingMode,
    required this.showComposer,
    this.message,
    this.isLoading = false,
  });

  final bool followingMode;
  final bool showComposer;
  final String? message;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
      children: [
        _HomeStackedIntro(
          posts: const <PostModel>[],
          followingMode: followingMode,
          showComposer: showComposer,
        ),
        const SizedBox(height: 12),
        if (isLoading) ...[
          PremiumMiniEmptyCard(
            icon: Icons.sync_rounded,
            iconColor: const Color(0xFF7C62D7),
            iconBg: AppTheme.lilac,
            title: 'Loading feed',
            subtitle: message ?? 'Bringing in the latest posts for you.',
          ),
          const SizedBox(height: 12),
          const SkeletonPostCard(),
          const SizedBox(height: 12),
          const SkeletonPostCard(),
          const SizedBox(height: 12),
          const SkeletonPostCard(showImage: false),
        ] else
          PremiumEmptyStateCard(
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF4C79C8),
            iconBg: AppTheme.sky,
            title: followingMode
                ? 'Following feed unavailable'
                : 'Feed unavailable',
            subtitle:
                message ??
                'No feed items are available right now. Pull to refresh and try again.',
            compact: true,
          ),
      ],
    );
  }
}

class _ForYouPagedFeed extends StatefulWidget {
  const _ForYouPagedFeed();

  @override
  State<_ForYouPagedFeed> createState() => _ForYouPagedFeedState();
}

class _ForYouPagedFeedState extends State<_ForYouPagedFeed>
    with AutomaticKeepAliveClientMixin {
  static const int _pageSize = 20;

  final _scroll = ScrollController();
  late final Stream<Set<String>> _blockedUsersStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _latestPostsStream;

  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loadingMore = false;
  bool _hasMore = true;

  final List<DocumentSnapshot<Map<String, dynamic>>> _olderDocs = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _blockedUsersStream = BlockRepository.instance.streamBlockedUids();
    _latestPostsStream = PostsRepository.instance.streamLatestSnap(
      limit: _pageSize,
    );
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 420) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final startAfter = _cursor;
    if (startAfter == null) return;

    setState(() => _loadingMore = true);
    try {
      final snap = await PostsRepository.instance.fetchLatestSnap(
        startAfter: startAfter,
        limit: _pageSize,
      );

      final docs = snap.docs;
      if (docs.isEmpty) {
        if (mounted) {
          setState(() {
            _hasMore = false;
            _loadingMore = false;
          });
        }
        return;
      }

      final existingIds = <String>{..._olderDocs.map((d) => d.id)};
      final newDocs = docs.where((d) => !existingIds.contains(d.id)).toList();

      _olderDocs.addAll(newDocs);
      _cursor = docs.last;
      if (docs.length < _pageSize) _hasMore = false;
    } catch (_) {
      // keep silent, feed remains usable
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _olderDocs.clear();
      _cursor = null;
      _hasMore = true;
      _loadingMore = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 180));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<Set<String>>(
      stream: _blockedUsersStream,
      builder: (context, bSnap) {
        final blocked = bSnap.data ?? {};

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _latestPostsStream,
          builder: (context, snap) {
            if (snap.hasError) {
              return const _HomeFeedFallback(
                followingMode: false,
                showComposer: true,
                message:
                    'Feed could not load right now. Pull to refresh or try again in a moment.',
              );
            }
            if (!snap.hasData) {
              return const _HomeFeedFallback(
                followingMode: false,
                showComposer: true,
                isLoading: true,
              );
            }

            final firstDocs = snap.data!.docs;
            if (_cursor == null && firstDocs.isNotEmpty) {
              _cursor = firstDocs.last;
            }

            final seen = <String>{};
            final combined = <PostModel>[];

            for (final d in firstDocs) {
              if (!seen.add(d.id)) continue;
              final p = _tryParsePost(d);
              if (p != null && !blocked.contains(p.authorId)) combined.add(p);
            }

            for (final d in _olderDocs) {
              if (!seen.add(d.id)) continue;
              final p = _tryParsePost(d);
              if (p != null && !blocked.contains(p.authorId)) combined.add(p);
            }

            // ── For You scoring ──────────────────────────────────────────
            // Score each post and sort descending. All arithmetic is local
            // (no extra Firestore reads) so this is instant.
            final now = DateTime.now();
            double score0(PostModel p) {
              double score = 0;

              // 1. Recency — posts decay with age (half-life ≈ 12 h)
              final age = p.createdAt != null
                  ? now.difference(p.createdAt!)
                  : const Duration(days: 30);
              final ageHours = age.inMinutes / 60.0;
              score += 100.0 / (1.0 + ageHours / 12.0);

              // 2. Engagement — likes + comments weighted
              score += p.likeCount * 4.0;
              score += p.commentCount * 6.0;

              // 3. Rich content bonus
              if (p.imageUrls.isNotEmpty) score += 12.0;

              // 4. Rescue posts float to top — time-sensitive content
              if (p.postType == 'rescue') score += 40.0;
              if (p.postType == 'adopt') score += 20.0;

              // 5. Seen penalty — de-prioritize already-seen posts
              score -= ForYouFeedService.instance.seenPenalty(p.id, now: now);

              return score;
            }

            combined.sort((a, b) => score0(b).compareTo(score0(a)));

            return RefreshIndicator(
              onRefresh: _refresh,
              color: AppTheme.orangeDark,
              backgroundColor: Colors.white,
              child: ListView.separated(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
                itemCount: combined.length + 2,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return _HomeStackedIntro(
                      posts: combined,
                      followingMode: false,
                      showComposer: true,
                    );
                  }

                  final postIndex = i - 1;
                  if (postIndex < combined.length) {
                    final post = combined[postIndex];
                    // Mark seen lazily — no await, no setState
                    ForYouFeedService.instance.markSeen(post.id);
                    return PostCard(post: post);
                  }

                  if (_loadingMore) {
                    return const _FeedLoadingMore();
                  }

                  if (!_hasMore) {
                    return const _FeedEndBadge();
                  }

                  return const SizedBox(height: 18);
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _FollowingHybridWrapper extends StatefulWidget {
  const _FollowingHybridWrapper();

  @override
  State<_FollowingHybridWrapper> createState() =>
      _FollowingHybridWrapperState();
}

class _FollowingHybridWrapperState extends State<_FollowingHybridWrapper> {
  late final Stream<Set<String>> _blockedUsersStream;
  late final Stream<Set<String>> _followingUsersStream;

  @override
  void initState() {
    super.initState();
    _blockedUsersStream = BlockRepository.instance.streamBlockedUids();
    _followingUsersStream = FollowRepository.instance.streamMyFollowingUids();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<String>>(
      stream: _blockedUsersStream,
      builder: (context, bSnap) {
        final blocked = bSnap.data ?? {};

        return StreamBuilder<Set<String>>(
          stream: _followingUsersStream,
          builder: (context, fSnap) {
            if (fSnap.hasError) {
              return const _HomeFeedFallback(
                followingMode: true,
                showComposer: false,
                message: 'Following list could not load right now.',
              );
            }
            if (!fSnap.hasData) {
              return const _HomeFeedFallback(
                followingMode: true,
                showComposer: false,
                isLoading: true,
              );
            }

            final following = (fSnap.data ?? {})
                .where((u) => !blocked.contains(u))
                .toList();

            if (following.isEmpty) {
              return const _HomeEmptyState(
                icon: Icons.favorite_border_rounded,
                title: 'No following yet',
                subtitle: 'Follow accounts to build your personalized feed.',
              );
            }

            return _FollowingHybridFeed(
              key: ValueKey(following.join('|')),
              following: following,
              blocked: blocked,
            );
          },
        );
      },
    );
  }
}

class _FollowingHybridFeed extends StatefulWidget {
  const _FollowingHybridFeed({
    super.key,
    required this.following,
    required this.blocked,
  });

  final List<String> following;
  final Set<String> blocked;

  @override
  State<_FollowingHybridFeed> createState() => _FollowingHybridFeedState();
}

class _FollowingHybridFeedState extends State<_FollowingHybridFeed>
    with AutomaticKeepAliveClientMixin {
  late Stream<List<PostModel>> _followingPostsStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _followingPostsStream = _buildFollowingPostsStream();
  }

  @override
  void didUpdateWidget(covariant _FollowingHybridFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameStringList(oldWidget.following, widget.following)) {
      _followingPostsStream = _buildFollowingPostsStream();
    }
  }

  Stream<List<PostModel>> _buildFollowingPostsStream() {
    return PostsRepository.instance.streamByAuthorsLive(
      widget.following,
      limitPerChunk: 12,
    );
  }

  bool _sameStringList(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<List<PostModel>>(
      stream: _followingPostsStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return const _HomeFeedFallback(
            followingMode: true,
            showComposer: false,
            message: 'Following feed could not load right now.',
          );
        }
        if (!snap.hasData) {
          return const _HomeFeedFallback(
            followingMode: true,
            showComposer: false,
            isLoading: true,
          );
        }

        final posts = (snap.data ?? const <PostModel>[])
            .where((p) => !widget.blocked.contains(p.authorId))
            .toList();

        if (posts.isEmpty) {
          return const _HomeEmptyState(
            icon: Icons.inbox_rounded,
            title: 'No posts yet',
            subtitle: 'Posts from followed accounts will appear here.',
          );
        }

        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
          itemCount: posts.length + 2,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i == 0) {
              return _HomeStackedIntro(
                posts: posts,
                followingMode: true,
                showComposer: false,
              );
            }
            final postIndex = i - 1;
            if (postIndex < posts.length) {
              return PostCard(post: posts[postIndex]);
            }
            return const _FeedEndBadge();
          },
        );
      },
    );
  }
}

class _FeedLoadingMore extends StatelessWidget {
  const _FeedLoadingMore();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: PremiumCardSurface(
          radius: BorderRadius.circular(18),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shadowOpacity: 0.05,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
              SizedBox(width: 10),
              Text(
                'Loading more posts',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.1,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedEndBadge extends StatelessWidget {
  const _FeedEndBadge();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: PremiumEmptyStateCard(
          icon: icon,
          iconColor: const Color(0xFF7C62D7),
          iconBg: AppTheme.lilac,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }
}
