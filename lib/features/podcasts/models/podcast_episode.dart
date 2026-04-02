import 'package:cloud_firestore/cloud_firestore.dart';

class PodcastEpisode {
  const PodcastEpisode({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.category,
    required this.isPublished,
    this.coverImageUrl,
    this.durationLabel = '',
    this.youtubeUrl,
    this.sourceType = '',
    this.videoId = '',
    this.publishedAt,
  });

  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final String category;
  final bool isPublished;
  final String? coverImageUrl;
  final String durationLabel;

  // Optional video source
  final String? youtubeUrl;
  final String sourceType;
  final String videoId;

  final DateTime? publishedAt;

  bool get isYouTube {
    final st = sourceType.trim().toLowerCase();
    if (st == 'youtube') return true;

    final yu = (youtubeUrl ?? '').trim().toLowerCase();
    if (yu.contains('youtube.com') || yu.contains('youtu.be')) return true;

    final au = audioUrl.trim().toLowerCase();
    return au.contains('youtube.com') || au.contains('youtu.be');
  }

  String get playUrl {
    final yt = (youtubeUrl ?? '').trim();
    if (yt.isNotEmpty) return yt;
    return audioUrl.trim();
  }

  static PodcastEpisode fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final cover = (m['coverImageUrl'] ?? '').toString().trim();
    final yt = (m['youtubeUrl'] ?? '').toString().trim();

    DateTime? publishedAt;
    final p = m['publishedAt'];
    if (p is Timestamp) {
      publishedAt = p.toDate();
    } else if (p is DateTime) {
      publishedAt = p;
    }

    return PodcastEpisode(
      id: d.id,
      title: (m['title'] ?? 'Podcast episode').toString(),
      description: (m['description'] ?? '').toString(),
      audioUrl: (m['audioUrl'] ?? '').toString(),
      category: (m['category'] ?? '').toString(),
      isPublished: m['isPublished'] == true,
      coverImageUrl: cover.isEmpty ? null : cover,
      durationLabel: (m['durationLabel'] ?? '').toString(),
      youtubeUrl: yt.isEmpty ? null : yt,
      sourceType: (m['sourceType'] ?? '').toString(),
      videoId: (m['videoId'] ?? '').toString(),
      publishedAt: publishedAt,
    );
  }
}
