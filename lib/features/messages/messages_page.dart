import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../repositories/block_repository.dart';
import '../../services/connectivity_status_controller.dart';
import '../../ui/app_theme.dart';
import '../../ui/premium_cards.dart';
import '../../ui/premium_feedback.dart';
import '../../ui/offline_feedback.dart';
import '../../ui/user_avatar.dart';
import 'chat_page.dart';
import 'conversation_model.dart';
import 'messages_repository.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  String _timeLabel(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    final myUid = me?.uid ?? '';

    return AnimatedBuilder(
      animation: ConnectivityStatusController.instance,
      builder: (context, _) {
        return Container(
          color: AppTheme.bg,
          child: StreamBuilder<Set<String>>(
            stream: BlockRepository.instance.streamBlockedUids(),
            builder: (context, bSnap) {
              final blocked = bSnap.data ?? <String>{};

              return StreamBuilder<List<ConversationModel>>(
                stream: MessagesRepository.instance.streamMyConversations(
                  limit: 60,
                ),
                builder: (context, snap) {
                  final offline = ConnectivityStatusController.instance.isOffline;
                  if (!snap.hasData) {
                    return offline
                        ? const _MessagesOfflineState()
                        : const _MessagesLoadingState();
                  }

                  final convosAll = snap.data ?? const <ConversationModel>[];

                  final convos = convosAll.where((c) {
                    if (myUid.isEmpty) return true;
                    final otherUid = c.participants.firstWhere(
                      (u) => u != myUid,
                      orElse: () => '',
                    );
                    if (otherUid.isEmpty) return true;
                    return !blocked.contains(otherUid);
                  }).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 112),
                    children: [
                      _InboxHeader(count: convos.length),
                      const SizedBox(height: 12),
                      if (convos.isEmpty)
                        const _EmptyInbox()
                      else
                        ...convos.map((c) {
                          final otherUid = c.participants.firstWhere(
                            (u) => u != myUid,
                            orElse: () => c.participants.isNotEmpty
                                ? c.participants.first
                                : '',
                          );

                          final otherName = (c.participantNames[otherUid] ?? 'User')
                              .toString();
                          final otherPhoto = (c.participantPhotos[otherUid] ?? '')
                              .toString();

                          final readTs = c.lastReadAt[myUid];
                          DateTime? readAt;
                          if (readTs is Timestamp) readAt = readTs.toDate();

                          final lastAt = c.lastMessageAt;
                          final unread =
                              c.lastMessage.isNotEmpty &&
                              (readAt == null ||
                                  (lastAt != null && lastAt.isAfter(readAt)));

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ConversationTile(
                              uid: otherUid,
                              name: otherName,
                              photoUrl: otherPhoto,
                              lastMessage: c.lastMessage,
                              timeLabel: _timeLabel(c.lastMessageAt),
                              unread: unread,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      otherUid: otherUid,
                                      otherName: otherName,
                                      otherPhoto: otherPhoto.isEmpty
                                          ? null
                                          : otherPhoto,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _InboxHeader extends StatelessWidget {
  const _InboxHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return PremiumCardSurface(
      radius: BorderRadius.circular(24),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      shadowOpacity: 0.1,
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Messages',
              style: TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                height: 1,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.lilac,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outline),
            ),
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.chat_bubble_rounded,
                  size: 22,
                  color: Color(0xFF6B56C9),
                ),
                if (count > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppTheme.outline),
                        boxShadow: AppTheme.softShadows(0.08),
                      ),
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6B56C9),
                          fontWeight: FontWeight.w900,
                          fontSize: 11.2,
                          height: 1,
                        ),
                      ),
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

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return const PremiumEmptyStateCard(
      icon: Icons.chat_bubble_outline_rounded,
      iconColor: Color(0xFF7C62D7),
      iconBg: AppTheme.lilac,
      title: 'No messages yet',
      subtitle: 'Follow someone from their profile to start chatting.',
    );
  }
}

class _MessagesLoadingState extends StatelessWidget {
  const _MessagesLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 112),
      children: [
        const _InboxHeader(count: 0),
        const SizedBox(height: 12),
        ...List.generate(
          6,
          (i) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: PremiumSkeletonCard(height: 88, radius: 24),
          ),
        ),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.uid,
    required this.name,
    required this.photoUrl,
    required this.lastMessage,
    required this.timeLabel,
    required this.unread,
    required this.onTap,
  });

  final String uid;
  final String name;
  final String photoUrl;
  final String lastMessage;
  final String timeLabel;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPhoto = lastMessage == '📷 Photo';
    final subtitle = lastMessage.trim().isEmpty
        ? 'Start chatting'
        : (isPhoto ? 'Photo' : lastMessage.trim());

    return PremiumCardSurface(
      onTap: onTap,
      radius: BorderRadius.circular(24),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      shadowOpacity: unread ? 0.13 : 0.08,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(
                uid: uid,
                radius: 27,
                fallbackName: name,
                fallbackPhotoUrl: photoUrl.isEmpty ? null : photoUrl,
              ),
              if (unread)
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C62D7),
                      borderRadius: BorderRadius.circular(999),
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
                  children: [
                    Expanded(
                      child: UserName(
                        uid: uid,
                        fallback: name,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 15.2,
                          height: 1,
                        ),
                      ),
                    ),
                    if (timeLabel.isNotEmpty)
                      Text(
                        timeLabel,
                        style: TextStyle(
                          color: unread
                              ? const Color(0xFF7C62D7)
                              : AppTheme.muted.withAlpha(190),
                          fontWeight: FontWeight.w800,
                          fontSize: 11.6,
                          height: 1,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    if (isPhoto) ...[
                      Icon(
                        Icons.photo_outlined,
                        size: 14,
                        color: unread
                            ? const Color(0xFF7C62D7)
                            : AppTheme.muted.withAlpha(180),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unread
                              ? AppTheme.ink.withAlpha(205)
                              : AppTheme.muted.withAlpha(220),
                          fontWeight:
                              unread ? FontWeight.w800 : FontWeight.w700,
                          fontSize: 12.8,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppTheme.ink.withAlpha(90),
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


class _MessagesOfflineState extends StatelessWidget {
  const _MessagesOfflineState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 112),
      children: const [
        _InboxHeader(count: 0),
        SizedBox(height: 12),
        OfflinePageState(
          compact: true,
          title: 'Messages are unavailable offline',
          subtitle:
              'Reconnect to load your inbox, or wait for saved conversations to appear.',
        ),
      ],
    );
  }
}
