/// Optional fallback for local development.
///
/// If you don't want to pass --dart-define in release/debug, you can put your
/// Cloudinary values here.
///
/// IMPORTANT:
/// - Keep this file OUT of git (add to .gitignore) if it contains real values.
class LocalSecrets {
  static const String cloudinaryCloudName = '';
  static const String cloudinaryUploadPreset = '';
}
