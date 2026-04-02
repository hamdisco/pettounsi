import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  UserProfileService._();
  static final instance = UserProfileService._();

  final _db = FirebaseFirestore.instance;

  Future<void> ensureUserDoc(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    final authName = (user.displayName ?? '').trim();
    final authEmail = (user.email ?? '').trim();
    final authPhoto = (user.photoURL ?? '').trim();

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'email': authEmail.isEmpty ? null : authEmail,
        'displayName': authName.isEmpty ? null : authName,
        'username': authName.isEmpty ? null : authName,
        'usernameLower': authName.isEmpty ? null : authName.toLowerCase(),
        'photoUrl': authPhoto.isEmpty ? null : authPhoto,
        'pointsBalance': 0,
        'pointsSpent': 0,
        'pointsEarnedTotal': 0,
        'pointsSpentTotal': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'isOnline': true,
      }, SetOptions(merge: true));
      return;
    }

    final data = snap.data() ?? {};

    final existingUsername = (data['username'] is String)
        ? (data['username'] as String).trim()
        : '';
    final existingDisplayName = (data['displayName'] is String)
        ? (data['displayName'] as String).trim()
        : '';
    final existingUsernameLower = (data['usernameLower'] is String)
        ? (data['usernameLower'] as String).trim()
        : '';
    final existingEmail = (data['email'] is String)
        ? (data['email'] as String).trim()
        : '';
    final existingPhoto = (data['photoUrl'] is String)
        ? (data['photoUrl'] as String).trim()
        : '';

    final fallbackName = existingUsername.isNotEmpty
        ? existingUsername
        : (existingDisplayName.isNotEmpty ? existingDisplayName : authName);

    final updates = <String, dynamic>{
      'lastSeenAt': FieldValue.serverTimestamp(),
      'isOnline': true,
    };

    if (existingPhoto.isEmpty && authPhoto.isNotEmpty) {
      updates['photoUrl'] = authPhoto;
    }

    if (existingEmail.isEmpty && authEmail.isNotEmpty) {
      updates['email'] = authEmail;
    }

    if (existingUsername.isEmpty && fallbackName.isNotEmpty) {
      updates['username'] = fallbackName;
    }

    if (existingDisplayName.isEmpty && fallbackName.isNotEmpty) {
      updates['displayName'] = fallbackName;
    }

    if (existingUsernameLower.isEmpty && fallbackName.isNotEmpty) {
      updates['usernameLower'] = fallbackName.toLowerCase();
    }

    await ref.set(updates, SetOptions(merge: true));
  }
}
