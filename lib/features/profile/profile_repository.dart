import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileRepository {
  ProfileRepository._();
  static final instance = ProfileRepository._();

  final _db = FirebaseFirestore.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Future<void> updateProfile({
    required String uid,
    required String username,
    required String bio,
    required String phone,
    String? photoUrl,
    String? coverPhotoUrl,
  }) async {
    final data = <String, dynamic>{
      'username': username.trim(),
      'bio': bio.trim(),
      'phone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Only write URLs when provided (prevents wiping on slow loads).
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (coverPhotoUrl != null) data['coverPhotoUrl'] = coverPhotoUrl;

    await _db.collection('users').doc(uid).update(data);
  }
}
