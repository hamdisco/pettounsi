import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../repositories/block_repository.dart';
import '../../services/connectivity_status_controller.dart';
import '../../ui/app_theme.dart';
import '../../ui/offline_feedback.dart';
import '../../ui/premium_cards.dart';
import '../../ui/premium_feedback.dart';
import '../../ui/user_avatar.dart';
import 'chat_page.dart';
import 'conversation_model.dart';
import 'messages_repository.dart';
import 'new_chat_sheet.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim().toLowerCase();
      if (next == _query) return;
      setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _timeLabel(DateTime? dt) {
    if (dt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  bool _isUnread(ConversationModel c, String myUid) {
    if (myUid.isEmpty || c.lastMessage.trim().isEmpty) return false;

    final readTs = c.lastReadAt[myUid];
    DateTime? readAt;
    if (readTs is Timestamp) readAt = readTs.toDate();

    final lastAt = c.lastMessageAt;
    return readAt == null || (lastAt != null && lastAt.isAfter(readAt));
  }

  String _otherUid(ConversationModel c, String myUid) {
    return c.participants.firstWhere(
      (u) => u != myUid,
      orElse: () => c.participants.isNotEmpty ? c.participants.first : '',
    );
  }

  String _otherName(ConversationModel c, String otherUid) {
    final name = (c.participantNames[otherUid] ?? 'User').toString().trim();
    return name.isEmpty ? 'User' : name;
  }

  String _otherPhoto(ConversationModel c, String otherUid) {
    return (c.participantPhotos[otherUid] ?? '').toString().trim();
  }

  bool _matchesQuery({
    required String name,
    required String lastMessage,
  }) {
    if (_query.isEmpty) return true;
    return name.toLowerCase().contains(_query) ||
        lastMessage.toLowerCase().contains(_query);
  }

  void _openNewChatSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NewChatSheet(),
    );
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
                  limit: 80,
                ),
                builder: (context, snap) {
                  final offline = ConnectivityStatusController.instance.isOffline;

                  if (snap.hasError) {
                    return _MessagesErrorState(
                      onNewMessage: () => _openNewChatSheet(context),
                    );
                  }

                  if (!snap.hasData) {
                    return offline
                        ? _MessagesOfflineState(
                            onNewMessage: () => _openNewChatSheet(context),
                          )
                        : _MessagesLoadingState(
                            onNewMessage: () => _openNewChatSheet(context),
                          );
                  }

                  final allConversations = snap.data ?? const <ConversationModel>[];

                  final visibleConversations = allConversations.where((c) {
                    if (myUid.isEmpty) return true;
                    final otherUid = _otherUid(c, myUid);
                    if (otherUid.isEmpty) return true;
                    return !blocked.contains(otherUid);
                  }).toList();

                  final unreadCount = visibleConversations
                      .where((c) => _isUnread(c, myUid))
                      .length;

                  final filteredConversations = visibleConversations.where((c) {
                    final otherUid = _otherUid(c, myUid);
                    final name = _otherName(c, otherUid);
                    return _matchesQuery(
                      name: name,
                      lastMessage: c.lastMessage,
                    );
                  }).toList();

                  return ListView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 112),
                    children: [
                      _InboxHeader(
                        totalCount: visibleConversations.length,
                        unreadCount: unreadCount,
                        onNewMessage: () => _openNewChatSheet(context),
                      ),
                      if (visibleConversations.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _InboxSearchField(controller: _searchController),
                      ],
                      const SizedBox(height: 12),
                      if (visibleConversations.isEmpty)
                        _EmptyInbox(
                          onNewMessage: () => _openNewChatSheet(context),
                        )
                      else if (filteredConversations.isEmpty)
                        _NoSearchResults(query: _searchController.text)
                      else
                        ...filteredConversations.map((c) {
                          final otherUid = _otherUid(c, myUid);
                          final otherName = _otherName(c, otherUid);
                          final otherPhoto = _otherPhoto(c, otherUid);
                          final unread = _isUnread(c, myUid);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: _ConversationTile(
                              uid: otherUid,
                              name: otherName,
                              photoUrl: otherPhoto,
                              lastMessage: c.lastMessage,
                              timeLabel: _timeLabel(c.lastMessageAt),
                              unread: unread,
                              onTap: otherUid.isEmpty
                                  ? null
                                  : () {
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
  const _InboxHeader({
    required this.totalCount,
    required this.unreadCount,
    required this.onNewMessage,
  });

  final int totalCount;
  final int unreadCount;
  final VoidCallback onNewMessage;

  @override
  Widget build(BuildContext context) {
    final meta = unreadCount > 0
        ? '$unreadCount unread'
        : totalCount == 1
            ? '1 chat'
            : '$totalCount chats';

    return PremiumCardSurface(
      radius: BorderRadius.circular(26),
      padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
      shadowOpacity: 0.08,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 21,
                    height: 1,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      unreadCount > 0
                          ? Icons.mark_chat_unread_rounded
                          : Icons.lock_outline_rounded,
                      size: 14,
                      color: unreadCount > 0
                          ? AppTheme.orangeDark
                          : AppTheme.muted.withAlpha(190),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      meta,
                      style: TextStyle(
                        color: unreadCount > 0
                            ? AppTheme.orangeDark
                            : AppTheme.muted.withAlpha(220),
                        fontWeight: FontWeight.w900,
                        fontSize: 12.3,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppTheme.softOrange,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onNewMessage,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.edit_rounded,
                  color: AppTheme.orangeDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxSearchField extends StatelessWidget {
  const _InboxSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search messages',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.trim().isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Clear',
              onPressed: controller.clear,
              icon: const Icon(Icons.close_rounded),
            );
          },
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppTheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppTheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppTheme.orange, width: 1.2),
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.onNewMessage});

  final VoidCallback onNewMessage;

  @override
  Widget build(BuildContext context) {
    return PremiumEmptyStateCard(
      icon: Icons.chat_bubble_outline_rounded,
      iconColor: AppTheme.orangeDark,
      iconBg: AppTheme.softOrange,
      title: 'No messages yet',
      subtitle: 'Start with someone you follow.',
      primaryLabel: 'New message',
      primaryIcon: Icons.edit_rounded,
      onPrimary: onNewMessage,
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final clean = query.trim();
    return PremiumEmptyStateCard(
      icon: Icons.search_off_rounded,
      iconColor: AppTheme.orangeDark,
      iconBg: AppTheme.softOrange,
      title: 'No conversation found',
      subtitle: clean.isEmpty ? 'Try another search.' : 'No match for "$clean".',
      compact: true,
    );
  }
}

class _MessagesLoadingState extends StatelessWidget {
  const _MessagesLoadingState({required this.onNewMessage});

  final VoidCallback onNewMessage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 112),
      children: [
        _InboxHeader(
          totalCount: 0,
          unreadCount: 0,
          onNewMessage: onNewMessage,
        ),
        const SizedBox(height: 12),
        ...List.generate(
          6,
          (i) => const Padding(
            padding: EdgeInsets.only(bottom: 9),
            child: PremiumSkeletonCard(height: 82, radius: 24),
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isPhoto = lastMessage == '📷 Photo';
    final subtitle = lastMessage.trim().isEmpty
        ? 'Say hello'
        : (isPhoto ? 'Photo' : lastMessage.trim());

    return PremiumCardSurface(
      onTap: onTap,
      radius: BorderRadius.circular(24),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      shadowOpacity: unread ? 0.11 : 0.05,
      borderColor: unread ? AppTheme.softOrange : AppTheme.outline,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(
                uid: uid,
                radius: 26,
                fallbackName: name,
                fallbackPhotoUrl: photoUrl.isEmpty ? null : photoUrl,
              ),
              if (unread)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppTheme.orangeDark,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 2.5),
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
                              ? AppTheme.orangeDark
                              : AppTheme.muted.withAlpha(185),
                          fontWeight: FontWeight.w900,
                          fontSize: 11.4,
                          height: 1,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (isPhoto) ...[
                      Icon(
                        Icons.photo_outlined,
                        size: 14,
                        color: unread
                            ? AppTheme.orangeDark
                            : AppTheme.muted.withAlpha(175),
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
                              ? AppTheme.ink.withAlpha(220)
                              : AppTheme.muted.withAlpha(220),
                          fontWeight: unread ? FontWeight.w900 : FontWeight.w700,
                          fontSize: 12.8,
                          height: 1.12,
                        ),
                      ),
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
  const _MessagesOfflineState({required this.onNewMessage});

  final VoidCallback onNewMessage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 112),
      children: [
        _InboxHeader(
          totalCount: 0,
          unreadCount: 0,
          onNewMessage: onNewMessage,
        ),
        const SizedBox(height: 12),
        const OfflinePageState(
          compact: true,
          title: 'Messages are offline',
          subtitle: 'Reconnect to load your latest chats.',
        ),
      ],
    );
  }
}

class _MessagesErrorState extends StatelessWidget {
  const _MessagesErrorState({required this.onNewMessage});

  final VoidCallback onNewMessage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 112),
      children: [
        _InboxHeader(
          totalCount: 0,
          unreadCount: 0,
          onNewMessage: onNewMessage,
        ),
        const SizedBox(height: 12),
        const PremiumEmptyStateCard(
          icon: Icons.error_outline_rounded,
          iconColor: Color(0xFFE05555),
          iconBg: Color(0xFFFFEBEB),
          title: 'Could not load messages',
          subtitle: 'Check your connection and try again.',
          compact: true,
        ),
      ],
    );
  }
}
