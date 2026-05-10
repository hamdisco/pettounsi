import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_identity_service.dart';

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
  final _identity = UserIdentityService.instance;

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

        final mini = UserMini(
          uid: id,
          name: _identity.displayNameFromData(d),
          photoUrl: _identity.photoUrlFromData(d),
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

    final mini = UserMini(
      uid: id,
      name: _identity.displayNameFromData(d),
      photoUrl: _identity.photoUrlFromData(d),
    );
    _last[id] = mini;
    return mini;
  }
}
