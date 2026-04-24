import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight local signals for the "For You" feed.
///
/// Keeps a bounded seen-post history on device only so we can de-prioritize
/// already-viewed posts without changing Firestore schema or rules.
class ForYouFeedService {
  ForYouFeedService._();
  static final ForYouFeedService instance = ForYouFeedService._();

  static const String _seenPostsKey = 'for_you_seen_posts_v1';
  static const int _maxSeenPosts = 300;

  bool _loaded = false;
  SharedPreferences? _prefs;
  Timer? _persistTimer;

  final Map<String, int> _seenAtMillis = <String, int>{};

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _prefs = await SharedPreferences.getInstance();

    final raw = _prefs?.getString(_seenPostsKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final key = entry.key.toString().trim();
            final value = entry.value;
            if (key.isEmpty) continue;
            if (value is int) {
              _seenAtMillis[key] = value;
            } else if (value is num) {
              _seenAtMillis[key] = value.toInt();
            } else if (value is String) {
              final parsed = int.tryParse(value);
              if (parsed != null) _seenAtMillis[key] = parsed;
            }
          }
        }
      } catch (_) {
        // Ignore corrupted local cache and continue with a fresh state.
      }
    }

    _trimToLimit();
    _loaded = true;
  }

  bool isSeen(String postId) => _seenAtMillis.containsKey(postId.trim());

  DateTime? seenAt(String postId) {
    final ms = _seenAtMillis[postId.trim()];
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  double seenPenalty(String postId, {DateTime? now}) {
    final seenTime = seenAt(postId);
    if (seenTime == null) return 0;

    final age = (now ?? DateTime.now()).difference(seenTime);
    if (age.inHours < 2) return 120;
    if (age.inHours < 24) return 88;
    if (age.inDays < 7) return 52;
    return 24;
  }

  Future<void> markSeen(String postId) async {
    final cleanId = postId.trim();
    if (cleanId.isEmpty) return;

    await ensureLoaded();
    _seenAtMillis[cleanId] = DateTime.now().millisecondsSinceEpoch;
    _trimToLimit();
    _schedulePersist();
  }

  void _trimToLimit() {
    if (_seenAtMillis.length <= _maxSeenPosts) return;

    final entries = _seenAtMillis.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final removeCount = _seenAtMillis.length - _maxSeenPosts;
    for (var i = 0; i < removeCount; i++) {
      _seenAtMillis.remove(entries[i].key);
    }
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 220), () async {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(_seenPostsKey, jsonEncode(_seenAtMillis));
    });
  }
}
