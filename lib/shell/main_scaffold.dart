import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../repositories/notifications_repository.dart';
import '../ui/app_theme.dart';
import '../ui/brand_widgets.dart';
import '../features/messages/messages_repository.dart';
import '../features/home/home_page.dart';
import '../features/map/map_page.dart';
import '../features/messages/messages_page.dart';
import '../features/messages/new_chat_sheet.dart';
import '../features/games/games_page.dart';
import '../features/profile/profile_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/search/search_page.dart';

import 'app_drawer.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  static const String route = "/app";

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int index = 0;

  final _pages = const [
    HomePage(),
    MapPage(),
    MessagesPage(),
    GamesPage(),
    _MyProfileTab(),
  ];

  static const _topLabels = <String>[
    'Home',
    'Map',
    'Messages',
    'Games',
    'Profile',
  ];

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  void _openNewChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: const NewChatSheet(),
      ),
    );
  }

  void _goProfile() => setState(() => index = 4);

  Widget _notifIconWithBadge() {
    return StreamBuilder<int>(
      stream: NotificationsRepository.instance.streamUnreadCount(),
      builder: (context, snap) {
        final c = snap.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: AppTheme.ink.withAlpha(190),
              size: 20,
            ),
            if (c > 0)
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.orangeDark,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white, width: 1.2),
                    boxShadow: AppTheme.softShadows(0.18),
                  ),
                  child: Text(
                    c > 99 ? '99+' : '$c',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 9.4,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _profileActionIcon() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final u = snap.data;
        final photo = (u?.photoURL ?? '').trim();

        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD8CB), Color(0xFFF0EAFF), Color(0xFFE7F4FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white),
          ),
          padding: const EdgeInsets.all(1.6),
          child: CircleAvatar(
            radius: 12.5,
            backgroundColor: Colors.white,
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo.isEmpty
                ? Icon(
                    Icons.person_rounded,
                    size: 15.5,
                    color: AppTheme.ink.withAlpha(170),
                  )
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      drawer: const AppDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(248),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.outline),
                boxShadow: AppTheme.softShadows(0.24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 5),
                  Builder(
                    builder: (ctx) => _TopBarIcon(
                      tooltip: 'Menu',
                      onTap: () => Scaffold.of(ctx).openDrawer(),
                      icon: Icons.menu_rounded,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _HeaderChip(label: _topLabels[index]),
                  const Spacer(),
                  _TopBarIcon(
                    tooltip: 'Search',
                    onTap: _openSearch,
                    icon: Icons.search_rounded,
                  ),
                  const SizedBox(width: 6),
                  _TopBarWidget(
                    tooltip: 'Notifications',
                    onTap: _openNotifications,
                    child: _notifIconWithBadge(),
                  ),
                  const SizedBox(width: 6),
                  _TopBarWidget(
                    tooltip: 'Profile',
                    onTap: _goProfile,
                    child: _profileActionIcon(),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(index: index, children: _pages),
      floatingActionButton: (index == 2)
          ? _GradientFab(onTap: _openNewChat)
          : null,
      bottomNavigationBar: StreamBuilder<int>(
        stream: MessagesRepository.instance.streamUnreadConversationCount(
          limit: 60,
        ),
        builder: (context, snap) {
          final unreadMessages = snap.data ?? 0;

          return _BottomNavBar(
            index: index,
            unreadMessages: unreadMessages,
            onChanged: (i) => setState(() => index = i),
          );
        },
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 390;

    return Container(
      constraints: BoxConstraints(maxWidth: compact ? 136 : 170),
      padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF2EC), Color(0xFFF6F0FF), Color(0xFFF0F8FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFA57D), AppTheme.orange],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.orange.withAlpha(24),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const AppLogo(size: 15),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pettounsi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.8,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarIcon extends StatelessWidget {
  const _TopBarIcon({
    required this.tooltip,
    required this.onTap,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _TopBarWidget(
      tooltip: tooltip,
      onTap: onTap,
      child: Icon(icon, color: AppTheme.ink.withAlpha(190), size: 20),
    );
  }
}

class _TopBarWidget extends StatelessWidget {
  const _TopBarWidget({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.index,
    required this.unreadMessages,
    required this.onChanged,
  });

  final int index;
  final int unreadMessages;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = <_NavItem>[
      _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
      _NavItem(Icons.map_rounded, Icons.map_outlined, 'Map'),
      _NavItem(
        Icons.chat_bubble_rounded,
        Icons.chat_bubble_outline,
        'Messages',
      ),
      _NavItem(
        Icons.sports_esports_rounded,
        Icons.sports_esports_outlined,
        'Games',
      ),
      _NavItem(Icons.person_rounded, Icons.person_outline, 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(248),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.outline),
            boxShadow: AppTheme.softShadows(0.32),
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == index;

              return Expanded(
                child: _NavButton(
                  item: items[i],
                  selected: selected,
                  badgeCount: i == 2 ? unreadMessages : 0,
                  onTap: () => onChanged(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.selectedIcon, this.icon, this.label);
  final IconData selectedIcon;
  final IconData icon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppTheme.ink : AppTheme.muted;
    final bg = selected ? AppTheme.lilac.withAlpha(180) : Colors.transparent;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: selected ? Border.all(color: AppTheme.outline) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: Icon(
                    selected ? item.selectedIcon : item.icon,
                    key: ValueKey(selected),
                    color: fg,
                    size: 21,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -10,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.orangeDark,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Colors.white, width: 1.2),
                        boxShadow: AppTheme.softShadows(0.16),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg.withAlpha(selected ? 255 : 210),
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientFab extends StatelessWidget {
  const _GradientFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.orange, Color(0xFFFFA57D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadows(0.26),
      ),
      child: FloatingActionButton(
        heroTag: 'new_chat_fab',
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: onTap,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }
}

class _MyProfileTab extends StatelessWidget {
  const _MyProfileTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Please log in'));
    }
    return ProfilePage(uid: uid);
  }
}
