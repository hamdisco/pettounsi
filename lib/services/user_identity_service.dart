import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserIdentity {
  const UserIdentity({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.email,
  });

  final String uid;
  final String displayName;
  final String photoUrl;
  final String email;

  String get safeName =>
      displayName.trim().isEmpty ? 'Pettounsi user' : displayName.trim();
  String? get nullablePhotoUrl =>
      photoUrl.trim().isEmpty ? null : photoUrl.trim();

  Map<String, String> toMeta() => {'name': safeName, 'photo': photoUrl.trim()};
}

class UserIdentityService {
  UserIdentityService._();
  static final instance = UserIdentityService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String displayNameFromData(
    Map<String, dynamic>? data, {
    User? authUser,
    String fallback = 'Pettounsi user',
  }) {
    final d = data ?? const <String, dynamic>{};

    final candidates = <Object?>[
      d['username'],
      d['name'],
      d['email'],
      authUser?.email,
      d['displayName'],
      authUser?.displayName,
    ];

    for (final value in candidates) {
      final text = _clean(value);
      if (text.isEmpty) continue;
      if (text.contains('@')) return _emailPrefix(text);
      return text;
    }

    return fallback.trim().isEmpty ? 'Pettounsi user' : fallback.trim();
  }

  String photoUrlFromData(Map<String, dynamic>? data, {User? authUser}) {
    final d = data ?? const <String, dynamic>{};
    final candidates = <Object?>[
      d['photoUrl'],
      d['avatarUrl'],
      authUser?.photoURL,
    ];

    for (final value in candidates) {
      final text = _clean(value);
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String emailFromData(Map<String, dynamic>? data, {User? authUser}) {
    final d = data ?? const <String, dynamic>{};
    final candidates = <Object?>[d['email'], authUser?.email];
    for (final value in candidates) {
      final text = _clean(value);
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  Future<UserIdentity> getForUid(
    String uid, {
    User? authUser,
    String fallbackName = 'Pettounsi user',
    String fallbackPhotoUrl = '',
  }) async {
    final cleanUid = uid.trim();
    Map<String, dynamic>? data;

    if (cleanUid.isNotEmpty) {
      try {
        final snap = await _db.collection('users').doc(cleanUid).get();
        data = snap.data();
      } catch (_) {
        data = null;
      }
    }

    final name = displayNameFromData(
      data,
      authUser: authUser,
      fallback: fallbackName,
    );

    final photo = photoUrlFromData(data, authUser: authUser).trim();
    final resolvedPhoto = photo.isNotEmpty ? photo : fallbackPhotoUrl.trim();

    return UserIdentity(
      uid: cleanUid.isNotEmpty ? cleanUid : (authUser?.uid ?? ''),
      displayName: name,
      photoUrl: resolvedPhoto,
      email: emailFromData(data, authUser: authUser),
    );
  }

  Future<UserIdentity?> getForCurrentUser({
    String fallbackName = 'Pettounsi user',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return getForUid(user.uid, authUser: user, fallbackName: fallbackName);
  }

  String initialFor(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'P';
    return clean.substring(0, 1).toUpperCase();
  }

  String _clean(Object? value) {
    if (value is! String) return '';
    return value.trim();
  }

  String _emailPrefix(String email) {
    final at = email.indexOf('@');
    final prefix = at > 0 ? email.substring(0, at) : email;
    final cleaned = prefix
        .replaceAll(RegExp(r'[._\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? email : cleaned;
  }
}
