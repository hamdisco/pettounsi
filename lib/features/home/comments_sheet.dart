import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/date_formatters.dart';
import '../../repositories/block_repository.dart';
import '../../ui/app_theme.dart';
import '../../ui/premium_feedback.dart';
import '../../ui/user_avatar.dart';
import '../profile/profile_page.dart';
import 'posts_repository.dart';

class CommentsSheet extends StatefulWidget {
  const CommentsSheet({super.key, required this.postId});
  final String postId;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  static const int _pageSize = 25;

  final _scroll = ScrollController();
  final _text = TextEditingController();
  final _inlineEditController = TextEditingController();
  final _inlineEditFocus = FocusNode();

  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _workingCommentId;
  String? _editingCommentId;
  String _editingInitialText = '';

  String? _replyingToCommentId;
  String? _replyingToUid;
  String? _replyingToName;

  final List<DocumentSnapshot<Map<String, dynamic>>> _older = [];

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _text.dispose();
    _inlineEditController.dispose();
    _inlineEditFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || !_hasMore || _loadingMore) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 260) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final cursor = _cursor;
    if (cursor == null) return;

    setState(() => _loadingMore = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(cursor)
          .limit(_pageSize)
          .get();

      if (snap.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _loadingMore = false;
        });
        return;
      }

      _older.addAll(snap.docs);
      _cursor = snap.docs.last;
      if (snap.docs.length < _pageSize) _hasMore = false;
    } catch (_) {
      // ignore paging errors
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;

    FocusScope.of(context).unfocus();
    final replyCommentId = _replyingToCommentId;
    final replyUid = _replyingToUid;
    final replyName = _replyingToName;

    _text.clear();
    _clearReply();

    try {
      await PostsRepository.instance.addComment(
        widget.postId,
        t,
        parentCommentId: replyCommentId,
        replyToUid: replyUid,
        replyToName: replyName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send comment: $e')));
    }
  }

  void _startReply({
    required String commentId,
    required String authorId,
    required String authorName,
  }) {
    final handle = _mentionHandle(authorName);
    final mentionText = handle.isEmpty ? '' : '@$handle ';
    final current = _text.text.trimLeft();

    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUid = authorId.isEmpty ? null : authorId;
      _replyingToName = authorName.trim().isEmpty ? 'User' : authorName.trim();
    });

    if (mentionText.isNotEmpty && !current.startsWith(mentionText)) {
      final next = current.isEmpty ? mentionText : '$mentionText$current';
      _text
        ..text = next
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: next.length),
        );
    }
  }

  void _clearReply() {
    if (!mounted) return;
    setState(() {
      _replyingToCommentId = null;
      _replyingToUid = null;
      _replyingToName = null;
    });
  }

  void _startInlineEdit({required String commentId, required String text}) {
    setState(() {
      _editingCommentId = commentId;
      _editingInitialText = text.trim();
      _inlineEditController
        ..text = text
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _inlineEditFocus.requestFocus();
    });
  }

  void _cancelInlineEdit() {
    setState(() {
      _editingCommentId = null;
      _editingInitialText = '';
      _inlineEditController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _saveInlineEdit(String commentId) async {
    final trimmed = _inlineEditController.text.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment cannot be empty.')));
      return;
    }
    if (trimmed == _editingInitialText) {
      _cancelInlineEdit();
      return;
    }

    setState(() => _workingCommentId = commentId);
    try {
      await PostsRepository.instance.editComment(
        widget.postId,
        commentId,
        trimmed,
      );
      if (!mounted) return;
      setState(() {
        _workingCommentId = null;
        _editingCommentId = null;
        _editingInitialText = '';
        _inlineEditController.clear();
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      setState(() => _workingCommentId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not edit comment: $e')));
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete comment?'),
          content: const Text('This comment will be removed from the post.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.orange),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _workingCommentId = commentId);
    try {
      await PostsRepository.instance.deleteComment(widget.postId, commentId);
      if (!mounted) return;
      setState(() {
        _workingCommentId = null;
        if (_editingCommentId == commentId) {
          _editingCommentId = null;
          _editingInitialText = '';
          _inlineEditController.clear();
        }
        if (_replyingToCommentId == commentId) {
          _replyingToCommentId = null;
          _replyingToUid = null;
          _replyingToName = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _workingCommentId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete comment: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final maxSheetHeight = media.size.height * 0.84;
    final maxListHeight = media.size.height * 0.52;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppTheme.outline),
                    boxShadow: AppTheme.softShadows(0.22),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.ink.withAlpha(18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _CommentsSheetHeader(
                        onClose: () => Navigator.pop(context),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '',
                            style: TextStyle(
                              color: AppTheme.muted.withAlpha(220),
                              fontWeight: FontWeight.w700,
                              fontSize: 12.3,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 14, endIndent: 14),
                      Flexible(
                        fit: FlexFit.loose,
                        child: _buildCommentsArea(maxListHeight),
                      ),
                      _CommentInputBar(
                        uid: _myUid,
                        controller: _text,
                        onSend: _send,
                        replyToName: _replyingToName,
                        onCancelReply: _replyingToName == null
                            ? null
                            : _clearReply,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsArea(double maxListHeight) {
    return StreamBuilder<Set<String>>(
      stream: BlockRepository.instance.streamBlockedUids(),
      builder: (context, blockedSnap) {
        final blocked = blockedSnap.data ?? <String>{};

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .collection('comments')
              .orderBy('createdAt', descending: true)
              .limit(_pageSize)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: SizedBox(
                  height: 220,
                  child: const _CommentsStateCard(
                    icon: Icons.cloud_off_rounded,
                    title: 'Could not load comments',
                    subtitle: 'Please try again.',
                  ),
                ),
              );
            }

            if (!snap.hasData) {
              return const SizedBox(height: 300, child: _CommentsLoading());
            }

            final firstDocs = snap.data!.docs;
            if (_cursor == null && firstDocs.isNotEmpty) {
              _cursor = firstDocs.last;
            }

            final combined = <QueryDocumentSnapshot<Map<String, dynamic>>>[
              ...firstDocs,
              ..._older
                  .whereType<QueryDocumentSnapshot<Map<String, dynamic>>>(),
            ];

            final filtered = combined
                .where((d) {
                  final a = (d.data()['authorId'] ?? '') as String;
                  return a.isEmpty || !blocked.contains(a);
                })
                .toList()
                .reversed
                .toList();

            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: SizedBox(
                  height: 220,
                  child: const _CommentsStateCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No comments yet',
                    subtitle: 'Start the conversation on this post.',
                  ),
                ),
              );
            }

            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxListHeight),
              child: ListView.separated(
                controller: _scroll,
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  if (i == filtered.length) {
                    if (_loadingMore) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                        ),
                      );
                    }
                    return const SizedBox(height: 2);
                  }

                  final doc = filtered[i];
                  final d = doc.data();
                  final commentId = doc.id;
                  final authorId = (d['authorId'] ?? '') as String;
                  final authorName = (d['authorName'] ?? 'User') as String;
                  final authorPhoto = (d['authorPhotoUrl'] ?? '') as String;
                  final text = (d['text'] ?? '') as String;
                  final replyToName = (d['replyToName'] ?? '') as String;

                  DateTime? createdAt;
                  final ts = d['createdAt'];
                  if (ts is Timestamp) createdAt = ts.toDate();

                  return _CommentTile(
                    key: ValueKey(commentId),
                    commentId: commentId,
                    authorId: authorId,
                    authorName: authorName,
                    authorPhoto: authorPhoto,
                    text: text,
                    replyToName: replyToName,
                    createdAt: createdAt,
                    isMine: authorId.isNotEmpty && authorId == _myUid,
                    isWorking: _workingCommentId == commentId,
                    isEditing: _editingCommentId == commentId,
                    editController: _inlineEditController,
                    editFocusNode: _inlineEditFocus,
                    onReply: () => _startReply(
                      commentId: commentId,
                      authorId: authorId,
                      authorName: authorName,
                    ),
                    onStartEdit: () =>
                        _startInlineEdit(commentId: commentId, text: text),
                    onCancelEdit: _cancelInlineEdit,
                    onSaveEdit: () => _saveInlineEdit(commentId),
                    onDelete: () => _deleteComment(commentId),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _CommentsSheetHeader extends StatelessWidget {
  const _CommentsSheetHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 8, 0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.lilac,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white),
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: Color(0xFF7C62D7),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Comments',
              style: TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
                fontSize: 15.8,
                height: 1.0,
              ),
            ),
          ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );
  }
}

class _CommentInputBar extends StatelessWidget {
  const _CommentInputBar({
    required this.uid,
    required this.controller,
    required this.onSend,
    this.replyToName,
    this.onCancelReply,
  });

  final String uid;
  final TextEditingController controller;
  final VoidCallback onSend;
  final String? replyToName;
  final VoidCallback? onCancelReply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.outline),
          boxShadow: AppTheme.softShadows(0.06),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (replyToName != null && replyToName!.trim().isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  decoration: BoxDecoration(
                    color: AppTheme.lilac.withAlpha(110),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF7C62D7).withAlpha(70),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.reply_rounded,
                        size: 18,
                        color: Color(0xFF7C62D7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Replying to $replyToName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.8,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onCancelReply,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        visualDensity: VisualDensity.compact,
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  UserAvatar(uid: uid, radius: 17, fallbackName: 'You'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.mist,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                        decoration: InputDecoration(
                          hintText: replyToName == null
                              ? 'Write a comment'
                              : 'Write a reply',
                          hintStyle: TextStyle(
                            color: AppTheme.muted.withAlpha(190),
                            fontWeight: FontWeight.w700,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: const Color(0xFF7C62D7),
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: onSend,
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    super.key,
    required this.commentId,
    required this.authorId,
    required this.authorName,
    required this.authorPhoto,
    required this.text,
    required this.replyToName,
    required this.createdAt,
    required this.isMine,
    required this.isWorking,
    required this.isEditing,
    required this.editController,
    required this.editFocusNode,
    required this.onReply,
    required this.onStartEdit,
    required this.onCancelEdit,
    required this.onSaveEdit,
    required this.onDelete,
  });

  final String commentId;
  final String authorId;
  final String authorName;
  final String authorPhoto;
  final String text;
  final String replyToName;
  final DateTime? createdAt;
  final bool isMine;
  final bool isWorking;
  final bool isEditing;
  final TextEditingController editController;
  final FocusNode editFocusNode;
  final VoidCallback onReply;
  final VoidCallback onStartEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onSaveEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final timeLabel = createdAt == null ? '' : AppDateFmt.hm(createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            uid: authorId,
            radius: 18,
            fallbackName: authorName,
            fallbackPhotoUrl: authorPhoto,
            onTap: authorId.isEmpty
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(uid: authorId),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isEditing
                    ? Colors.white
                    : (isMine ? AppTheme.mist : Colors.white),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isEditing
                      ? AppTheme.orchidDark.withAlpha(120)
                      : (isMine
                            ? AppTheme.orchid.withAlpha(200)
                            : AppTheme.outline),
                ),
                boxShadow: AppTheme.softShadows(isMine ? 0.05 : 0.04),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: authorId.isEmpty
                                    ? null
                                    : () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ProfilePage(uid: authorId),
                                        ),
                                      ),
                                borderRadius: BorderRadius.circular(10),
                                child: UserName(
                                  uid: authorId,
                                  fallback: authorName,
                                  style: const TextStyle(
                                    color: AppTheme.ink,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13.2,
                                    height: 1.05,
                                  ),
                                ),
                              ),
                              if (timeLabel.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  timeLabel,
                                  style: TextStyle(
                                    color: AppTheme.muted.withAlpha(185),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.3,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isMine)
                          isWorking
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Padding(
                                    padding: EdgeInsets.all(5),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : PopupMenuButton<_CommentAction>(
                                  tooltip: 'Comment options',
                                  splashRadius: 18,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  color: Colors.white,
                                  icon: Icon(
                                    Icons.more_horiz_rounded,
                                    color: AppTheme.muted.withAlpha(210),
                                    size: 20,
                                  ),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: _CommentAction.edit,
                                      enabled: !isEditing,
                                      child: const Text(
                                        'Edit',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: _CommentAction.delete,
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == _CommentAction.edit) {
                                      onStartEdit();
                                    }
                                    if (value == _CommentAction.delete) {
                                      onDelete();
                                    }
                                  },
                                ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (isEditing)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.mist,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.outline),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            child: TextField(
                              controller: editController,
                              focusNode: editFocusNode,
                              minLines: 1,
                              maxLines: 6,
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                                fontSize: 13.6,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Edit your comment',
                                hintStyle: TextStyle(
                                  color: AppTheme.muted.withAlpha(190),
                                  fontWeight: FontWeight.w700,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              TextButton(
                                onPressed: onCancelEdit,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.muted,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 6,
                                  ),
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Cancel'),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: onSaveEdit,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.orchidDark,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 6,
                                  ),
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        ],
                      )
                    else ...[
                      if (replyToName.trim().isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lilac.withAlpha(95),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Replying to $replyToName',
                            style: const TextStyle(
                              color: Color(0xFF7C62D7),
                              fontWeight: FontWeight.w800,
                              fontSize: 11.8,
                            ),
                          ),
                        ),
                      ],
                      _TaggedCommentText(text: text),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onReply,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF7C62D7),
                            minimumSize: const Size(0, 0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.reply_rounded, size: 16),
                          label: const Text(
                            'Reply',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaggedCommentText extends StatelessWidget {
  const _TaggedCommentText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final reg = RegExp(r'(@[^\s]+)|(\s+)|([^@\s]+)', unicode: true);

    for (final match in reg.allMatches(text)) {
      final part = match.group(0) ?? '';
      if (part.isEmpty) continue;

      if (part.startsWith('@')) {
        spans.add(
          TextSpan(
            text: part,
            style: const TextStyle(
              color: Color(0xFF7C62D7),
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: part,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: AppTheme.ink,
          fontWeight: FontWeight.w700,
          height: 1.34,
          fontSize: 13.4,
        ),
        children: spans,
      ),
    );
  }
}

enum _CommentAction { edit, delete }

class _CommentsLoading extends StatelessWidget {
  const _CommentsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: 7,
      itemBuilder: (context, i) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: PremiumSkeletonCard(
            height: 76,
            radius: 20,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppTheme.lilac,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      PremiumSkeletonLine(width: 92, height: 11),
                      SizedBox(height: 10),
                      PremiumSkeletonLine(width: 220, height: 11),
                      SizedBox(height: 8),
                      PremiumSkeletonLine(width: 160, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CommentsStateCard extends StatelessWidget {
  const _CommentsStateCard({
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
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: PremiumEmptyStateCard(
          icon: icon,
          iconColor: const Color(0xFF7C62D7),
          iconBg: AppTheme.lilac,
          title: title,
          subtitle: subtitle,
          compact: true,
        ),
      ),
    );
  }
}

String _mentionHandle(String input) {
  final normalized = input.trim().replaceAll(RegExp(r'\s+'), '_');
  final cleaned = normalized.replaceAll(
    RegExp(r'[^\p{L}\p{N}_.]', unicode: true),
    '',
  );
  return cleaned;
}
