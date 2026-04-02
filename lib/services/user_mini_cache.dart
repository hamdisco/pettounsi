import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class UserMini {
  const UserMini({
    required this.uid,
    required this.name,
    required this.photoUrl,
  });

  final String uid;
  final String name;
  final String photoUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserMini &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          name == other.name &&
          photoUrl == other.photoUrl;

  @override
  int get hashCode => Object.hash(uid, name, photoUrl);
}

class UserMiniCache {
  UserMiniCache._();
  static final instance = UserMiniCache._();

  final _db = FirebaseFirestore.instance;

  final Map<String, Stream<UserMini?>> _streams = {};
  final Map<String, UserMini?> _last = {};

  UserMini? peek(String uid) => _last[uid];

  Stream<UserMini?> stream(String uid) {
    final id = uid.trim();
    if (id.isEmpty) return const Stream<UserMini?>.empty();

    return _streams.putIfAbsent(id, () {
      final base = _db.collection('users').doc(id).snapshots().map((snap) {
        final d = snap.data();
        if (d == null) return null;

        final rawName = (d['username'] ?? d['displayName'] ?? '') as dynamic;
        final rawPhoto = (d['photoUrl'] ?? '') as dynamic;

        final name = (rawName is String ? rawName : '').trim();
        final photoUrl = (rawPhoto is String ? rawPhoto : '').trim();

        final mini = UserMini(
          uid: id,
          name: name,
          photoUrl: photoUrl,
        );

        _last[id] = mini;
        return mini;
      }).distinct((a, b) => a == b);

      // Keep it broadcast and stable across rebuilds.
      return base.asBroadcastStream();
    });
  }

  Future<UserMini?> getOnce(String uid) async {
    final id = uid.trim();
    if (id.isEmpty) return null;

    final doc = await _db.collection('users').doc(id).get();
    final d = doc.data();
    if (d == null) return null;

    final rawName = (d['username'] ?? d['displayName'] ?? '') as dynamic;
    final rawPhoto = (d['photoUrl'] ?? '') as dynamic;

    final mini = UserMini(
      uid: id,
      name: (rawName is String ? rawName : '').trim(),
      photoUrl: (rawPhoto is String ? rawPhoto : '').trim(),
    );
    _last[id] = mini;
    return mini;
  }
}
