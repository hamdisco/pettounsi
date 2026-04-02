import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../ui/app_theme.dart';
import '../profile/profile_page.dart';

class FollowersPage extends StatelessWidget {
  const FollowersPage({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('follows')
        .doc(uid)
        .collection('followers')
        .orderBy('createdAt', descending: true)
        .limit(200);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text("Followers")),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "We couldn't load followers right now. Please try again in a moment.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.ink.withAlpha(170),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No followers yet",
                style: TextStyle(
                  color: AppTheme.ink.withAlpha(150),
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final followerUid = docs[i].id;

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(followerUid)
                    .get(),
                builder: (context, uSnap) {
                  final d = uSnap.data?.data() ?? {};
                  final name = (d['username'] ?? 'User') as String;
                  final photo = (d['photoUrl'] ?? '') as String;

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(uid: followerUid),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppTheme.orange.withAlpha(25),
                            backgroundImage: photo.isNotEmpty
                                ? NetworkImage(photo)
                                : null,
                            child: photo.isEmpty
                                ? Text(
                                    name.isEmpty ? 'U' : name[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppTheme.ink.withAlpha(120),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
