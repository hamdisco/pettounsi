import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';
import '../../ui/premium_feedback.dart';
import '../home/post_card.dart';
import '../home/post_model.dart';

class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context) {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Post')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: postRef.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return ListView(
              padding: const EdgeInsets.all(12),
              children: const [
                PremiumMiniEmptyCard(
                  icon: Icons.sync_rounded,
                  iconColor: Color(0xFF7C62D7),
                  iconBg: AppTheme.lilac,
                  title: 'Loading post',
                  subtitle: 'Fetching the latest post details.',
                ),
                SizedBox(height: 12),
                PremiumSkeletonCard(height: 360, radius: 28),
              ],
            );
          }

          if (!snap.data!.exists) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: PremiumEmptyStateCard(
                  icon: Icons.inbox_rounded,
                  iconColor: Color(0xFF4C79C8),
                  iconBg: AppTheme.sky,
                  title: 'This post no longer exists',
                  subtitle:
                      'It may have been deleted or is no longer available.',
                  compact: true,
                ),
              ),
            );
          }

          final post = PostModel.fromDoc(snap.data!);
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [PostCard(post: post)],
          );
        },
      ),
    );
  }
}
