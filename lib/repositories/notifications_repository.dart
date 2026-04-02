import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsRepository {
  NotificationsRepository._();
  static final NotificationsRepository instance = NotificationsRepository._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _itemsRef(String uid) {
    return _db.collection('notifications').doc(uid).collection('items');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMyNotifications({
    int limit = 60,
  }) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _itemsRef(
      user.uid,
    ).orderBy('createdAt', descending: true).limit(limit).snapshots();
  }

  Stream<int> streamUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream<int>.value(0);

    return _itemsRef(
      user.uid,
    ).where('read', isEqualTo: false).snapshots().map((s) => s.size);
  }

  Future<void> markAsRead(String notifId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _itemsRef(user.uid).doc(notifId).update({'read': true});
  }

  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snap = await _itemsRef(
      user.uid,
    ).where('read', isEqualTo: false).get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notifId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _itemsRef(user.uid).doc(notifId).delete();
  }
}
