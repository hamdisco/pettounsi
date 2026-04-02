import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/url_utils.dart';

class PostModel {
  final String id;

  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;

  final String text;

  /// Multiple images (preferred)
  final List<String> imageUrls;

  /// Legacy single image (still supported for older docs)
  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  final int likeCount;
  final int commentCount;

  final DateTime? createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.text,
    required this.imageUrls,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
  });

  factory PostModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

    // imageUrls (new) or imageUrl (legacy)
    List<String> urls = [];
    final rawList = d['imageUrls'];
    if (rawList is List) {
      urls = UrlUtils.normalizeMediaUrls(rawList.whereType<String>());
    } else {
      final legacy = d['imageUrl'];
      if (legacy is String && legacy.trim().isNotEmpty) urls = [UrlUtils.normalizeMediaUrl(legacy)];
    }

    DateTime? created;
    final ts = d['createdAt'];
    if (ts is Timestamp) created = ts.toDate();

    int asInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return PostModel(
      id: doc.id,
      authorId: (d['authorId'] ?? '') as String,
      authorName: (d['authorName'] ?? 'User') as String,
      authorPhotoUrl: (d['authorPhotoUrl'] is String) ? UrlUtils.normalizeMediaUrl(d['authorPhotoUrl'] as String) : null,
      text: (d['text'] ?? '') as String,
      imageUrls: urls,
      likeCount: asInt(d['likeCount']),
      commentCount: asInt(d['commentCount']),
      createdAt: created,
    );
  }
}
