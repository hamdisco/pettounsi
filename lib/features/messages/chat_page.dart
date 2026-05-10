import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../repositories/block_repository.dart';
import '../../repositories/follow_repository.dart';
import '../../ui/adaptive_cached_image.dart';
import '../../ui/app_theme.dart';
import '../../ui/premium_cards.dart';
import '../../ui/premium_feedback.dart';
import '../../ui/user_avatar.dart';
import '../profile/profile_page.dart';
import 'image_viewer_page.dart';
import 'message_model.dart';
import 'messages_repository.dart';

String _chatTimeLabel(DateTime? dt) {
  if (dt == null) return '';
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _chatDayLabel(DateTime? dt) {
  if (dt == null) return '';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(day).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';

  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  return '$d/$m/${dt.year}';
}

bool _sameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.otherUid,
    required this.otherName,
    this.otherPhoto,
  });

  final String otherUid;
  final String otherName;
  final String? otherPhoto;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textController = TextEditingController();

  String? _convoId;
  String? _error;
  bool _blockedByMe = false;
  bool _sendingImage = false;
  bool _sendingText = false;
  bool _markReadQueued = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final blocked = await BlockRepository.instance.isBlockedByMe(
        widget.otherUid,
      );
      if (!mounted) return;

      setState(() => _blockedByMe = blocked);
      if (blocked) {
        setState(() => _error = 'You blocked this user. Unblock to chat.');
        return;
      }

      final me = FirebaseAuth.instance.currentUser;
      if (me == null) {
        setState(() => _error = 'Please sign in again.');
        return;
      }

      final existingId = MessagesRepository.instance.dmId(
        me.uid,
        widget.otherUid,
      );
      final existingSnap = await MessagesRepository.instance
          .convoRef(existingId)
          .get();

      if (existingSnap.exists) {
        if (!mounted) return;
        setState(() => _convoId = existingId);
        _queueMarkRead();
        return;
      }

      final canStart = await FollowRepository.instance.isFollowingOnce(
        widget.otherUid,
      );
      if (!canStart) {
        if (!mounted) return;
        setState(() => _error = 'Follow this user to start a chat.');
        return;
      }

      final id = await MessagesRepository.instance.ensureDm(
        otherUid: widget.otherUid,
        otherName: widget.otherName,
        otherPhoto: widget.otherPhoto,
      );

      if (!mounted) return;
      setState(() => _convoId = id);
      _queueMarkRead();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Can’t open this chat right now.');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _queueMarkRead() {
    final id = _convoId;
    if (id == null || _markReadQueued) return;

    _markReadQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await MessagesRepository.instance.markRead(id);
      } catch (_) {
        // Keep the chat usable even if the read receipt update fails.
      } finally {
        _markReadQueued = false;
      }
    });
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(uid: widget.otherUid),
      ),
    );
  }

  Future<void> _sendText() async {
    final id = _convoId;
    if (id == null || _sendingText || _blockedByMe) return;

    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() => _sendingText = true);

    try {
      await MessagesRepository.instance.sendText(convoId: id, text: text);
    } catch (_) {
      if (!mounted) return;
      _textController.text = text;
      _textController.selection = TextSelection.collapsed(offset: text.length);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message not sent. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _sendingText = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final id = _convoId;
    if (id == null || _sendingImage || _blockedByMe) return;

    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (x == null) return;

    setState(() => _sendingImage = true);
    try {
      await MessagesRepository.instance.sendImage(
        convoId: id,
        imageFile: File(x.path),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo not sent. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _sendingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        titleSpacing: 0,
        title: _ChatAppBarTitle(
          uid: widget.otherUid,
          name: widget.otherName,
          photoUrl: widget.otherPhoto,
          onTap: _openProfile,
        ),
        actions: [
          IconButton(
            tooltip: 'View profile',
            onPressed: _openProfile,
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),
      body: _error != null
          ? _ChatStateCard(
              icon: _blockedByMe
                  ? Icons.block_rounded
                  : Icons.chat_bubble_outline_rounded,
              title: 'Chat unavailable',
              subtitle: _error!,
            )
          : (_convoId == null)
              ? const _ChatLoadingState()
              : Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.bg, Color(0xFFFFF5F0)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: StreamBuilder<List<MessageModel>>(
                          stream: MessagesRepository.instance.streamMessages(
                            _convoId!,
                            limit: 160,
                          ),
                          builder: (context, snap) {
                            if (snap.hasError) {
                              return const _ChatStateCard(
                                icon: Icons.error_outline_rounded,
                                title: 'Could not load messages',
                                subtitle: 'Check your connection and try again.',
                                compact: true,
                              );
                            }

                            if (!snap.hasData) {
                              return const _MessagesLoading();
                            }

                            final messages = snap.data ?? const <MessageModel>[];
                            _queueMarkRead();

                            if (messages.isEmpty) {
                              return const _ChatStateCard(
                                icon: Icons.pets_rounded,
                                title: 'Start the conversation',
                                subtitle: 'Send a friendly message when you’re ready.',
                                compact: true,
                              );
                            }

                            return ListView.builder(
                              reverse: true,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final mine = message.senderId == myUid;

                                final olderMessage = index + 1 < messages.length
                                    ? messages[index + 1]
                                    : null;
                                final newerMessage = index > 0
                                    ? messages[index - 1]
                                    : null;

                                final sameAsOlder = olderMessage != null &&
                                    olderMessage.senderId == message.senderId &&
                                    _sameDay(
                                      olderMessage.createdAt,
                                      message.createdAt,
                                    );
                                final roundedTail = !sameAsOlder;

                                final showDayLabel = newerMessage == null ||
                                    !_sameDay(
                                      newerMessage.createdAt,
                                      message.createdAt,
                                    );

                                return _MessageCluster(
                                  showDayLabel: showDayLabel,
                                  dayLabel: _chatDayLabel(message.createdAt),
                                  child: Align(
                                    alignment: mine
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: message.type == 'image' &&
                                            (message.imageUrl ?? '').isNotEmpty
                                        ? _ImageBubble(
                                            url: message.imageUrl!,
                                            mine: mine,
                                            roundedTail: roundedTail,
                                            timeLabel:
                                                _chatTimeLabel(message.createdAt),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ChatImageViewerPage(
                                                    imageUrl: message.imageUrl!,
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                        : _TextBubble(
                                            text: message.text,
                                            mine: mine,
                                            roundedTail: roundedTail,
                                            timeLabel:
                                                _chatTimeLabel(message.createdAt),
                                          ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    _Composer(
                      controller: _textController,
                      sendingImage: _sendingImage,
                      sendingText: _sendingText,
                      blocked: _blockedByMe,
                      onPickImage: _pickAndSendImage,
                      onSend: _sendText,
                    ),
                  ],
                ),
    );
  }
}

class _ChatAppBarTitle extends StatelessWidget {
  const _ChatAppBarTitle({
    required this.uid,
    required this.name,
    required this.photoUrl,
    required this.onTap,
  });

  final String uid;
  final String name;
  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Row(
        children: [
          UserAvatar(
            uid: uid,
            radius: 18,
            fallbackName: name,
            fallbackPhotoUrl: photoUrl,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                UserName(
                  uid: uid,
                  fallback: name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                    fontSize: 15,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Private chat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.muted.withAlpha(210),
                    fontWeight: FontWeight.w800,
                    fontSize: 11.2,
                    height: 1,
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

class _MessageCluster extends StatelessWidget {
  const _MessageCluster({
    required this.showDayLabel,
    required this.dayLabel,
    required this.child,
  });

  final bool showDayLabel;
  final String dayLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDayLabel && dayLabel.isNotEmpty) ...[
          const SizedBox(height: 8),
          _DaySeparator(label: dayLabel),
          const SizedBox(height: 10),
        ],
        child,
      ],
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(230),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppTheme.muted.withAlpha(220),
            fontWeight: FontWeight.w900,
            fontSize: 10.8,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onPickImage,
    required this.sendingImage,
    required this.sendingText,
    required this.blocked,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final bool sendingImage;
  final bool sendingText;
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: PremiumCardSurface(
          radius: BorderRadius.circular(24),
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          shadowOpacity: 0.08,
          child: Row(
            children: [
              Material(
                color: blocked || sendingImage ? AppTheme.mist : AppTheme.sky,
                borderRadius: BorderRadius.circular(17),
                child: InkWell(
                  borderRadius: BorderRadius.circular(17),
                  onTap: (blocked || sendingImage || sendingText)
                      ? null
                      : onPickImage,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: sendingImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.photo_rounded,
                              color: blocked
                                  ? AppTheme.muted.withAlpha(150)
                                  : const Color(0xFF4C79C8),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  enabled: !blocked && !sendingText,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!blocked && !sendingText) onSend();
                  },
                  decoration: InputDecoration(
                    hintText: blocked ? 'You blocked this user' : 'Message',
                    filled: true,
                    fillColor: AppTheme.mist,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppTheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppTheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppTheme.orange),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final canSend = !blocked &&
                      !sendingText &&
                      value.text.trim().isNotEmpty;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: canSend ? null : AppTheme.mist,
                      gradient: canSend
                          ? const LinearGradient(
                              colors: [AppTheme.orange, AppTheme.orangeDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: canSend ? Colors.transparent : AppTheme.outline,
                      ),
                      boxShadow: canSend ? AppTheme.softShadows(0.10) : null,
                    ),
                    child: IconButton(
                      onPressed: canSend ? onSend : null,
                      icon: sendingText
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: canSend
                                  ? Colors.white
                                  : AppTheme.muted.withAlpha(150),
                            ),
                      tooltip: 'Send',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({
    required this.text,
    required this.mine,
    required this.roundedTail,
    required this.timeLabel,
  });

  final String text;
  final bool mine;
  final bool roundedTail;
  final String timeLabel;

  BorderRadius _radius() {
    if (mine) {
      return BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: const Radius.circular(18),
        bottomRight: Radius.circular(roundedTail ? 7 : 18),
      );
    }
    return BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
      bottomLeft: Radius.circular(roundedTail ? 7 : 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.76;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
      decoration: BoxDecoration(
        gradient: mine
            ? const LinearGradient(
                colors: [AppTheme.orange, AppTheme.orangeDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: mine ? null : Colors.white,
        borderRadius: _radius(),
        border: mine ? null : Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(mine ? 0.06 : 0.04),
      ),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              color: mine ? Colors.white : AppTheme.ink,
              fontWeight: FontWeight.w700,
              height: 1.28,
              fontSize: 13.4,
            ),
          ),
          if (timeLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              timeLabel,
              style: TextStyle(
                color: mine
                    ? Colors.white.withAlpha(220)
                    : AppTheme.muted.withAlpha(205),
                fontWeight: FontWeight.w800,
                fontSize: 10.1,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  const _ImageBubble({
    required this.url,
    required this.mine,
    required this.roundedTail,
    required this.timeLabel,
    required this.onTap,
  });

  final String url;
  final bool mine;
  final bool roundedTail;
  final String timeLabel;
  final VoidCallback onTap;

  BorderRadius _radius() {
    if (mine) {
      return BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: const Radius.circular(18),
        bottomRight: Radius.circular(roundedTail ? 7 : 18),
      );
    }
    return BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
      bottomLeft: Radius.circular(roundedTail ? 7 : 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeUrl = Uri.encodeFull(url);
    final maxWidth = MediaQuery.of(context).size.width * 0.68;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        borderRadius: _radius(),
        border: mine ? null : Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.06),
      ),
      child: ClipRRect(
        borderRadius: _radius(),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.04,
                  child: AdaptiveCachedImage(
                    imageUrl: safeUrl,
                    fit: BoxFit.cover,
                    fallbackHeight: 254,
                    maxCacheDimension: 720,
                    httpHeaders: const {'User-Agent': 'Mozilla/5.0'},
                    placeholder: Container(
                      color: AppTheme.softOrange,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppTheme.orangeDark,
                      ),
                    ),
                    errorWidget: Container(
                      color: AppTheme.softOrange,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: AppTheme.muted,
                      ),
                    ),
                  ),
                ),
                if (timeLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Text(
                      timeLabel,
                      style: TextStyle(
                        color: AppTheme.muted.withAlpha(210),
                        fontWeight: FontWeight.w800,
                        fontSize: 10.1,
                        height: 1,
                      ),
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

class _ChatLoadingState extends StatelessWidget {
  const _ChatLoadingState();

  @override
  Widget build(BuildContext context) {
    return const _ChatStateCard(
      icon: Icons.sync_rounded,
      title: 'Loading chat',
      subtitle: 'Please wait.',
      compact: true,
    );
  }
}

class _MessagesLoading extends StatelessWidget {
  const _MessagesLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: 8,
      itemBuilder: (_, i) {
        final mine = i.isEven;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PremiumSkeletonCard(
              height: mine ? 58 : 72,
              radius: 20,
              padding: const EdgeInsets.all(10),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

class _ChatStateCard extends StatelessWidget {
  const _ChatStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: PremiumEmptyStateCard(
          icon: icon,
          iconColor: AppTheme.orangeDark,
          iconBg: AppTheme.softOrange,
          title: title,
          subtitle: subtitle,
          compact: compact,
        ),
      ),
    );
  }
}
