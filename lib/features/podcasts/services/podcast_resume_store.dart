import 'package:shared_preferences/shared_preferences.dart';

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

  bool get isValid => episodeId.trim().isNotEmpty && title.trim().isNotEmpty;

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

  static String _posKey(String episodeId) => 'podcast_pos_$episodeId';

  static Future<PodcastResume?> readLast() async {
    final prefs = await SharedPreferences.getInstance();
    final id = (prefs.getString(_kLastEpisodeId) ?? '').trim();
    final title = (prefs.getString(_kLastTitle) ?? '').trim();
    final audio = (prefs.getString(_kLastAudioUrl) ?? '').trim();
    if (id.isEmpty || title.isEmpty || audio.isEmpty) return null;

    final img = (prefs.getString(_kLastImageUrl) ?? '').trim();
    final yt = (prefs.getString(_kLastYoutubeUrl) ?? '').trim();

    final r = PodcastResume(
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

    return r.isValid ? r : null;
  }

  static Future<void> saveLast({
    required String episodeId,
    required String title,
    required String description,
    required String audioUrl,
    required String? imageUrl,
    required String category,
    required String durationLabel,
    required String sourceType,
    required String? youtubeUrl,
    required String videoId,
    required int positionMs,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_kLastEpisodeId, episodeId);
    await prefs.setString(_kLastTitle, title);
    await prefs.setString(_kLastDescription, description);
    await prefs.setString(_kLastAudioUrl, audioUrl);
    await prefs.setString(_kLastImageUrl, (imageUrl ?? '').trim());
    await prefs.setString(_kLastCategory, category);
    await prefs.setString(_kLastDurationLabel, durationLabel);
    await prefs.setString(_kLastSourceType, sourceType);
    await prefs.setString(_kLastYoutubeUrl, (youtubeUrl ?? '').trim());
    await prefs.setString(_kLastVideoId, videoId);
    await prefs.setInt(_kLastPositionMs, positionMs.clamp(0, 1 << 31));
    await prefs.setInt(_kLastUpdatedAtMs, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> clearLast() async {
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

  static Future<int> readPositionMs(String episodeId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_posKey(episodeId)) ?? 0;
  }

  static Future<void> savePositionMs(String episodeId, int positionMs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_posKey(episodeId), positionMs.clamp(0, 1 << 31));
  }

  static Future<void> clearPositionMs(String episodeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_posKey(episodeId));
  }
}
