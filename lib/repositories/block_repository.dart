import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockRepository {
  BlockRepository._();
  static final BlockRepository instance = BlockRepository._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _myBlocksRef(String myUid) {
    return _db.collection('blocks').doc(myUid).collection('users');
  }

  Stream<Set<String>> streamBlockedUids() {
    final me = _auth.currentUser;
    if (me == null) return Stream<Set<String>>.value({});
    return _myBlocksRef(
      me.uid,
    ).snapshots().map((s) => s.docs.map((d) => d.id).toSet());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMyBlockedDocs() {
    final me = _auth.currentUser;
    if (me == null) return const Stream.empty();
    return _db
        .collection('blocks')
        .doc(me.uid)
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<bool> isBlockedByMe(String otherUid) async {
    final me = _auth.currentUser;
    if (me == null) return false;
    final doc = await _myBlocksRef(me.uid).doc(otherUid).get();
    return doc.exists;
  }

  Future<void> block(String otherUid) async {
    final me = _auth.currentUser;
    if (me == null) throw Exception("Not signed in");

    await _myBlocksRef(
      me.uid,
    ).doc(otherUid).set({'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> unblock(String otherUid) async {
    final me = _auth.currentUser;
    if (me == null) throw Exception("Not signed in");

    await _myBlocksRef(me.uid).doc(otherUid).delete();
  }
}
