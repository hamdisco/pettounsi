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

  String displayTitleFor(Map<String, dynamic> data) {
    final storedTitle =
        ((data['notificationTitle'] ?? data['title'] ?? '') as String?)
            ?.trim() ??
        '';
    if (storedTitle.isNotEmpty) return storedTitle;

    final type = ((data['type'] ?? '') as String?)?.trim() ?? '';
    final actorName = ((data['actorName'] ?? 'Someone') as String?)?.trim();
    final name = (actorName == null || actorName.isEmpty)
        ? 'Someone'
        : actorName;
    final listingTitle = ((data['listingTitle'] ?? '') as String?)?.trim() ?? '';
    final eventTitle = ((data['eventTitle'] ?? '') as String?)?.trim() ?? '';

    switch (type) {
      case 'like':
        return '$name liked your post';
      case 'comment':
        return '$name commented on your post';
      case 'follow':
        return '$name started following you';
      case 'message':
        return '$name sent you a message';
      case 'babysitting_request':
        return '$name sent a stay request';
      case 'babysitting_accepted':
        return '$name accepted your stay request';
      case 'babysitting_declined':
        return '$name declined your stay request';
      case 'babysitting_completed':
        return '$name marked the stay completed';
      case 'babysitting_booking_canceled':
        return '$name canceled a confirmed stay';
      case 'babysitting_canceled':
        return '$name canceled a stay request';
      case 'babysitting_review':
        return listingTitle.isEmpty
            ? '$name left a review'
            : '$name left a review for $listingTitle';
      case 'event':
        return eventTitle.isEmpty ? 'Event update' : eventTitle;
      default:
        return 'New activity';
    }
  }

  String displayBodyFor(Map<String, dynamic> data) {
    final storedBody = ((data['notificationBody'] ?? data['body'] ?? '')
                as String?)
            ?.trim() ??
        '';
    if (storedBody.isNotEmpty) return storedBody;

    final type = ((data['type'] ?? '') as String?)?.trim() ?? '';
    final listingTitle = ((data['listingTitle'] ?? '') as String?)?.trim() ?? '';
    final dateRangeText =
        ((data['dateRangeText'] ?? '') as String?)?.trim() ?? '';
    final eventDateLabel =
        ((data['eventDateLabel'] ?? '') as String?)?.trim() ?? '';
    final messagePreview =
        ((data['messagePreview'] ?? '') as String?)?.trim() ?? '';
    final rating = data['rating'];

    switch (type) {
      case 'babysitting_request':
      case 'babysitting_accepted':
      case 'babysitting_declined':
      case 'babysitting_completed':
      case 'babysitting_booking_canceled':
      case 'babysitting_canceled':
        if (listingTitle.isNotEmpty && dateRangeText.isNotEmpty) {
          return '$listingTitle • $dateRangeText';
        }
        return listingTitle.isNotEmpty ? listingTitle : dateRangeText;
      case 'babysitting_review':
        if (rating is int || rating is double) return 'Rating $rating/5';
        return listingTitle;
      case 'event':
        return eventDateLabel;
      case 'message':
        return messagePreview;
      default:
        return '';
    }
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
