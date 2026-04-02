import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/home/posts_repository.dart';

class PostOutboxItem {
  PostOutboxItem({
    required this.id,
    required this.text,
    required this.localImagePaths,
    required this.createdAt,
    required this.attemptCount,
    required this.nextAttemptAt,
    required this.lastError,
  });

  /// Used as Firestore postId for deduplication on retries.
  final String id;

  final String text;
  final List<String> localImagePaths;
  final DateTime createdAt;

  final int attemptCount;
  final DateTime nextAttemptAt;
  final String lastError;

  bool get readyToSend =>
      DateTime.now().isAfter(nextAttemptAt) ||
      DateTime.now().isAtSameMomentAs(nextAttemptAt);

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'localImagePaths': localImagePaths,
    'createdAt': createdAt.toIso8601String(),
    'attemptCount': attemptCount,
    'nextAttemptAt': nextAttemptAt.toIso8601String(),
    'lastError': lastError,
  };

  static PostOutboxItem fromJson(Map<String, dynamic> j) => PostOutboxItem(
    id: (j['id'] ?? '').toString(),
    text: (j['text'] ?? '').toString(),
    localImagePaths: ((j['localImagePaths'] ?? const []) as List)
        .map((e) => e.toString())
        .toList(),
    createdAt:
        DateTime.tryParse((j['createdAt'] ?? '').toString()) ?? DateTime.now(),
    attemptCount: (j['attemptCount'] ?? 0) is int
        ? (j['attemptCount'] as int)
        : int.tryParse((j['attemptCount'] ?? '0').toString()) ?? 0,
    nextAttemptAt:
        DateTime.tryParse((j['nextAttemptAt'] ?? '').toString()) ??
        DateTime.now(),
    lastError: (j['lastError'] ?? '').toString(),
  );

  PostOutboxItem copyWith({
    String? text,
    List<String>? localImagePaths,
    DateTime? createdAt,
    int? attemptCount,
    DateTime? nextAttemptAt,
    String? lastError,
  }) {
    return PostOutboxItem(
      id: id,
      text: text ?? this.text,
      localImagePaths: localImagePaths ?? this.localImagePaths,
      createdAt: createdAt ?? this.createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
    );
  }
}

class PostOutboxService with WidgetsBindingObserver {
  PostOutboxService._();
  static final PostOutboxService instance = PostOutboxService._();

  static const _prefsKey = 'post_outbox_v1';

  final ValueNotifier<List<PostOutboxItem>> items =
      ValueNotifier<List<PostOutboxItem>>([]);

  SharedPreferences? _prefs;
  Directory? _dir;
  Timer? _timer;
  bool _processing = false;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _dir ??= await _ensureOutboxDir();

    await _load();

    WidgetsBinding.instance.addObserver(this);

    // Foreground-only retry loop (light).
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(processQueue());
    });

    // Kick once on startup.
    unawaited(processQueue(force: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(processQueue(force: true));
    }
  }

  Future<Directory> _ensureOutboxDir() async {
    final root = await getApplicationDocumentsDirectory();
    final d = Directory('${root.path}/outbox_posts');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<void> _load() async {
    final raw = _prefs?.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      items.value = <PostOutboxItem>[];
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        items.value = <PostOutboxItem>[];
        return;
      }

      final list = <PostOutboxItem>[];
      for (final e in decoded) {
        if (e is Map) {
          final m = e.map((k, v) => MapEntry(k.toString(), v));
          final it = PostOutboxItem.fromJson(m);
          if (it.id.isNotEmpty) list.add(it);
        }
      }
      items.value = list;
    } catch (_) {
      // Corrupted: reset.
      items.value = <PostOutboxItem>[];
      await _prefs?.remove(_prefsKey);
    }
  }

  Future<void> _save() async {
    final list = items.value.map((e) => e.toJson()).toList();
    await _prefs?.setString(_prefsKey, jsonEncode(list));
  }

  String _safeExt(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return '.png';
    if (p.endsWith('.webp')) return '.webp';
    if (p.endsWith('.heic')) return '.heic';
    return '.jpg';
  }

  String _newId(String uid) {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final r = Random.secure().nextInt(1 << 20).toString().padLeft(6, '0');
    // IMPORTANT: use braces so Dart doesn't create a `ms_` identifier.
    return '${uid}_${ms}_${r}';
  }

  /// Saves the post locally and schedules it for retry.
  Future<void> enqueue({
    required String text,
    required List<File> imageFiles,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');

    _dir ??= await _ensureOutboxDir();

    final id = _newId(user.uid);
    final createdAt = DateTime.now();

    final copiedPaths = <String>[];
    for (var i = 0; i < imageFiles.length && i < 4; i++) {
      final src = imageFiles[i];
      final ext = _safeExt(src.path);
      final dst = File('${_dir!.path}/$id-$i$ext');
      try {
        await dst.parent.create(recursive: true);
        await src.copy(dst.path);
        copiedPaths.add(dst.path);
      } catch (_) {
        // If copying fails, keep going (text-only post is still valuable).
      }
    }

    final item = PostOutboxItem(
      id: id,
      text: text.trim(),
      localImagePaths: copiedPaths,
      createdAt: createdAt,
      attemptCount: 0,
      nextAttemptAt: DateTime.now(),
      lastError: '',
    );

    items.value = [item, ...items.value];
    await _save();

    // Try immediately.
    unawaited(processQueue(force: true));
  }

  Future<void> remove(String id) async {
    PostOutboxItem? item;
    for (final x in items.value) {
      if (x.id == id) {
        item = x;
        break;
      }
    }

    if (item != null) {
      for (final p in item.localImagePaths) {
        try {
          final f = File(p);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    }

    items.value = items.value.where((e) => e.id != id).toList();
    await _save();
  }

  Future<void> retryNow(String id) async {
    final list = items.value;
    final idx = list.indexWhere((e) => e.id == id);
    if (idx < 0) return;

    final updated = list[idx].copyWith(nextAttemptAt: DateTime.now());
    final next = [...list];
    next[idx] = updated;
    items.value = next;
    await _save();

    unawaited(processQueue(force: true));
  }

  Duration _backoff(int attempt) {
    // Exponential backoff with cap (max 10 minutes) + small jitter.
    final base = 10; // seconds
    final exp = min(6, max(0, attempt)); // 10*2^6 = 640s
    final secs = min(600, base * (1 << exp));
    final jitter = Random().nextInt(5); // 0..4
    return Duration(seconds: secs + jitter);
  }

  Future<void> processQueue({bool force = false}) async {
    if (_processing) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final list = items.value;
    if (list.isEmpty) return;

    final now = DateTime.now();
    final idx = list.indexWhere(
      (e) =>
          force ||
          e.nextAttemptAt.isBefore(now) ||
          e.nextAttemptAt.isAtSameMomentAs(now),
    );
    if (idx < 0) return;

    final item = list[idx];

    _processing = true;
    try {
      // Load files that still exist.
      final files = <File>[];
      for (final p in item.localImagePaths) {
        final f = File(p);
        if (await f.exists()) files.add(f);
      }

      await PostsRepository.instance.createPost(
        text: item.text,
        imageFiles: files,
        postId: item.id,
        clientCreatedAt: item.createdAt,
      );

      await remove(item.id);
    } catch (e) {
      final err = _prettyError(e.toString());

      final list2 = items.value;
      final idx2 = list2.indexWhere((x) => x.id == item.id);
      if (idx2 < 0) return;

      final cur = list2[idx2];
      final nextAttempt = DateTime.now().add(_backoff(cur.attemptCount + 1));
      final updated = cur.copyWith(
        attemptCount: cur.attemptCount + 1,
        nextAttemptAt: nextAttempt,
        lastError: err,
      );
      final next = [...list2];
      next[idx2] = updated;
      items.value = next;
      await _save();
    } finally {
      _processing = false;
    }
  }

  String _prettyError(String raw) {
    final s = raw.replaceAll('Exception: ', '').trim();
    final t = s.toLowerCase();
    if (t.contains('socketexception') || t.contains('failed host lookup'))
      return 'No internet connection.';
    if (t.contains('timed out')) return 'Connection timed out.';
    if (t.contains('cloudinary upload failed'))
      return 'Upload failed. Will retry.';
    return s.length > 140 ? '${s.substring(0, 140)}…' : s;
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }
}
