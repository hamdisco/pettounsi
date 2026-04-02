import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../repositories/block_repository.dart';
import '../../repositories/follow_repository.dart';
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
  final _t = TextEditingController();

  String? _convoId;
  String? _error;
  bool _blockedByMe = false;
  bool _sendingImage = false;

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
        try {
          await MessagesRepository.instance.markRead(existingId);
        } catch (_) {}
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
      try {
        await MessagesRepository.instance.markRead(id);
      } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Can’t open this chat right now.');
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final id = _convoId;
    if (id == null) return;

    final text = _t.text.trim();
    if (text.isEmpty) return;
    _t.clear();

    try {
      await MessagesRepository.instance.sendText(convoId: id, text: text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message failed. Make sure you follow this user.'),
        ),
      );
    }
  }

  Future<void> _pickAndSendImage() async {
    final id = _convoId;
    if (id == null) return;

    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;

    setState(() => _sendingImage = true);
    try {
      await MessagesRepository.instance.sendImage(
        convoId: id,
        imageFile: File(x.path),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _sendingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(uid: widget.otherUid),
              ),
            );
          },
          child: Row(
            children: [
              UserAvatar(
                uid: widget.otherUid,
                radius: 18,
                fallbackName: widget.otherName,
                fallbackPhotoUrl: widget.otherPhoto,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: UserName(
                  uid: widget.otherUid,
                  fallback: widget.otherName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                    fontSize: 15,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
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
                            colors: [AppTheme.bg, AppTheme.blush],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: StreamBuilder<List<MessageModel>>(
                          stream: MessagesRepository.instance.streamMessages(
                            _convoId!,
                            limit: 140,
                          ),
                          builder: (context, snap) {
                            if (!snap.hasData) {
                              return const _MessagesLoading();
                            }

                            final msgs = snap.data ?? const <MessageModel>[];

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              MessagesRepository.instance.markRead(_convoId!);
                            });

                            if (msgs.isEmpty) {
                              return const _ChatStateCard(
                                icon: Icons.chat_bubble_outline_rounded,
                                title: 'No messages yet',
                                subtitle: 'Send a message.',
                                compact: true,
                              );
                            }

                            return ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                              itemCount: msgs.length,
                              itemBuilder: (context, i) {
                                final m = msgs[i];
                                final mine = m.senderId == myUid;

                                final next = (i + 1 < msgs.length)
                                    ? msgs[i + 1]
                                    : null;
                                final sameAsNext =
                                    next != null && next.senderId == m.senderId;
                                final isGroupTail = !sameAsNext;

                                if (m.type == 'image' &&
                                    (m.imageUrl ?? '').isNotEmpty) {
                                  return Align(
                                    alignment: mine
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: _ImageBubble(
                                      url: m.imageUrl!,
                                      mine: mine,
                                      roundedTail: isGroupTail,
                                      timeLabel: _chatTimeLabel(m.createdAt),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatImageViewerPage(
                                              imageUrl: m.imageUrl!,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }

                                return Align(
                                  alignment: mine
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: _TextBubble(
                                    text: m.text,
                                    mine: mine,
                                    roundedTail: isGroupTail,
                                    timeLabel: _chatTimeLabel(m.createdAt),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    _Composer(
                      controller: _t,
                      sendingImage: _sendingImage,
                      blocked: _blockedByMe,
                      onPickImage: _pickAndSendImage,
                      onSend: _sendText,
                    ),
                  ],
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
    required this.blocked,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final bool sendingImage;
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 10 + bottom),
        child: PremiumCardSurface(
          radius: BorderRadius.circular(22),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          shadowOpacity: 0.10,
          child: Row(
            children: [
              Material(
                color: AppTheme.sky,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: (blocked || sendingImage) ? null : onPickImage,
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
                          : const Icon(
                              Icons.photo_rounded,
                              color: Color(0xFF4C79C8),
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
                  enabled: !blocked,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!blocked) onSend();
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
                      borderSide: const BorderSide(color: AppTheme.outline),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C62D7), Color(0xFFC86B9A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.softShadows(0.10),
                ),
                child: IconButton(
                  onPressed: blocked ? null : onSend,
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  tooltip: 'Send',
                ),
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
        bottomRight: Radius.circular(roundedTail ? 6 : 18),
      );
    }
    return BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
      bottomLeft: Radius.circular(roundedTail ? 6 : 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxWidth: 330),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: mine
            ? const LinearGradient(
                colors: [Color(0xFF7C62D7), Color(0xFFC86B9A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: mine ? null : Colors.white,
        borderRadius: _radius(),
        border: mine ? null : Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.06),
      ),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              color: mine ? Colors.white : AppTheme.ink,
              fontWeight: FontWeight.w700,
              height: 1.25,
              fontSize: 13.1,
            ),
          ),
          if (timeLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              timeLabel,
              style: TextStyle(
                color: mine
                    ? Colors.white.withAlpha(215)
                    : AppTheme.muted.withAlpha(210),
                fontWeight: FontWeight.w800,
                fontSize: 10.2,
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
        bottomRight: Radius.circular(roundedTail ? 6 : 18),
      );
    }
    return BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
      bottomLeft: Radius.circular(roundedTail ? 6 : 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeUrl = Uri.encodeFull(url);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        borderRadius: _radius(),
        border: mine ? null : Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.08),
      ),
      child: ClipRRect(
        borderRadius: _radius(),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.1,
                  child: Image.network(
                    safeUrl,
                    fit: BoxFit.cover,
                    headers: const {'User-Agent': 'Mozilla/5.0'},
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: AppTheme.lilac,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_outlined,
                          color: Color(0xFF7C62D7),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) {
                      return Container(
                        color: AppTheme.lilac,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_rounded,
                          color: AppTheme.muted,
                        ),
                      );
                    },
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
                        fontSize: 10.2,
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
              height: mine ? 62 : 74,
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
          iconColor: const Color(0xFF7C62D7),
          iconBg: AppTheme.lilac,
          title: title,
          subtitle: subtitle,
          compact: compact,
        ),
      ),
    );
  }
}
