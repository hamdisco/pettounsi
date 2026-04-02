import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pettounsi/features/settings/settings_page.dart';

import '../ui/app_theme.dart';
import '../services/auth_service.dart';
import '../auth/login_page.dart';

import '../features/profile/profile_page.dart';
import '../features/pet_babysitting/pet_babysitting_page.dart';
import '../features/vets/vets_page.dart';
import '../features/petshops/petshops_page.dart';
import '../features/events/events_page.dart';
import '../features/games/games_page.dart';
import '../features/podcasts/podcasts_page.dart';
import '../features/accessories/accessories_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final name = (user?.displayName ?? "Pettounsi").trim();
    final photo = (user?.photoURL ?? '').trim();

    return Drawer(
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.bg,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.outline),
                boxShadow: AppTheme.softShadows(0.55),
              ),
              child: Column(
                children: [
                  _DrawerHeroHeader(
                    name: name.isEmpty ? "Pettounsi" : name,
                    photoUrl: photo,
                    onProfileTap: uid == null
                        ? null
                        : () => _push(context, ProfilePage(uid: uid)),
                    onSettingsTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),

                  // ✅ No scroll: scale down content to fit any height.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: c.maxWidth,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _SectionTitle(
                                    title: "Quick services",
                                    subtitle: "Fast access",
                                    icon: Icons.grid_view_rounded,
                                    iconBg: AppTheme.lilac,
                                    iconFg: Color(0xFF7C62D7),
                                  ),
                                  const SizedBox(height: 8),
                                  _QuickServicesStack(
                                    onBabysitting: () => _push(
                                      context,
                                      const PetBabysittingPage(),
                                    ),
                                    onVets: () =>
                                        _push(context, const VetsPage()),
                                    onAccessories: () =>
                                        _push(context, const AccessoriesPage()),
                                    onEvents: () =>
                                        _push(context, const EventsPage()),
                                  ),
                                  const SizedBox(height: 10),
                                  Divider(
                                    color: AppTheme.ink.withAlpha(16),
                                    height: 1,
                                  ),
                                  const SizedBox(height: 10),
                                  const _SectionTitle(
                                    title: "Browse",
                                    subtitle: "More places & content",
                                    icon: Icons.explore_rounded,
                                    iconBg: AppTheme.sky,
                                    iconFg: Color(0xFF4C79C8),
                                  ),
                                  const SizedBox(height: 8),
                                  _DrawerTile(
                                    title: "Petshops",
                                    icon: Icons.storefront_rounded,
                                    iconBg: AppTheme.butter,
                                    iconFg: const Color(0xFFC6921A),
                                    onTap: () =>
                                        _push(context, const PetshopsPage()),
                                  ),
                                  _DrawerTile(
                                    title: "Games & points",
                                    icon: Icons.emoji_events_rounded,
                                    iconBg: const Color(0xFFFFF2DB),
                                    iconFg: const Color(0xFFDA8A1F),
                                    onTap: () =>
                                        _push(context, const GamesPage()),
                                  ),
                                  _DrawerTile(
                                    title: "Podcasts",
                                    icon: Icons.podcasts_rounded,
                                    iconBg: AppTheme.blush,
                                    iconFg: const Color(0xFFD35A8E),
                                    onTap: () =>
                                        _push(context, const PodcastsPage()),
                                  ),
                                  const SizedBox(height: 10),
                                  Divider(
                                    color: AppTheme.ink.withAlpha(16),
                                    height: 1,
                                  ),
                                  const SizedBox(height: 10),
                                  _DrawerTile(
                                    title: "Logout",
                                    icon: Icons.logout_rounded,
                                    iconBg: const Color(0xFFFFEBEB),
                                    iconFg: const Color(0xFFE05555),
                                    danger: true,
                                    onTap: () async {
                                      await AuthService.instance.signOut();
                                      if (!context.mounted) return;
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        LoginPage.route,
                                        (r) => false,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerHeroHeader extends StatelessWidget {
  const _DrawerHeroHeader({
    required this.name,
    required this.photoUrl,
    required this.onProfileTap,
    required this.onSettingsTap,
  });

  final String name;
  final String photoUrl;
  final VoidCallback? onProfileTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1EA), Color(0xFFF6EFFF), Color(0xFFEEF7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: AppTheme.outline.withAlpha(180)),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/start.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0.05, -0.08),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onProfileTap,
                child: Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl.isEmpty
                        ? const Icon(
                            Icons.pets_rounded,
                            color: AppTheme.orangeDark,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: onProfileTap,
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(220),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Text(
                          onProfileTap == null ? "Welcome" : "View profile",
                          style: TextStyle(
                            color: AppTheme.ink.withAlpha(185),
                            fontWeight: FontWeight.w800,
                            fontSize: 11.2,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.white.withAlpha(220),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onSettingsTap,
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.settings_rounded,
                      color: AppTheme.ink,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;

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
          child: Icon(icon, color: iconFg, size: 18),
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
                  fontSize: 13.0,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.muted.withAlpha(210),
                  fontWeight: FontWeight.w700,
                  fontSize: 10.6,
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

class _QuickServicesStack extends StatelessWidget {
  const _QuickServicesStack({
    required this.onBabysitting,
    required this.onVets,
    required this.onAccessories,
    required this.onEvents,
  });

  final VoidCallback onBabysitting;
  final VoidCallback onVets;
  final VoidCallback onAccessories;
  final VoidCallback onEvents;

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    const h = 78.0;

    return Column(
      children: [
        _ServicePhotoCard(
          height: h,
          title: "Pet Babysitting",
          subtitle: "Trusted sitters",
          icon: Icons.volunteer_activism_rounded,
          grad: const [Color(0xFFE2D7FF), Color(0xFFF4F0FF)],
          accent: const Color(0xFF7B5BE8),
          badge: "Care",
          photoUrl:
              "https://images.unsplash.com/photo-1770786442845-a48353e5cdb3?auto=format&fit=crop&fm=jpg&q=60&w=1000",
          photoAlign: const Alignment(0.0, 0.2),
          onTap: onBabysitting,
        ),

        const SizedBox(height: gap),
        _ServicePhotoCard(
          height: h,
          title: "Vets",
          subtitle: "Clinics • emergency",
          icon: Icons.local_hospital_rounded,
          grad: const [Color(0xFFCFF4E2), Color(0xFFEFFAF4)],
          accent: const Color(0xFF26A06F),
          badge: "Help",
          photoUrl:
              "https://images.unsplash.com/photo-1770836037289-e00e5f351d11?auto=format&fit=crop&fm=jpg&q=60&w=1000",
          photoAlign: const Alignment(0.25, 0.0),
          onTap: onVets,
        ),
        const SizedBox(height: gap),
        _ServicePhotoCard(
          height: h,
          title: "Events",
          subtitle: "Meetups • local",
          icon: Icons.event_rounded,
          grad: const [Color(0xFFFFD7C8), Color(0xFFFFEEE6)],
          accent: AppTheme.orangeDark,
          badge: "Social",
          photoUrl:
              "https://images.unsplash.com/photo-1667230228326-c881966e2a29?auto=format&fit=crop&fm=jpg&q=60&w=1000",
          photoAlign: const Alignment(0.0, 0.25),
          onTap: onEvents,
        ),

        const SizedBox(height: gap),
        _ServicePhotoCard(
          height: h,
          title: "Accessories",
          subtitle: "Rewards • points",
          icon: Icons.shopping_bag_rounded,
          grad: const [Color(0xFFD8E5FF), Color(0xFFEEF4FF)],
          accent: const Color(0xFF4679F0),
          badge: "Rewards",
          photoUrl:
              "https://images.unsplash.com/photo-1747443148294-a91791c0a62a?auto=format&fit=crop&fm=jpg&q=60&w=1000",
          photoAlign: const Alignment(-0.2, 0.0),
          onTap: onAccessories,
        ),
      ],
    );
  }
}

class _ServicePhotoCard extends StatelessWidget {
  const _ServicePhotoCard({
    required this.height,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.grad,
    required this.accent,
    required this.badge,
    required this.photoUrl,
    required this.photoAlign,
    required this.onTap,
  });

  final double height;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> grad;
  final Color accent;
  final String badge;
  final String photoUrl;
  final Alignment photoAlign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: grad,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(220)),
          boxShadow: AppTheme.softShadows(0.16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: _NetworkBackdrop(
                  url: photoUrl,
                  alignment: photoAlign,
                  opacity: 0.16,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withAlpha(26),
                        Colors.white.withAlpha(90),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 54,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(220),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 10.4,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(235),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Icon(icon, color: accent, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 13.2,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.ink.withAlpha(168),
                              fontWeight: FontWeight.w700,
                              fontSize: 10.6,
                              height: 1.10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(228),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: accent.withAlpha(210),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkBackdrop extends StatelessWidget {
  const _NetworkBackdrop({
    required this.url,
    required this.alignment,
    required this.opacity,
  });

  final String url;
  final Alignment alignment;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final clean = url.trim();
    if (clean.isEmpty) return const SizedBox.shrink();

    return Opacity(
      opacity: opacity,
      child: LayoutBuilder(
        builder: (context, c) {
          final dpr = MediaQuery.of(context).devicePixelRatio;
          final w = c.maxWidth.isFinite
              ? c.maxWidth
              : MediaQuery.of(context).size.width;
          final h = c.maxHeight.isFinite ? c.maxHeight : 120.0;

          int clampInt(int v, int min, int max) {
            if (v < min) return min;
            if (v > max) return max;
            return v;
          }

          final cacheW = clampInt((w * dpr).round(), 240, 1400);
          final cacheH = clampInt((h * dpr).round(), 240, 1400);

          final provider = ResizeImage(
            CachedNetworkImageProvider(clean),
            width: cacheW,
            height: cacheH,
          );

          return Image(
            image: provider,
            fit: BoxFit.cover,
            alignment: alignment,
            filterQuality: FilterQuality.low,
            gaplessPlayback: true,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return ColoredBox(color: Colors.white.withAlpha(18));
            },
            errorBuilder: (_, __, ___) {
              return Container(
                color: Colors.white.withAlpha(40),
                alignment: Alignment.center,
                child: Icon(
                  Icons.pets_rounded,
                  color: AppTheme.muted.withAlpha(70),
                  size: 64,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.onTap,
    this.danger = false,
  });

  final String title;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? const Color(0xFFE05555) : AppTheme.ink;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(248),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.outline),
            boxShadow: AppTheme.softShadows(0.10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Icon(icon, color: iconFg, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w900, color: fg),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.ink.withAlpha(120),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
