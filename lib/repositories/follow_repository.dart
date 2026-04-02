import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowRepository {
  FollowRepository._();
  static final FollowRepository instance = FollowRepository._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _followingDoc(
    String me,
    String target,
  ) => _db.collection('follows').doc(me).collection('following').doc(target);

  DocumentReference<Map<String, dynamic>> _followerDoc(
    String target,
    String me,
  ) => _db.collection('follows').doc(target).collection('followers').doc(me);

  Future<Map<String, String>> _resolveMyMeta(User user) async {
    try {
      final snap = await _db.collection('users').doc(user.uid).get();
      final d = snap.data() ?? {};
      final name = (d['username'] ?? user.displayName ?? 'User').toString().trim();
      final photo = (d['photoUrl'] ?? user.photoURL ?? '').toString().trim();
      return {
        'name': name.isEmpty ? 'User' : name,
        'photo': photo,
      };
    } catch (_) {
      final name = (user.displayName ?? 'User').toString().trim();
      final photo = (user.photoURL ?? '').toString().trim();
      return {
        'name': name.isEmpty ? 'User' : name,
        'photo': photo,
      };
    }
  }

  Stream<Set<String>> streamMyFollowingUids() {
    final me = _auth.currentUser;
    if (me == null) return Stream<Set<String>>.value({});
    return _db
        .collection('follows')
        .doc(me.uid)
        .collection('following')
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toSet());
  }

  Stream<bool> streamIsFollowing(String targetUid) {
    final me = _auth.currentUser;
    if (me == null) return Stream<bool>.value(false);
    return _followingDoc(me.uid, targetUid).snapshots().map((d) => d.exists);
  }

  Future<bool> isFollowingOnce(String targetUid) async {
    final me = _auth.currentUser;
    if (me == null) return false;
    final snap = await _followingDoc(me.uid, targetUid).get();
    return snap.exists;
  }

  Stream<int> streamFollowersCount(String uid) {
    return _db
        .collection('follows')
        .doc(uid)
        .collection('followers')
        .snapshots()
        .map((s) => s.size);
  }

  Stream<int> streamFollowingCount(String uid) {
    return _db
        .collection('follows')
        .doc(uid)
        .collection('following')
        .snapshots()
        .map((s) => s.size);
  }

  /// Follow a user and (client-only) create a "follow" notification.
  /// No Cloud Functions required.
  ///
  /// IMPORTANT: Notification create is written in the same batch as the follow
  /// docs to satisfy the anti-spam security rule (existsAfter checks).
  Future<void> follow({required String targetUid}) async {
    final me = _auth.currentUser;
    if (me == null) throw Exception('Not signed in');
    if (me.uid == targetUid) return;

    // Guard: if already following, do nothing (prevents duplicate notifications).
    final already = await isFollowingOnce(targetUid);
    if (already) return;

    final meta = await _resolveMyMeta(me);

    final batch = _db.batch();
    final now = Timestamp.now();

    batch.set(_followingDoc(me.uid, targetUid), {
      'uid': targetUid,
      'createdAt': now,
    });
    batch.set(_followerDoc(targetUid, me.uid), {
      'uid': me.uid,
      'createdAt': now,
    });

    // ✅ Follow notification
    final notifRef = _db
        .collection('notifications')
        .doc(targetUid)
        .collection('items')
        .doc();

    batch.set(notifRef, {
      'type': 'follow',
      'toUid': targetUid,
      'actorUid': me.uid,
      'actorName': meta['name'],
      'actorPhotoUrl': meta['photo'],
      'createdAt': now,
      'read': false,
    });

    await batch.commit();
  }

  Future<void> unfollow(String targetUid) async {
    final me = _auth.currentUser;
    if (me == null) throw Exception('Not signed in');
    if (me.uid == targetUid) return;

    final batch = _db.batch();
    batch.delete(_followingDoc(me.uid, targetUid));
    batch.delete(_followerDoc(targetUid, me.uid));
    await batch.commit();
  }
}
