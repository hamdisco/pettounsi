import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../repositories/notifications_repository.dart';
import '../../services/connectivity_status_controller.dart';
import '../../ui/app_theme.dart';
import '../../ui/premium_cards.dart';
import '../../ui/premium_feedback.dart';
import '../../ui/offline_feedback.dart';
import '../directory/models/directory_item.dart';
import '../events/events_page.dart';
import '../pet_babysitting/pet_babysitting_page.dart';
import '../profile/profile_page.dart';
import 'post_detail_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  String _timeLabel(dynamic createdAt) {
    DateTime? dt;
    if (createdAt is Timestamp) dt = createdAt.toDate();
    if (createdAt is DateTime) dt = createdAt;
    if (dt == null) return '';

    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  String _titleFor(Map<String, dynamic> d) {
    final type = (d['type'] ?? '') as String;
    final name = ((d['actorName'] ?? 'Someone') as String).trim();
    final listingTitle = ((d['listingTitle'] ?? '') as String).trim();
    final eventTitle = ((d['eventTitle'] ?? '') as String).trim();

    switch (type) {
      case 'like':
        return '$name liked your post';
      case 'comment':
        return '$name commented on your post';
      case 'follow':
        return '$name started following you';
      case 'babysitting_request':
        return '$name sent a babysitting request';
      case 'babysitting_accepted':
        return '$name accepted your request';
      case 'babysitting_declined':
        return '$name declined your request';
      case 'babysitting_completed':
        return '$name marked your stay as completed';
      case 'babysitting_canceled':
        return '$name canceled a babysitting request';
      case 'babysitting_review':
        return '$name left a review for ${listingTitle.isEmpty ? 'your listing' : listingTitle}';
      case 'event':
        return eventTitle.isEmpty ? 'Upcoming event' : eventTitle;
      default:
        return 'New activity';
    }
  }

  String _subtitleFor(Map<String, dynamic> d) {
    final type = (d['type'] ?? '') as String;
    final listingTitle = ((d['listingTitle'] ?? '') as String).trim();
    final dateRangeText = ((d['dateRangeText'] ?? '') as String).trim();
    final eventDateLabel = ((d['eventDateLabel'] ?? '') as String).trim();
    final rating = d['rating'];

    switch (type) {
      case 'like':
      case 'comment':
      case 'follow':
        return '';
      case 'babysitting_request':
      case 'babysitting_accepted':
      case 'babysitting_declined':
      case 'babysitting_completed':
      case 'babysitting_canceled':
        if (listingTitle.isNotEmpty && dateRangeText.isNotEmpty) {
          return '$listingTitle • $dateRangeText';
        }
        return listingTitle.isNotEmpty ? listingTitle : dateRangeText;
      case 'babysitting_review':
        if (rating is int || rating is double) {
          return 'Rating ${rating.toString()}/5';
        }
        return listingTitle;
      case 'event':
        return eventDateLabel;
      default:
        return '';
    }
  }

  IconData _iconFor(Map<String, dynamic> d) {
    switch ((d['type'] ?? '') as String) {
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.mode_comment_rounded;
      case 'follow':
        return Icons.person_add_alt_1_rounded;
      case 'babysitting_request':
        return Icons.pets_rounded;
      case 'babysitting_accepted':
        return Icons.check_circle_rounded;
      case 'babysitting_declined':
        return Icons.cancel_rounded;
      case 'babysitting_completed':
        return Icons.verified_rounded;
      case 'babysitting_canceled':
        return Icons.event_busy_rounded;
      case 'babysitting_review':
        return Icons.star_rounded;
      case 'event':
        return Icons.event_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _accentFor(Map<String, dynamic> d) {
    switch ((d['type'] ?? '') as String) {
      case 'like':
        return const Color(0xFFE05555);
      case 'comment':
        return const Color(0xFF4C79C8);
      case 'follow':
        return const Color(0xFF7C62D7);
      case 'babysitting_request':
        return const Color(0xFFDA8A1F);
      case 'babysitting_accepted':
      case 'babysitting_completed':
        return const Color(0xFF2F9A6A);
      case 'babysitting_declined':
      case 'babysitting_canceled':
        return const Color(0xFFE05555);
      case 'babysitting_review':
        return const Color(0xFFF1A90A);
      case 'event':
        return const Color(0xFFF39A63);
      default:
        return AppTheme.orangeDark;
    }
  }

  Color _bgFor(Map<String, dynamic> d) {
    switch ((d['type'] ?? '') as String) {
      case 'like':
      case 'babysitting_declined':
      case 'babysitting_canceled':
        return const Color(0xFFFFEBEB);
      case 'comment':
      case 'event':
        return AppTheme.sky;
      case 'follow':
      case 'babysitting_review':
        return AppTheme.lilac;
      case 'babysitting_request':
        return const Color(0xFFFFF2DB);
      case 'babysitting_accepted':
      case 'babysitting_completed':
        return AppTheme.mint;
      default:
        return AppTheme.sky;
    }
  }

  String _sectionLabel(String type) {
    if (type == 'event') return 'Event';
    if (type.startsWith('babysitting_')) return 'Babysitting';
    return 'Activity';
  }

  Future<void> _openTarget(BuildContext context, Map<String, dynamic> d) async {
    final type = (d['type'] ?? '') as String;
    final postId = (d['postId'] ?? '') as String;
    final actorUid = (d['actorUid'] ?? '') as String;

    if ((type == 'like' || type == 'comment') && postId.trim().isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PostDetailPage(postId: postId.trim())),
      );
      return;
    }

    if (type == 'follow' && actorUid.trim().isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage(uid: actorUid.trim())),
      );
      return;
    }

    if (type.startsWith('babysitting_')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PetBabysittingPage()),
      );
      return;
    }

    if (type == 'event') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EventsPage()),
      );
      return;
    }
  }

  List<Map<String, dynamic>> _buildEventCards(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final items = docs
        .map((d) => DirectoryItem.fromDoc(d, 'events'))
        .where((e) => e.isActive)
        .toList();

    final now = DateTime.now();
    final upcoming = items.where((e) {
      if (e.startsAt == null) return true;
      return e.startsAt!.isAfter(now.subtract(const Duration(days: 1)));
    }).toList();

    upcoming.sort((a, b) {
      final ad = a.startsAt ?? DateTime(2100);
      final bd = b.startsAt ?? DateTime(2100);
      return ad.compareTo(bd);
    });

    return upcoming.take(4).map((e) {
      return <String, dynamic>{
        'id': e.id,
        'type': 'event',
        'eventId': e.id,
        'eventTitle': e.name,
        'eventDateLabel': e.dateLabel,
        'actorPhotoUrl': e.photoUrl ?? '',
        'read': true,
        'createdAt': e.startsAt,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final clamped = mq.copyWith(textScaler: const TextScaler.linear(1.0));

    return MediaQuery(
      data: clamped,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          title: const Text(
            'Notifications',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              tooltip: 'Mark all read',
              onPressed: () async {
                try {
                  await NotificationsRepository.instance.markAllAsRead();
                } catch (_) {}
              },
              icon: const Icon(Icons.done_all_rounded),
            ),
          ],
        ),
        body: AnimatedBuilder(
          animation: ConnectivityStatusController.instance,
          builder: (context, _) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: NotificationsRepository.instance.streamMyNotifications(limit: 80),
              builder: (context, notifSnap) {
                final offline = ConnectivityStatusController.instance.isOffline;

                if (!notifSnap.hasData) {
                  return offline
                      ? const _NotificationsOffline()
                      : const _NotificationsLoading();
                }

                final notifDocs = notifSnap.data!.docs;
                final unreadCount = notifDocs
                    .where((d) => (d.data()['read'] ?? false) == false)
                    .length;

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('events').limit(16).snapshots(),
                  builder: (context, eventSnap) {
                    final eventCards = eventSnap.hasData
                        ? _buildEventCards(eventSnap.data!.docs)
                        : const <Map<String, dynamic>>[];
                    final noCachedEvents = offline && !eventSnap.hasData;

                    if (notifDocs.isEmpty && eventCards.isEmpty) {
                      if (noCachedEvents) {
                        return const _NotificationsOffline();
                      }

                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: PremiumEmptyStateCard(
                            icon: Icons.notifications_none_rounded,
                            iconColor: Color(0xFF4C79C8),
                            iconBg: AppTheme.sky,
                            title: 'No notifications yet',
                            subtitle:
                                'Likes, comments, follows, babysitting activity, and event updates will appear here.',
                          ),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      children: [
                        _InboxSummary(
                          unreadCount: unreadCount,
                          totalCount: notifDocs.length,
                          eventCount: eventCards.length,
                        ),
                        const SizedBox(height: 12),
                        if (eventCards.isNotEmpty || noCachedEvents) ...[
                          const _SectionLabel(
                            title: 'Events',
                            subtitle: 'Upcoming activities and meetups',
                          ),
                          const SizedBox(height: 8),
                          if (noCachedEvents)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: OfflinePageState(
                                compact: true,
                                title: 'Event updates are unavailable offline',
                                subtitle:
                                    'Reconnect to load upcoming meetups or wait for saved events to appear.',
                              ),
                            ),
                          ...eventCards.map(
                            (d) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _NotificationTile(
                                title: _titleFor(d),
                                subtitle: _subtitleFor(d),
                                time: _timeLabel(d['createdAt']),
                                read: true,
                                accent: _accentFor(d),
                                bg: _bgFor(d),
                                leadingIcon: _iconFor(d),
                                actorPhotoUrl: (d['actorPhotoUrl'] ?? '').toString(),
                                section: _sectionLabel((d['type'] ?? '') as String),
                                onTap: () => _openTarget(context, d),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (notifDocs.isNotEmpty) ...[
                          const _SectionLabel(
                            title: 'Activity',
                            subtitle: 'Likes, comments, follows, and requests',
                          ),
                          const SizedBox(height: 8),
                          ...notifDocs.map((doc) {
                            final d = doc.data();
                            final read = (d['read'] ?? false) as bool;
                            final photo = (d['actorPhotoUrl'] ?? '') as String;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Dismissible(
                                key: ValueKey(doc.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE6E6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFD64545),
                                  ),
                                ),
                                onDismissed: (_) => NotificationsRepository.instance.deleteNotification(doc.id),
                                child: _NotificationTile(
                                  title: _titleFor(d),
                                  subtitle: _subtitleFor(d),
                                  time: _timeLabel(d['createdAt']),
                                  read: read,
                                  accent: _accentFor(d),
                                  bg: _bgFor(d),
                                  leadingIcon: _iconFor(d),
                                  actorPhotoUrl: photo,
                                  section: _sectionLabel((d['type'] ?? '') as String),
                                  onTap: () async {
                                    try {
                                      await NotificationsRepository.instance.markAsRead(doc.id);
                                    } catch (_) {}
                                    if (!context.mounted) return;
                                    await _openTarget(context, d);
                                  },
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _InboxSummary extends StatelessWidget {
  const _InboxSummary({
    required this.unreadCount,
    required this.totalCount,
    required this.eventCount,
  });

  final int unreadCount;
  final int totalCount;
  final int eventCount;

  @override
  Widget build(BuildContext context) {
    final summary = unreadCount > 0
        ? '$unreadCount unread'
        : 'All caught up';
    final trailing = <String>[
      if (totalCount > 0) '$totalCount item${totalCount == 1 ? '' : 's'}',
      if (eventCount > 0) '$eventCount event${eventCount == 1 ? '' : 's'}',
    ].join(' • ');

    return PremiumCardSurface(
      radius: BorderRadius.circular(24),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      shadowOpacity: 0.08,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.sky,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outline),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: Color(0xFF4C79C8),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1.05,
                  ),
                ),
                if (trailing.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    trailing,
                    style: TextStyle(
                      color: AppTheme.muted.withAlpha(220),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.blush,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: AppTheme.orangeDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 11.4,
                  height: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.muted.withAlpha(220),
              fontWeight: FontWeight.w700,
              fontSize: 12.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.read,
    required this.accent,
    required this.bg,
    required this.leadingIcon,
    required this.actorPhotoUrl,
    required this.section,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String time;
  final bool read;
  final Color accent;
  final Color bg;
  final IconData leadingIcon;
  final String actorPhotoUrl;
  final String section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = read ? AppTheme.ink.withAlpha(195) : AppTheme.ink;

    return PremiumCardSurface(
      onTap: onTap,
      radius: BorderRadius.circular(22),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      shadowOpacity: read ? 0.06 : 0.1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white),
                ),
                child: CircleAvatar(
                  backgroundColor: bg,
                  backgroundImage: actorPhotoUrl.trim().isNotEmpty
                      ? NetworkImage(actorPhotoUrl.trim())
                      : null,
                  child: actorPhotoUrl.trim().isEmpty
                      ? Icon(leadingIcon, color: accent, size: 22)
                      : null,
                ),
              ),
              if (!read)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                          fontSize: 15,
                          height: 1.15,
                        ),
                      ),
                    ),
                    if (time.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text(
                        time,
                        style: TextStyle(
                          color: AppTheme.muted.withAlpha(210),
                          fontWeight: FontWeight.w800,
                          fontSize: 11.6,
                          height: 1,
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.muted.withAlpha(225),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.4,
                      height: 1.2,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(leadingIcon, size: 13, color: accent),
                          const SizedBox(width: 6),
                          Text(
                            section,
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w900,
                              fontSize: 11.2,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.ink.withAlpha(110),
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsLoading extends StatelessWidget {
  const _NotificationsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: [
        const PremiumSkeletonCard(height: 82, radius: 24),
        const SizedBox(height: 12),
        ...List.generate(
          6,
          (i) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: PremiumSkeletonCard(height: 92, radius: 22),
          ),
        ),
      ],
    );
  }
}


class _NotificationsOffline extends StatelessWidget {
  const _NotificationsOffline();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: const [
        PremiumSkeletonCard(height: 82, radius: 24),
        SizedBox(height: 12),
        OfflinePageState(
          title: 'Notifications are unavailable offline',
          subtitle:
              'Reconnect to load new activity, or wait for saved notifications to appear on this device.',
        ),
      ],
    );
  }
}
