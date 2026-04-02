import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../repositories/block_repository.dart';
import '../../ui/app_theme.dart';
import '../../ui/premium_cards.dart';
import '../../ui/premium_feedback.dart';
import '../../ui/premium_sheet.dart';
import '../../ui/user_avatar.dart';
import 'chat_page.dart';

class NewChatSheet extends StatefulWidget {
  const NewChatSheet({super.key});

  @override
  State<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  final _c = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    final maxHeight = MediaQuery.of(context).size.height * 0.72;

    return PremiumBottomSheetFrame(
      icon: Icons.chat_bubble_rounded,
      iconColor: const Color(0xFF7C62D7),
      iconBg: AppTheme.lilac,
      title: 'New message',
      subtitle: 'Start a conversation with someone you already follow.',
      scrollable: false,
      child: SizedBox(
        height: maxHeight,
        child: Column(
          children: [
            TextField(
              controller: _c,
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search in following…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppTheme.mist,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppTheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppTheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppTheme.outline),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: me == null
                  ? const Center(
                      child: PremiumEmptyStateCard(
                        icon: Icons.lock_outline_rounded,
                        iconColor: Color(0xFFE05555),
                        iconBg: Color(0xFFFFEBEB),
                        title: 'Please sign in again',
                        subtitle: 'You need an active session to start a chat.',
                        compact: true,
                      ),
                    )
                  : StreamBuilder<Set<String>>(
                      stream: BlockRepository.instance.streamBlockedUids(),
                      builder: (context, blockedSnap) {
                        final blocked = blockedSnap.data ?? <String>{};

                        final q = FirebaseFirestore.instance
                            .collection('follows')
                            .doc(me.uid)
                            .collection('following')
                            .orderBy('createdAt', descending: true)
                            .limit(50);

                        return StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>
                        >(
                          stream: q.snapshots(),
                          builder: (context, snap) {
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return ListView.builder(
                                itemCount: 6,
                                itemBuilder: (_, __) => const Padding(
                                  padding: EdgeInsets.only(bottom: 10),
                                  child: PremiumSkeletonCard(
                                    height: 82,
                                    radius: 20,
                                  ),
                                ),
                              );
                            }

                            final docs = snap.data?.docs ?? [];
                            if (docs.isEmpty) {
                              return const Center(
                                child: PremiumEmptyStateCard(
                                  icon: Icons.people_alt_rounded,
                                  iconColor: Color(0xFF7C62D7),
                                  iconBg: AppTheme.lilac,
                                  title: 'No following yet',
                                  subtitle:
                                      'Follow someone from their profile to message them.',
                                  compact: true,
                                ),
                              );
                            }

                            final ids = docs
                                .map((d) => d.id)
                                .where((id) => !blocked.contains(id))
                                .toList();

                            return ListView.separated(
                              itemCount: ids.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final uid = ids[i];

                                return StreamBuilder<
                                  DocumentSnapshot<Map<String, dynamic>>
                                >(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .snapshots(),
                                  builder: (context, us) {
                                    final d = us.data?.data() ?? {};
                                    final name =
                                        (d['username'] ??
                                                d['displayName'] ??
                                                'User')
                                            .toString();
                                    final nameLower = name.toLowerCase();
                                    final photo = (d['photoUrl'] ?? '')
                                        .toString();

                                    if (_q.isNotEmpty &&
                                        !nameLower.contains(_q)) {
                                      return const SizedBox.shrink();
                                    }

                                    return _UserTile(
                                      uid: uid,
                                      name: name,
                                      photoUrl: photo,
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatPage(
                                              otherUid: uid,
                                              otherName: name,
                                              otherPhoto: photo.isEmpty
                                                  ? null
                                                  : photo,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.uid,
    required this.name,
    required this.photoUrl,
    required this.onTap,
  });

  final String uid;
  final String name;
  final String photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCardSurface(
      onTap: onTap,
      radius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      shadowOpacity: 0.06,
      child: Row(
        children: [
          UserAvatar(
            uid: uid,
            radius: 20,
            fallbackName: name,
            fallbackPhotoUrl: photoUrl.isEmpty ? null : photoUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: UserName(
              uid: uid,
              fallback: name,
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
                fontSize: 13.4,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PremiumCardBadge(
            label: 'Message',
            icon: Icons.arrow_outward_rounded,
            bg: AppTheme.mist,
            fg: const Color(0xFF7C62D7),
          ),
        ],
      ),
    );
  }
}
