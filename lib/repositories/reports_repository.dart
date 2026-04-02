import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportsRepository {
  ReportsRepository._();
  static final ReportsRepository instance = ReportsRepository._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> reportPost({
    required String postId,
    required String targetUid,
    required String reason,
    String? details,
  }) async {
    final me = _auth.currentUser;
    if (me == null) throw Exception("Not signed in");

    await _db.collection('reports').doc().set({
      'type': 'post',
      'postId': postId,
      'targetUid': targetUid,
      'reporterUid': me.uid,
      'reason': reason.trim(),
      'details': (details ?? '').trim(),
      'createdAt': Timestamp.now(),
      'status': 'open',
    });
  }

  Future<void> reportUser({
    required String targetUid,
    required String reason,
    String? details,
  }) async {
    final me = _auth.currentUser;
    if (me == null) throw Exception("Not signed in");

    await _db.collection('reports').doc().set({
      'type': 'user',
      'targetUid': targetUid,
      'reporterUid': me.uid,
      'reason': reason.trim(),
      'details': (details ?? '').trim(),
      'createdAt': Timestamp.now(),
      'status': 'open',
    });
  }
}
