import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../repositories/block_repository.dart';
import '../../ui/app_theme.dart';
import '../profile/profile_page.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text("Blocked users")),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: BlockRepository.instance.streamMyBlockedDocs(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No blocked users",
                style: TextStyle(
                  color: AppTheme.ink.withAlpha(150),
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final uid = docs[i].id;
              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                builder: (context, uSnap) {
                  final d = uSnap.data?.data() ?? {};
                  final name = (d['username'] ?? 'User') as String;
                  final photo = (d['photoUrl'] ?? '') as String;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(248),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.outline),
                      boxShadow: AppTheme.softShadows(0.10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppTheme.blush,
                          backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                          child: photo.isEmpty
                              ? Text(
                                  name.isEmpty ? 'U' : name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProfilePage(uid: uid)),
                            ),
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => BlockRepository.instance.unblock(uid),
                          child: const Text("Unblock"),
                        ),
                      ],
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
