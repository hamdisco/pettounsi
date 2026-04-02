import 'dart:async';
import 'dart:io';
import '../../core/content_safety.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/cloudinary_service.dart';
import 'post_model.dart';

class PostsRepository {
  PostsRepository._();
  static final PostsRepository instance = PostsRepository._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');

  // -----------------------------
  // Identity helpers
  // -----------------------------
  Future<_Actor> _actorFor(User user) async {
    try {
      final snap = await _db.collection('users').doc(user.uid).get();
      final d = snap.data() ?? <String, dynamic>{};

      final name = _pickName(d, user);
      final photo = _pickPhoto(d, user);

      return _Actor(name: name, photoUrl: photo);
    } catch (_) {
      final name = (user.displayName ?? user.email ?? 'User').trim();
      final photo = (user.photoURL ?? '').trim();
      return _Actor(
        name: name.isEmpty ? 'User' : name,
        photoUrl: photo.isEmpty ? null : photo,
      );
    }
  }

  String _pickName(Map<String, dynamic> d, User user) {
    final candidates = <Object?>[
      d['username'],
      d['displayName'],
      user.displayName,
      user.email,
    ];

    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) return c.trim();
    }
    return 'User';
  }

  String? _pickPhoto(Map<String, dynamic> d, User user) {
    final candidates = <Object?>[d['photoUrl'], user.photoURL];
    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) return c.trim();
    }
    return null;
  }

  // -----------------------------
  // Search keywords helper
  // -----------------------------
  List<String> _keywordsFromText(String text) {
    final t = text.toLowerCase();
    final parts = t
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s#]+', unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();

    final keywords = <String>{};
    for (final w in parts) {
      final x = w.trim();
      if (x.length >= 2 && x.length <= 24) keywords.add(x);
    }
    return keywords.take(25).toList();
  }

  // -----------------------------
  // Feeds (simple streams)
  // -----------------------------
  Stream<List<PostModel>> streamLatest({int limit = 30}) {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(PostModel.fromDoc).toList());
  }

  Stream<List<PostModel>> streamByAuthor(String uid, {int limit = 60}) {
    return _posts
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(PostModel.fromDoc).toList());
  }

  /// Kept for compatibility: this is the realtime merged feed (chunked by 10).
  /// Use `streamByAuthorsLive` explicitly in new code.
  Stream<List<PostModel>> streamByAuthors(
    List<String> authorIds, {
    int limitPerChunk = 25,
  }) => streamByAuthorsLive(authorIds, limitPerChunk: limitPerChunk);

  // -----------------------------
  // ✅ BEST BALANCE: Following feed
  // - realtime first page (per chunk)
  // - fetch older pages (no realtime)
  // -----------------------------
  Stream<List<PostModel>> streamByAuthorsLive(
    List<String> authorIds, {
    int limitPerChunk = 12,
  }) {
    if (authorIds.isEmpty) return Stream<List<PostModel>>.value([]);

    final ids = authorIds.toSet().toList();
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, (i + 10) > ids.length ? ids.length : (i + 10)));
    }

    final controller = StreamController<List<PostModel>>.broadcast();
    final subs = <StreamSubscription>[];
    final latestDocs = <String, DocumentSnapshot<Map<String, dynamic>>>{};

    void emit() {
      final posts = latestDocs.values.map((d) => PostModel.fromDoc(d)).toList();
      posts.sort((a, b) {
        final ad = a.createdAt;
        final bd = b.createdAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
      controller.add(posts);
    }

    controller.onListen = () {
      for (final c in chunks) {
        final q = _posts
            .where('authorId', whereIn: c)
            .orderBy('createdAt', descending: true)
            .limit(limitPerChunk);

        subs.add(
          q.snapshots().listen((snap) {
            for (final doc in snap.docs) {
              latestDocs[doc.id] = doc;
            }
            emit();
          }),
        );
      }
    };

    controller.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
      await controller.close();
    };

    return controller.stream;
  }

  /// Fetch older posts (no realtime) for following feed.
  /// Works for ANY number of authors (chunks to 10).
  Future<List<PostModel>> fetchByAuthorsAfter(
    List<String> authorIds, {
    required Timestamp startAfter,
    int limitPerChunk = 12,
  }) async {
    if (authorIds.isEmpty) return [];

    final ids = authorIds.toSet().toList();
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, (i + 10) > ids.length ? ids.length : (i + 10)));
    }

    final futures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
    for (final c in chunks) {
      Query<Map<String, dynamic>> q = _posts
          .where('authorId', whereIn: c)
          .orderBy('createdAt', descending: true)
          .startAfter([startAfter])
          .limit(limitPerChunk);

      futures.add(q.get());
    }

    final snaps = await Future.wait(futures);
    final allDocs = snaps.expand((s) => s.docs).toList();

    // Dedup by id, then sort
    final map = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final d in allDocs) {
      map[d.id] = d;
    }

    final posts = map.values.map(PostModel.fromDoc).toList();
    posts.sort((a, b) {
      final ad = a.createdAt;
      final bd = b.createdAt;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });

    return posts;
  }

  // -----------------------------
  // ✅ Search
  // -----------------------------
  Stream<List<PostModel>> streamSearchByKeyword(
    String keyword, {
    int limit = 40,
  }) {
    final k = keyword.trim().toLowerCase();
    if (k.isEmpty) return Stream<List<PostModel>>.value([]);

    return _posts
        .where('keywords', arrayContains: k)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(PostModel.fromDoc).toList());
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchSearchByKeywordSnap({
    required String keyword,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) {
    final k = keyword.trim().toLowerCase();

    Query<Map<String, dynamic>> q = _posts
        .where('keywords', arrayContains: k)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) q = q.startAfterDocument(startAfter);
    return q.get();
  }

  // -----------------------------
  // ✅ Home pagination helpers
  // -----------------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> streamLatestSnap({
    int limit = 20,
  }) {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchLatestSnap({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) {
    Query<Map<String, dynamic>> q = _posts
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    return q.get();
  }

  // -----------------------------
  // Create post
  // -----------------------------
  // Create post
  // -----------------------------
  Future<void> createPost({
    required String text,
    List<File> imageFiles = const [],
    required String postId,
    required DateTime clientCreatedAt,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');
    ContentSafety.validatePublicText([text], context: 'post');
    final actor = await _actorFor(user);

    final files = imageFiles.take(4).toList();
    final urls = <String>[];

    for (final f in files) {
      final uploaded = await CloudinaryService.instance.uploadImage(f);
      urls.add(uploaded.secureUrl);
    }

    final postRef = _posts.doc();

    await postRef.set({
      'authorId': user.uid,
      'authorName': actor.name,
      'authorPhotoUrl': actor.photoUrl,

      'text': text.trim(),

      'imageUrls': urls,
      'imageUrl': urls.isNotEmpty ? urls.first : null,

      // ✅ keywords for search
      'keywords': _keywordsFromText(text),

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'likeCount': 0,
      'commentCount': 0,
      'lastCommentId': '',
    });
  }

  // -----------------------------
  // Likes
  // -----------------------------
  Stream<bool> streamIsLiked(String postId) {
    final user = _auth.currentUser;
    if (user == null) return Stream<bool>.value(false);

    return _posts
        .doc(postId)
        .collection('likes')
        .doc(user.uid)
        .snapshots()
        .map((d) => d.exists);
  }

  Stream<String?> streamLatestLikerUid(String postId) {
    return _posts
        .doc(postId)
        .collection('likes')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty ? null : snap.docs.first.id);
  }


  Stream<List<String>> streamRecentLikerUids(String postId, {int limit = 80}) {
    return _posts
        .doc(postId)
        .collection('likes')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => d.id.trim())
              .where((id) => id.isNotEmpty)
              .toList(),
        );
  }

  Future<void> toggleLike(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final actor = await _actorFor(user);

    final postRef = _posts.doc(postId);
    final likeRef = postRef.collection('likes').doc(user.uid);

    await _db.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) throw Exception("Post not found");

      final post = postSnap.data()!;
      final authorId = (post['authorId'] ?? '') as String;
      final likeCount = (post['likeCount'] ?? 0) as int;

      final likeSnap = await tx.get(likeRef);
      final isLiking = !likeSnap.exists;

      if (isLiking) {
        tx.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
        tx.update(postRef, {
          'likeCount': likeCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (authorId.isNotEmpty && authorId != user.uid) {
          final notifRef = _db
              .collection('notifications')
              .doc(authorId)
              .collection('items')
              .doc();
          tx.set(notifRef, {
            'type': 'like',
            'toUid': authorId,
            'actorUid': user.uid,
            'actorName': actor.name,
            'actorPhotoUrl': actor.photoUrl,
            'postId': postId,
            'createdAt': Timestamp.now(),
            'read': false,
          });
        }
      } else {
        tx.delete(likeRef);
        tx.update(postRef, {
          'likeCount': (likeCount - 1) < 0 ? 0 : (likeCount - 1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // -----------------------------
  // Comments (existing + pagination helpers)
  // -----------------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> streamComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // ✅ Realtime newest comments (first page)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCommentsSnap(
    String postId, {
    int limit = 25,
  }) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // ✅ Fetch older comments (no realtime → cheaper)
  Future<QuerySnapshot<Map<String, dynamic>>> fetchCommentsSnap(
    String postId, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 25,
  }) {
    Query<Map<String, dynamic>> q = _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) q = q.startAfterDocument(startAfter);
    return q.get();
  }

  Future<void> addComment(String postId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final actor = await _actorFor(user);

    final postRef = _posts.doc(postId);
    final commentRef = postRef.collection('comments').doc();
    final commentId = commentRef.id;

    await _db.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) throw Exception("Post not found");

      final post = postSnap.data()!;
      final authorId = (post['authorId'] ?? '') as String;
      final commentCount = (post['commentCount'] ?? 0) as int;

      final cleaned = text.trim();
      if (cleaned.isEmpty) throw Exception("Empty comment");
      ContentSafety.validatePublicText([cleaned], context: 'comment');

      tx.set(commentRef, {
        'authorId': user.uid,
        'authorName': actor.name,
        'authorPhotoUrl': actor.photoUrl,
        'text': cleaned,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(postRef, {
        'commentCount': commentCount + 1,
        'lastCommentId': commentId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (authorId.isNotEmpty && authorId != user.uid) {
        final notifRef = _db
            .collection('notifications')
            .doc(authorId)
            .collection('items')
            .doc();
        tx.set(notifRef, {
          'type': 'comment',
          'toUid': authorId,
          'actorUid': user.uid,
          'actorName': actor.name,
          'actorPhotoUrl': actor.photoUrl,
          'postId': postId,
          'createdAt': Timestamp.now(),
          'read': false,
        });
      }
    });
  }



  Future<void> editComment(String postId, String commentId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final cleaned = text.trim();
    if (cleaned.isEmpty) throw Exception('Empty comment');
    ContentSafety.validatePublicText([cleaned], context: 'comment');

    final commentRef = _posts.doc(postId).collection('comments').doc(commentId);

    await _db.runTransaction((tx) async {
      final commentSnap = await tx.get(commentRef);
      if (!commentSnap.exists) throw Exception('Comment not found');

      final data = commentSnap.data()!;
      final authorId = (data['authorId'] ?? '') as String;
      if (authorId != user.uid) throw Exception('Not allowed');

      tx.update(commentRef, {
        'text': cleaned,
      });
    });
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final postRef = _posts.doc(postId);
    final commentRef = postRef.collection('comments').doc(commentId);

    await _db.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) throw Exception('Post not found');

      final commentSnap = await tx.get(commentRef);
      if (!commentSnap.exists) throw Exception('Comment not found');

      final comment = commentSnap.data()!;
      final authorId = (comment['authorId'] ?? '') as String;
      if (authorId != user.uid) throw Exception('Not allowed');

      final post = postSnap.data()!;
      final rawCount = post['commentCount'];
      final commentCount = rawCount is int
          ? rawCount
          : rawCount is num
              ? rawCount.toInt()
              : 0;
      if (commentCount <= 0) throw Exception('Invalid comment count');

      tx.update(postRef, {
        'commentCount': commentCount - 1,
        'lastCommentId': commentId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.delete(commentRef);
    });
  }

  Future<void> deletePost(PostModel post) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');
    if (user.uid != post.authorId) throw Exception('Not allowed');

    await _posts.doc(post.id).delete();
  }
}

class _Actor {
  const _Actor({required this.name, required this.photoUrl});
  final String name;
  final String? photoUrl;
}
