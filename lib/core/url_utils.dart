class UrlUtils {
  UrlUtils._();

  /// Normalizes user/media URLs so they work reliably in Android release builds.
  /// - trims
  /// - upgrades http -> https (Cloudinary supports https)
  /// - leaves other schemes untouched
  static String normalizeMediaUrl(String url) {
    final u = url.trim();
    if (u.isEmpty) return '';

    // Already secure or a data/file URI
    if (u.startsWith('https://') || u.startsWith('data:') || u.startsWith('file:')) {
      return u;
    }

    // Protocol-relative
    if (u.startsWith('//')) {
      return 'https:$u';
    }

    // Upgrade cleartext to TLS
    if (u.startsWith('http://')) {
      return 'https://${u.substring('http://'.length)}';
    }

    // Bare domain/path
    if (u.startsWith('res.cloudinary.com/') || u.startsWith('api.cloudinary.com/')) {
      return 'https://$u';
    }

    return u;
  }

  static List<String> normalizeMediaUrls(Iterable<String> urls) {
    final out = <String>[];
    for (final s in urls) {
      final n = normalizeMediaUrl(s);
      if (n.isNotEmpty) out.add(n);
    }
    return out;
  }
}
