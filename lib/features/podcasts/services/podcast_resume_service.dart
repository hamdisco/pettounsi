import 'package:shared_preferences/shared_preferences.dart';

import '../models/podcast_episode.dart';

/// Single source of truth for podcast progress + "continue listening".
///
/// Why this exists:
/// - Avoid duplicated SharedPreferences keys in multiple files.
/// - Keep storage logic testable and consistent.
class PodcastResumeService {
  PodcastResumeService._();
  static final PodcastResumeService instance = PodcastResumeService._();

  // -----------------------------
  // Keys
  // -----------------------------
  static const _kLastEpisodeId = 'podcast_last_episode_id';
  static const _kLastTitle = 'podcast_last_title';
  static const _kLastDescription = 'podcast_last_description';
  static const _kLastAudioUrl = 'podcast_last_audio_url';
  static const _kLastImageUrl = 'podcast_last_image_url';
  static const _kLastCategory = 'podcast_last_category';
  static const _kLastDurationLabel = 'podcast_last_duration_label';
  static const _kLastSourceType = 'podcast_last_source_type';
  static const _kLastYoutubeUrl = 'podcast_last_youtube_url';
  static const _kLastVideoId = 'podcast_last_video_id';
  static const _kLastPositionMs = 'podcast_last_position_ms';
  static const _kLastUpdatedAtMs = 'podcast_last_updated_at_ms';

  String _posKey(String episodeId) => 'podcast_pos_$episodeId';

  // -----------------------------
  // Public API
  // -----------------------------
  Future<PodcastResume?> loadLastPlayed() async {
    final prefs = await SharedPreferences.getInstance();

    final id = (prefs.getString(_kLastEpisodeId) ?? '').trim();
    final title = (prefs.getString(_kLastTitle) ?? '').trim();
    final audio = (prefs.getString(_kLastAudioUrl) ?? '').trim();

    if (id.isEmpty || title.isEmpty || audio.isEmpty) return null;

    final img = (prefs.getString(_kLastImageUrl) ?? '').trim();
    final yt = (prefs.getString(_kLastYoutubeUrl) ?? '').trim();

    return PodcastResume(
      episodeId: id,
      title: title,
      description: (prefs.getString(_kLastDescription) ?? '').trim(),
      audioUrl: audio,
      imageUrl: img.isEmpty ? null : img,
      category: (prefs.getString(_kLastCategory) ?? '').trim(),
      durationLabel: (prefs.getString(_kLastDurationLabel) ?? '').trim(),
      sourceType: (prefs.getString(_kLastSourceType) ?? '').trim(),
      youtubeUrl: yt.isEmpty ? null : yt,
      videoId: (prefs.getString(_kLastVideoId) ?? '').trim(),
      positionMs: prefs.getInt(_kLastPositionMs) ?? 0,
      updatedAtMs: prefs.getInt(_kLastUpdatedAtMs) ?? 0,
    );
  }

  Future<void> clearLastPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastEpisodeId);
    await prefs.remove(_kLastTitle);
    await prefs.remove(_kLastDescription);
    await prefs.remove(_kLastAudioUrl);
    await prefs.remove(_kLastImageUrl);
    await prefs.remove(_kLastCategory);
    await prefs.remove(_kLastDurationLabel);
    await prefs.remove(_kLastSourceType);
    await prefs.remove(_kLastYoutubeUrl);
    await prefs.remove(_kLastVideoId);
    await prefs.remove(_kLastPositionMs);
    await prefs.remove(_kLastUpdatedAtMs);
  }

  /// Saves the last-played metadata + progress.
  Future<void> saveLastPlayed(PodcastEpisode episode, {required int positionMs}) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_kLastEpisodeId, episode.id);
    await prefs.setString(_kLastTitle, episode.title);
    await prefs.setString(_kLastDescription, episode.description);
    await prefs.setString(_kLastAudioUrl, episode.audioUrl);
    await prefs.setString(_kLastImageUrl, (episode.coverImageUrl ?? '').trim());
    await prefs.setString(_kLastCategory, episode.category);
    await prefs.setString(_kLastDurationLabel, episode.durationLabel);
    await prefs.setString(_kLastSourceType, episode.sourceType);
    await prefs.setString(_kLastYoutubeUrl, (episode.youtubeUrl ?? '').trim());
    await prefs.setString(_kLastVideoId, episode.videoId);
    await prefs.setInt(_kLastPositionMs, positionMs.clamp(0, 1 << 31));
    await prefs.setInt(_kLastUpdatedAtMs, DateTime.now().millisecondsSinceEpoch);
  }

  Future<int> getSavedPositionMs(String episodeId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_posKey(episodeId)) ?? 0;
  }

  Future<void> setSavedPositionMs(String episodeId, int positionMs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_posKey(episodeId), positionMs.clamp(0, 1 << 31));
  }

  Future<void> clearSavedPosition(String episodeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_posKey(episodeId));
  }
}

class PodcastResume {
  const PodcastResume({
    required this.episodeId,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.imageUrl,
    required this.category,
    required this.durationLabel,
    required this.sourceType,
    required this.youtubeUrl,
    required this.videoId,
    required this.positionMs,
    required this.updatedAtMs,
  });

  final String episodeId;
  final String title;
  final String description;
  final String audioUrl;
  final String? imageUrl;
  final String category;
  final String durationLabel;
  final String sourceType;
  final String? youtubeUrl;
  final String videoId;
  final int positionMs;
  final int updatedAtMs;

  PodcastEpisode toEpisodeFallback() {
    return PodcastEpisode(
      id: episodeId,
      title: title,
      description: description,
      audioUrl: audioUrl,
      category: category,
      isPublished: true,
      coverImageUrl: imageUrl,
      durationLabel: durationLabel,
      youtubeUrl: youtubeUrl,
      sourceType: sourceType,
      videoId: videoId,
      publishedAt: null,
    );
  }
}
