/// Centralized image constraints for a social app.
///
/// Goal: reduce upload size (Cloudinary bandwidth + faster feed) while keeping
/// images crisp on modern phones.
///
/// We purposely do this at *pick time* (ImagePicker parameters) to avoid
/// heavy decoding/encoding in Dart and to keep release builds stable.
library;

enum SocialImageKind { post, chat, avatar, cover }

class SocialImagePreset {
  final double maxWidth;
  final double maxHeight;
  final int quality;

  const SocialImagePreset({
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
  });
}

class MediaPresets {
  // Feed photos: enough for full-screen view, but not huge.
  static const SocialImagePreset post = SocialImagePreset(
    maxWidth: 1600,
    maxHeight: 1600,
    quality: 82,
  );

  // Chat images: smaller by design.
  static const SocialImagePreset chat = SocialImagePreset(
    maxWidth: 1280,
    maxHeight: 1280,
    quality: 80,
  );

  // Avatars: small, round.
  static const SocialImagePreset avatar = SocialImagePreset(
    maxWidth: 768,
    maxHeight: 768,
    quality: 85,
  );

  // Covers: wide; allow larger width.
  static const SocialImagePreset cover = SocialImagePreset(
    maxWidth: 2048,
    maxHeight: 2048,
    quality: 82,
  );

  static SocialImagePreset forKind(SocialImageKind kind) {
    switch (kind) {
      case SocialImageKind.post:
        return post;
      case SocialImageKind.chat:
        return chat;
      case SocialImageKind.avatar:
        return avatar;
      case SocialImageKind.cover:
        return cover;
    }
  }
}
