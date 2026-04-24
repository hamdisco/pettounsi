import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/url_utils.dart';

class PostModel {
  final String id;

  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;

  final String text;

  /// postType: null = general post, 'adopt' = adoption, 'rescue' = rescue alert
  final String? postType;

  /// Multiple images (preferred)
  final List<String> imageUrls;

  /// Legacy single image (still supported for older docs)
  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  final int likeCount;
  final int commentCount;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String city;
  final String region;
  final String locationText;

  DateTime? get activityAt => updatedAt ?? createdAt;

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
    required this.updatedAt,
    required this.city,
    required this.region,
    required this.locationText,
    this.postType,
  });

  factory PostModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

    List<String> urls = [];
    final rawList = d['imageUrls'];
    if (rawList is List) {
      urls = UrlUtils.normalizeMediaUrls(rawList.whereType<String>());
    } else {
      final legacy = d['imageUrl'];
      if (legacy is String && legacy.trim().isNotEmpty) {
        urls = [UrlUtils.normalizeMediaUrl(legacy)];
      }
    }

    DateTime? asDateTime(Object? value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    String firstString(List<String> keys) {
      for (final key in keys) {
        final value = d[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return '';
    }

    final created = asDateTime(d['createdAt']);
    final updated = asDateTime(d['updatedAt']);

    int asInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final rawType = d['postType'];
    final postType =
        (rawType is String && rawType.trim().isNotEmpty) ? rawType.trim() : null;

    final city = firstString(const ['city']);
    final region = firstString(const ['governorate', 'region', 'state']);

    var locationText = firstString(const [
      'locationText',
      'place',
      'address',
      'city',
    ]);

    if (locationText.isEmpty && (city.isNotEmpty || region.isNotEmpty)) {
      locationText = [city, region]
          .where((part) => part.trim().isNotEmpty)
          .join(', ');
    }

    return PostModel(
      id: doc.id,
      authorId: (d['authorId'] ?? '') as String,
      authorName: (d['authorName'] ?? 'User') as String,
      authorPhotoUrl: (d['authorPhotoUrl'] is String)
          ? UrlUtils.normalizeMediaUrl(d['authorPhotoUrl'] as String)
          : null,
      text: (d['text'] ?? '') as String,
      imageUrls: urls,
      likeCount: asInt(d['likeCount']),
      commentCount: asInt(d['commentCount']),
      createdAt: created,
      updatedAt: updated,
      city: city,
      region: region,
      locationText: locationText,
      postType: postType,
    );
  }
}
