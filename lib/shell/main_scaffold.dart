import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/home/home_page.dart';
import '../features/map/map_page.dart';
import '../features/messages/messages_page.dart';
import '../features/messages/messages_repository.dart';
import '../features/messages/new_chat_sheet.dart';
import '../features/notifications/notifications_page.dart';
import '../features/profile/profile_page.dart';
import '../features/search/search_page.dart';
import '../features/services/services_hub_page.dart';
import '../repositories/notifications_repository.dart';
import '../services/in_app_sound_service.dart';
import '../ui/app_theme.dart';
import '../ui/user_avatar.dart';

import 'app_drawer.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  static const String route = '/app';

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int index = 0;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _notificationsSoundSub;
  final Set<String> _seenNotificationIds = <String>{};
  bool _notificationsSoundArmed = false;
  _InAppAlert? _activeAlert;
  Timer? _alertTimer;

  final Set<int> _visitedTabs = <int>{0};

  static const _topLabels = <String>[
    'PetTounsi',
    'Services',
    'Map',
    'Messages',
    'Profile',
  ];

  static const _topSubtitles = <String>[
    'Pet care near you',
    'Trusted partners',
    'Discover nearby places',
    'Stay connected',
    'Your space',
  ];

  @override
  void initState() {
    super.initState();
    _wireInAppSounds();
  }

  @override
  void dispose() {
    _notificationsSoundSub?.cancel();
    _alertTimer?.cancel();
    super.dispose();
  }

  void _wireInAppSounds() {
    _notificationsSoundSub?.cancel();

    _notificationsSoundSub = NotificationsRepository.instance
        .streamMyNotifications(limit: 60)
        .listen((snap) {
          final ids = snap.docs.map((d) => d.id).toSet();

          if (!_notificationsSoundArmed) {
            _seenNotificationIds
              ..clear()
              ..addAll(ids);
            _notificationsSoundArmed = true;
            return;
          }

          QueryDocumentSnapshot<Map<String, dynamic>>? newestDoc;
          for (final doc in snap.docs) {
            if (!_seenNotificationIds.contains(doc.id)) {
              newestDoc = doc;
              break;
            }
          }

          _seenNotificationIds
            ..clear()
            ..addAll(ids);

          if (newestDoc != null) {
            final data = newestDoc.data();
            final type = ((data['type'] ?? '') as String).trim();
            final isMessage = type == 'message';

            if (isMessage) {
              InAppSoundService.instance.playMessageSound();
            } else {
              InAppSoundService.instance.playNotificationSound();
            }

            _showInAppAlert(
              _InAppAlert(
                id: 'notification-${newestDoc.id}',
                title: NotificationsRepository.instance.displayTitleFor(data),
                subtitle: NotificationsRepository.instance.displayBodyFor(data),
                icon: isMessage
                    ? Icons.chat_bubble_rounded
                    : Icons.notifications_active_rounded,
                onTap: isMessage ? () => _onTabChanged(3) : _openNotifications,
              ),
            );
          }
        });
  }

  void _showInAppAlert(_InAppAlert alert) {
    if (!mounted) return;

    _alertTimer?.cancel();
    setState(() => _activeAlert = alert);

    _alertTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _activeAlert?.id != alert.id) return;
      setState(() => _activeAlert = null);
    });
  }

  void _dismissInAppAlert() {
    _alertTimer?.cancel();
    if (!mounted || _activeAlert == null) return;
    setState(() => _activeAlert = null);
  }

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

  void _goProfile() => _onTabChanged(4);

  void _onTabChanged(int newIndex) {
    if (newIndex == index && _visitedTabs.contains(newIndex)) return;
    setState(() {
      index = newIndex;
      _visitedTabs.add(newIndex);
    });
  }

  Widget _buildTabPage(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return const HomePage();
      case 1:
        return const ServicesHubPage();
      case 2:
        return const MapPage();
      case 3:
        return const MessagesPage();
      case 4:
        return const _MyProfileTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _notifIconWithBadge() {
    return StreamBuilder<int>(
      stream: NotificationsRepository.instance.streamUnreadCount(),
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: AppTheme.ink,
              size: 24,
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppTheme.orangeDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.6),
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
        final user = snap.data;
        final uid = user?.uid ?? '';
        final fallbackName = (user?.displayName ?? 'PetTounsi').trim();
        final fallbackPhoto = (user?.photoURL ?? '').trim();

        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.outline),
            color: Colors.white,
            boxShadow: AppTheme.softShadows(0.08),
          ),
          padding: const EdgeInsets.all(2),
          child: uid.isEmpty
              ? CircleAvatar(
                  backgroundColor: const Color(0xFFFFEEE8),
                  child: Text(
                    fallbackName.isNotEmpty
                        ? fallbackName.substring(0, 1).toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.orangeDark,
                    ),
                  ),
                )
              : UserAvatar(
                  uid: uid,
                  radius: 19,
                  fallbackName: fallbackName.isEmpty
                      ? 'PetTounsi'
                      : fallbackName,
                  fallbackPhotoUrl: fallbackPhoto.isEmpty
                      ? null
                      : fallbackPhoto,
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(82),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Builder(
                  builder: (drawerContext) => _TopBarWidget(
                    tooltip: 'Menu',
                    onTap: () => Scaffold.of(drawerContext).openDrawer(),
                    child: const Icon(
                      Icons.menu_rounded,
                      color: AppTheme.ink,
                      size: 23,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: index == 0
                      ? const _HomeBrandTitle()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _topLabels[index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _topSubtitles[index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.6,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.muted,
                              ),
                            ),
                          ],
                        ),
                ),
                _TopBarWidget(
                  tooltip: 'Search',
                  onTap: _openSearch,
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.ink,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 10),
                _TopBarWidget(
                  tooltip: 'Notifications',
                  onTap: _openNotifications,
                  child: _notifIconWithBadge(),
                ),
                const SizedBox(width: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _goProfile,
                  child: _profileActionIcon(),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: index,
            children: List<Widget>.generate(_topLabels.length, (tabIndex) {
              if (!_visitedTabs.contains(tabIndex)) {
                return const SizedBox.shrink();
              }
              return KeyedSubtree(
                key: PageStorageKey<String>('main-tab-$tabIndex'),
                child: _buildTabPage(tabIndex),
              );
            }),
          ),
          _InAppAlertHost(alert: _activeAlert, onDismiss: _dismissInAppAlert),
        ],
      ),
      floatingActionButton: (index == 3)
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
            onChanged: _onTabChanged,
          );
        },
      ),
    );
  }
}

class _InAppAlert {
  const _InAppAlert({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _InAppAlertHost extends StatelessWidget {
  const _InAppAlertHost({required this.alert, required this.onDismiss});

  final _InAppAlert? alert;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final current = alert;

    return IgnorePointer(
      ignoring: current == null,
      child: AnimatedSlide(
        offset: current == null ? const Offset(0, -1.2) : Offset.zero,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: current == null ? 0 : 1,
          duration: const Duration(milliseconds: 180),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: current == null
                  ? const SizedBox.shrink()
                  : _InAppAlertCard(alert: current, onDismiss: onDismiss),
            ),
          ),
        ),
      ),
    );
  }
}

class _InAppAlertCard extends StatelessWidget {
  const _InAppAlertCard({required this.alert, required this.onDismiss});

  final _InAppAlert alert;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final subtitle = alert.subtitle.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          onDismiss();
          alert.onTap();
        },
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.outline),
            boxShadow: AppTheme.softShadows(0.18),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1EB),
                  shape: BoxShape.circle,
                ),
                child: Icon(alert.icon, color: AppTheme.orangeDark, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title.trim().isEmpty
                          ? 'New activity'
                          : alert.title.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 13.6,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12.2,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
                onPressed: onDismiss,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppTheme.muted,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBrandTitle extends StatelessWidget {
  const _HomeBrandTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'PetTounsi',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontSize: 20.8,
            fontWeight: FontWeight.w900,
            color: AppTheme.ink,
            height: 1.0,
            letterSpacing: -0.25,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Trusted pet care nearby',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontSize: 12.6,
            fontWeight: FontWeight.w600,
            color: AppTheme.muted,
            height: 1.15,
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.outline),
            boxShadow: AppTheme.softShadows(0.08),
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
      _NavItem(Icons.grid_view_rounded, Icons.grid_view_outlined, 'Services'),
      _NavItem(Icons.location_on_rounded, Icons.location_on_outlined, 'Map'),
      _NavItem(
        Icons.chat_bubble_rounded,
        Icons.chat_bubble_outline_rounded,
        'Messages',
      ),
      _NavItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppTheme.outline),
            boxShadow: AppTheme.softShadows(0.16),
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              return Expanded(
                child: _NavButton(
                  item: items[i],
                  selected: i == index,
                  badgeCount: i == 3 ? unreadMessages : 0,
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
    final fg = selected ? AppTheme.orangeDark : AppTheme.muted;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: selected ? Border.all(color: AppTheme.outline) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: fg,
                  size: 22,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.orangeDark,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1.1),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 8.8,
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
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.6,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                color: fg,
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
        boxShadow: AppTheme.softShadows(0.18),
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
