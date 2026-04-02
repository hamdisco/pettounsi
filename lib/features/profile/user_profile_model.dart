import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  final String uid;
  final String username;
  final String? photoUrl;
  final String? bio;
  final String? phone;

  UserProfileModel({
    required this.uid,
    required this.username,
    this.photoUrl,
    this.bio,
    this.phone,
  });

  factory UserProfileModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return UserProfileModel(
      uid: doc.id,
      username: (d['username'] ?? 'User') as String,
      photoUrl: d['photoUrl'] as String?,
      bio: d['bio'] as String?,
      phone: d['phone'] as String?,
    );
  }
}
