import 'local_secrets.dart';

class AppConfig {
  // NOTE:
  // String.fromEnvironment reads compile-time defines set via:
  //   flutter run/build --dart-define=CLOUDINARY_CLOUD_NAME=... --dart-define=CLOUDINARY_UPLOAD_PRESET=...

  static String get cloudinaryCloudName {
    final v = const String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
    if (v.trim().isNotEmpty) return v.trim();
    return LocalSecrets.cloudinaryCloudName.trim();
  }

  static String get cloudinaryUploadPreset {
    final v = const String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');
    if (v.trim().isNotEmpty) return v.trim();
    return LocalSecrets.cloudinaryUploadPreset.trim();
  }

  /// Optional folder in your Cloudinary media library.
  /// If your preset disallows folder, the upload service will retry without it.
  static const cloudinaryFolder = 'pettounsi/posts';
}
