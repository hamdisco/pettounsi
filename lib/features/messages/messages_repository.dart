import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/content_safety.dart';
import '../../repositories/follow_repository.dart';
import '../../services/cloudinary_service.dart';
import 'conversation_model.dart';
import 'message_model.dart';

class MessagesRepository {
  MessagesRepository._();
  static final MessagesRepository instance = MessagesRepository._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String dmId(String a, String b) {
    final ids = [a, b]..sort();
    return 'dm_${ids[0]}_${ids[1]}';
  }

  DocumentReference<Map<String, dynamic>> convoRef(String convoId) =>
      _db.collection('conversations').doc(convoId);

  CollectionReference<Map<String, dynamic>> messagesRef(String convoId) =>
      convoRef(convoId).collection('messages');

  Stream<List<ConversationModel>> streamMyConversations({int limit = 50}) {
    final me = _auth.currentUser;
    if (me == null) return const Stream.empty();

    return _db
        .collection('conversations')
        .where('participants', arrayContains: me.uid)
        .orderBy('lastMessageAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(ConversationModel.fromDoc).toList());
  }

  Stream<int> streamUnreadConversationCount({int limit = 60}) {
    final me = _auth.currentUser;
    if (me == null) return Stream.value(0);

    return streamMyConversations(limit: limit).map((convos) {
      var unread = 0;

      for (final c in convos) {
        final readTs = c.lastReadAt[me.uid];
        DateTime? readAt;
        if (readTs is Timestamp) readAt = readTs.toDate();

        final lastAt = c.lastMessageAt;
        final hasUnread =
            c.lastMessage.isNotEmpty &&
            (readAt == null || (lastAt != null && lastAt.isAfter(readAt)));

        if (hasUnread) unread++;
      }

      return unread;
    });
  }

  Future<String> ensureDm({
    required String otherUid,
    required String otherName,
    String? otherPhoto,
  }) async {
    final me = _auth.currentUser;
    if (me == null) throw Exception('Not signed in');
    if (me.uid == otherUid) throw Exception('Cannot message yourself.');

    // ✅ Instagram-like: you can start a chat only with users you follow.
    final canStart = await FollowRepository.instance.isFollowingOnce(otherUid);
    if (!canStart) {
      throw Exception('Follow this user to send messages.');
    }

    final id = dmId(me.uid, otherUid);
    final ref = convoRef(id);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) return;

      final parts = [me.uid, otherUid]..sort();

      tx.set(ref, {
        'participants': parts,
        'starterUid': me.uid,
        'starterAt': FieldValue.serverTimestamp(),
        'participantNames': {
          me.uid: me.displayName ?? 'User',
          otherUid: otherName,
        },
        'participantPhotos': {
          me.uid: me.photoURL ?? '',
          otherUid: otherPhoto ?? '',
        },
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastReadAt': {me.uid: FieldValue.serverTimestamp()},
      });
    });

    return id;
  }

  Stream<List<MessageModel>> streamMessages(String convoId, {int limit = 80}) {
    return messagesRef(convoId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(MessageModel.fromDoc).toList());
  }

  Future<void> markRead(String convoId) async {
    final me = _auth.currentUser;
    if (me == null) return;

    await convoRef(convoId).update({
      'lastReadAt.${me.uid}': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendText({required String convoId, required String text}) async {
    final me = _auth.currentUser;
    if (me == null) throw Exception('Not signed in');

    final t = text.trim();
    if (t.isEmpty) return;
    ContentSafety.validatePublicText([t], context: 'message');
    final convo = convoRef(convoId);
    final msg = messagesRef(convoId).doc();

    final batch = _db.batch();
    batch.set(msg, {
      'senderId': me.uid,
      'type': 'text',
      'text': t,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(convo, {
      'lastMessage': t,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastReadAt.${me.uid}': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> sendImage({
    required String convoId,
    required File imageFile,
  }) async {
    final me = _auth.currentUser;
    if (me == null) throw Exception('Not signed in');

    // Upload to Cloudinary (no Firebase Storage needed)
    final uploaded = await CloudinaryService.instance.uploadImage(imageFile);
    final url = uploaded.secureUrl;

    final convo = convoRef(convoId);
    final msg = messagesRef(convoId).doc();

    final batch = _db.batch();

    batch.set(msg, {
      'senderId': me.uid,
      'type': 'image',
      'text': '',
      'imageUrl': url,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(convo, {
      'lastMessage': '📷 Photo',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastReadAt.${me.uid}': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
