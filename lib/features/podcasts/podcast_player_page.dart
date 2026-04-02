import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ui/app_theme.dart';
import 'models/podcast_episode.dart';
import 'services/podcast_resume_store.dart';

class PodcastPlayerPage extends StatefulWidget {
  const PodcastPlayerPage({super.key, required this.episode});

  final PodcastEpisode episode;

  @override
  State<PodcastPlayerPage> createState() => _PodcastPlayerPageState();
}

class _PodcastPlayerPageState extends State<PodcastPlayerPage> {
  late final AudioPlayer _player;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  bool _loading = true;
  String? _error;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool _seeking = false;
  double _seekPreviewMs = 0;

  double _speed = 1.0;
  int _lastSavedWallMs = 0;

  bool get _isYouTube => widget.episode.isYouTube;
  String get _playUrl => widget.episode.playUrl;

  static const _kSpeed = 'podcast_playback_speed';

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    // Always save last opened meta, even for YouTube.
    await PodcastResume.saveLast(
      episodeId: widget.episode.id,
      title: widget.episode.title,
      description: widget.episode.description,
      audioUrl: widget.episode.audioUrl,
      imageUrl: widget.episode.coverImageUrl,
      category: widget.episode.category,
      durationLabel: widget.episode.durationLabel,
      sourceType: widget.episode.sourceType,
      youtubeUrl: widget.episode.youtubeUrl,
      videoId: widget.episode.videoId,
      positionMs: 0,
    );

    final prefs = await SharedPreferences.getInstance();
    _speed = (prefs.getDouble(_kSpeed) ?? 1.0).clamp(0.5, 2.0);

    if (_isYouTube) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    _bind();
    await _initAudio();
  }

  void _bind() {
    _durSub = _player.durationStream.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d ?? Duration.zero);
    });

    _posSub = _player.positionStream.listen((p) async {
      if (!mounted) return;
      if (_seeking) return;
      setState(() => _position = p);

      // Throttled save (every ~5s)
      final now = DateTime.now().millisecondsSinceEpoch;
      if (p.inMilliseconds <= 0) return;
      if (now - _lastSavedWallMs < 5000) return;
      _lastSavedWallMs = now;

      await PodcastResume.savePositionMs(widget.episode.id, p.inMilliseconds);
      await PodcastResume.saveLast(
        episodeId: widget.episode.id,
        title: widget.episode.title,
        description: widget.episode.description,
        audioUrl: widget.episode.audioUrl,
        imageUrl: widget.episode.coverImageUrl,
        category: widget.episode.category,
        durationLabel: widget.episode.durationLabel,
        sourceType: widget.episode.sourceType,
        youtubeUrl: widget.episode.youtubeUrl,
        videoId: widget.episode.videoId,
        positionMs: p.inMilliseconds,
      );
    });

    _stateSub = _player.playerStateStream.listen((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _initAudio() async {
    try {
      final savedMs = await PodcastResume.readPositionMs(widget.episode.id);

      await _player.setUrl(widget.episode.audioUrl);
      await _player.setSpeed(_speed);

      final dur = _player.duration ?? Duration.zero;
      if (savedMs > 0 && dur.inMilliseconds > 0) {
        final targetMs = savedMs.clamp(0, dur.inMilliseconds);
        await _player.seek(Duration(milliseconds: targetMs));
      }

      if (!mounted) return;
      setState(() {
        _duration = _player.duration ?? Duration.zero;
        _position = _player.position;
        _loading = false;
      });

      await PodcastResume.saveLast(
        episodeId: widget.episode.id,
        title: widget.episode.title,
        description: widget.episode.description,
        audioUrl: widget.episode.audioUrl,
        imageUrl: widget.episode.coverImageUrl,
        category: widget.episode.category,
        durationLabel: widget.episode.durationLabel,
        sourceType: widget.episode.sourceType,
        youtubeUrl: widget.episode.youtubeUrl,
        videoId: widget.episode.videoId,
        positionMs: _player.position.inMilliseconds,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load audio.';
      });
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();

    if (!_isYouTube) {
      PodcastResume.saveLast(
        episodeId: widget.episode.id,
        title: widget.episode.title,
        description: widget.episode.description,
        audioUrl: widget.episode.audioUrl,
        imageUrl: widget.episode.coverImageUrl,
        category: widget.episode.category,
        durationLabel: widget.episode.durationLabel,
        sourceType: widget.episode.sourceType,
        youtubeUrl: widget.episode.youtubeUrl,
        videoId: widget.episode.videoId,
        positionMs: _player.position.inMilliseconds,
      );
    }

    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_loading || _error != null || _isYouTube) return;

    final state = _player.playerState.processingState;
    if (state == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }

    try {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Playback error.')));
    }
  }

  Future<void> _skipSeconds(int seconds) async {
    if (_loading || _error != null || _isYouTube) return;

    final dur = _duration;
    final current = _player.position;
    final next = current + Duration(seconds: seconds);

    final target = dur.inMilliseconds <= 0
        ? (next.isNegative ? Duration.zero : next)
        : Duration(
            milliseconds: next.inMilliseconds.clamp(0, dur.inMilliseconds),
          );

    await _player.seek(target);
  }

  void _onSliderChanged(double value) {
    setState(() {
      _seeking = true;
      _seekPreviewMs = value;
    });
  }

  Future<void> _onSliderChangeEnd(double value) async {
    if (_isYouTube) return;
    final target = Duration(milliseconds: value.round());
    await _player.seek(target);
    if (!mounted) return;
    setState(() {
      _position = target;
      _seeking = false;
    });

    await PodcastResume.savePositionMs(
      widget.episode.id,
      target.inMilliseconds,
    );
    await PodcastResume.saveLast(
      episodeId: widget.episode.id,
      title: widget.episode.title,
      description: widget.episode.description,
      audioUrl: widget.episode.audioUrl,
      imageUrl: widget.episode.coverImageUrl,
      category: widget.episode.category,
      durationLabel: widget.episode.durationLabel,
      sourceType: widget.episode.sourceType,
      youtubeUrl: widget.episode.youtubeUrl,
      videoId: widget.episode.videoId,
      positionMs: target.inMilliseconds,
    );
  }

  Future<void> _resetSavedProgress() async {
    if (_isYouTube) return;
    await PodcastResume.clearPositionMs(widget.episode.id);
    await _player.seek(Duration.zero);
    if (!mounted) return;
    setState(() => _position = Duration.zero);

    await PodcastResume.saveLast(
      episodeId: widget.episode.id,
      title: widget.episode.title,
      description: widget.episode.description,
      audioUrl: widget.episode.audioUrl,
      imageUrl: widget.episode.coverImageUrl,
      category: widget.episode.category,
      durationLabel: widget.episode.durationLabel,
      sourceType: widget.episode.sourceType,
      youtubeUrl: widget.episode.youtubeUrl,
      videoId: widget.episode.videoId,
      positionMs: 0,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Progress reset.')));
  }

  Future<void> _openExternal() async {
    final raw = _playUrl.trim();
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No link available.')));
      return;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid link.')));
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link.')));
    }
  }

  Future<void> _copyLink() async {
    final raw = _playUrl.trim();
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No link to copy.')));
      return;
    }

    await Clipboard.setData(ClipboardData(text: raw));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied.')));
  }

  Future<void> _pickSpeed() async {
    if (_isYouTube) return;

    final options = <double>[0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final picked = await showModalBottomSheet<double>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.ink.withAlpha(25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const Text(
                  'Playback speed',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: options.map((s) {
                    final active = (s - _speed).abs() < 0.001;
                    return ChoiceChip(
                      selected: active,
                      label: Text('${s.toStringAsFixed(s == 1.0 ? 0 : 2)}x'),
                      onSelected: (_) => Navigator.pop(ctx, s),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: active
                            ? AppTheme.ink
                            : AppTheme.ink.withAlpha(170),
                      ),
                      selectedColor: AppTheme.softOrange,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: active
                            ? AppTheme.orange.withAlpha(120)
                            : AppTheme.outline,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kSpeed, picked);

    await _player.setSpeed(picked);
    if (!mounted) return;
    setState(() => _speed = picked);
  }

  @override
  Widget build(BuildContext context) {
    final durationMs = _duration.inMilliseconds;
    final currentMs = (_seeking
        ? _seekPreviewMs.round()
        : _position.inMilliseconds);
    final sliderMax = (durationMs <= 0 ? 1 : durationMs).toDouble();
    final sliderValue = currentMs.clamp(0, sliderMax.toInt()).toDouble();

    final state = _player.playerState.processingState;
    final playing = _player.playing;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withAlpha(220),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.ink,
        iconTheme: const IconThemeData(color: AppTheme.ink),
        actionsIconTheme: const IconThemeData(color: AppTheme.ink),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink),
            ),
          ),
        ),
        title: Text(
          _isYouTube ? 'Episode' : 'Now playing',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy link',
            onPressed: _copyLink,
            icon: const Icon(Icons.link_rounded),
          ),
          IconButton(
            tooltip: 'Open externally',
            onPressed: _openExternal,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
          if (!_isYouTube)
            IconButton(
              tooltip: 'Speed',
              onPressed: _pickSpeed,
              icon: const Icon(Icons.speed_rounded),
            ),
          if (!_isYouTube)
            IconButton(
              tooltip: 'Reset progress',
              onPressed: _resetSavedProgress,
              icon: const Icon(Icons.restart_alt_rounded),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            expandedHeight: _isYouTube ? 300 : 320,
            pinned: false,
            flexibleSpace: _CoverHeader(
              episode: widget.episode,
              isYouTube: _isYouTube,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetaChips(
                    episode: widget.episode,
                    speed: _speed,
                    isYouTube: _isYouTube,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.episode.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      height: 1.05,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (widget.episode.description.trim().isNotEmpty) ...[
                    _ExpandableText(
                      text: widget.episode.description.trim(),
                      maxLines: 6,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorTip(text: _error!),
                    if (!_isYouTube) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            setState(() {
                              _error = null;
                              _loading = true;
                            });
                            await _initAudio();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isYouTube
          ? _YouTubeBottomBar(onOpen: _openExternal, onCopy: _copyLink)
          : _AudioBottomBar(
              loading: _loading,
              disabled: _error != null,
              playing: playing,
              completed: state == ProcessingState.completed,
              positionText: _fmtDuration(Duration(milliseconds: currentMs)),
              durationText: _fmtDuration(_duration),
              sliderValue: sliderValue,
              sliderMax: sliderMax,
              onSliderChanged: (_loading || _error != null || durationMs <= 0)
                  ? null
                  : _onSliderChanged,
              onSliderChangeEnd: (_loading || _error != null || durationMs <= 0)
                  ? null
                  : _onSliderChangeEnd,
              onReplay15: (_loading || _error != null)
                  ? null
                  : () => _skipSeconds(-15),
              onForward15: (_loading || _error != null)
                  ? null
                  : () => _skipSeconds(15),
              onPlayPause: (_error != null) ? null : _togglePlayPause,
              onSpeed: _pickSpeed,
            ),
    );
  }
}

class _CoverHeader extends StatelessWidget {
  const _CoverHeader({required this.episode, required this.isYouTube});
  final PodcastEpisode episode;
  final bool isYouTube;

  @override
  Widget build(BuildContext context) {
    final has =
        episode.coverImageUrl != null &&
        episode.coverImageUrl!.trim().isNotEmpty;

    // For video episodes we avoid the full-screen "TikTok" look and instead
    // present a premium, rounded preview card.
    if (isYouTube) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.blush, AppTheme.lilac],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 54, 14, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _badge(
                      icon: Icons.play_circle_fill_rounded,
                      label: 'Video',
                      color: const Color(0xFFE53935),
                    ),
                    const SizedBox(width: 10),
                    if (episode.durationLabel.trim().isNotEmpty)
                      _badge(
                        icon: Icons.timer_rounded,
                        label: episode.durationLabel,
                        color: AppTheme.ink,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Hero(
                    tag: 'podcast_cover_${episode.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          has
                              ? Image.network(
                                  episode.coverImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _fallback(),
                                )
                              : _fallback(),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withAlpha(30),
                                  Colors.black.withAlpha(120),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Center(
                            child: Container(
                              width: 74,
                              height: 74,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(240),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.outline),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(25),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                size: 44,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Audio keeps the immersive cover.
    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'podcast_cover_${episode.id}',
          child: has
              ? Image.network(
                  episode.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(),
                )
              : _fallback(),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withAlpha(0),
                Colors.black.withAlpha(90),
                Colors.black.withAlpha(160),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
            child: Row(
              children: [
                _badge(
                  icon: Icons.headphones_rounded,
                  label: 'Audio',
                  color: AppTheme.orangeDark,
                ),
                const SizedBox(width: 10),
                if (episode.durationLabel.trim().isNotEmpty)
                  _badge(
                    icon: Icons.timer_rounded,
                    label: episode.durationLabel,
                    color: AppTheme.ink,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.softOrange, AppTheme.lilac],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.podcasts_rounded,
          size: 64,
          color: AppTheme.ink.withAlpha(130),
        ),
      ),
    );
  }
}

class _MetaChips extends StatelessWidget {
  const _MetaChips({
    required this.episode,
    required this.speed,
    required this.isYouTube,
  });

  final PodcastEpisode episode;
  final double speed;
  final bool isYouTube;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (episode.category.trim().isNotEmpty) {
      chips.add(
        _Chip(
          icon: Icons.local_offer_rounded,
          text: episode.category,
          bg: AppTheme.lilac,
          fg: const Color(0xFF4B3DB8),
        ),
      );
    }

    if (!isYouTube && speed != 1.0) {
      chips.add(
        _Chip(
          icon: Icons.speed_rounded,
          text: '${speed.toStringAsFixed(speed == 1.0 ? 0 : 2)}x',
          bg: AppTheme.mint,
          fg: const Color(0xFF1B7A4B),
        ),
      );
    }

    if (episode.publishedAt != null) {
      final dt = episode.publishedAt!;
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      chips.add(
        _Chip(
          icon: Icons.calendar_month_rounded,
          text: '$y-$m-$d',
          bg: AppTheme.sky,
          fg: const Color(0xFF4C79C8),
        ),
      );
    }

    return Wrap(spacing: 10, runSpacing: 10, children: chips);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.text,
    required this.bg,
    required this.fg,
  });
  final IconData icon;
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: fg,
              fontSize: 12.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorTip extends StatelessWidget {
  const _ErrorTip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD8D8)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5E5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFE05555),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.ink.withAlpha(185),
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YouTubeBottomBar extends StatelessWidget {
  const _YouTubeBottomBar({required this.onOpen, required this.onCopy});
  final Future<void> Function() onOpen;
  final Future<void> Function() onCopy;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppTheme.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(14),
              blurRadius: 22,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => onOpen(),
            icon: const Icon(Icons.ondemand_video_rounded),
            label: const Text('Open on YouTube'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioBottomBar extends StatelessWidget {
  const _AudioBottomBar({
    required this.loading,
    required this.disabled,
    required this.playing,
    required this.completed,
    required this.positionText,
    required this.durationText,
    required this.sliderValue,
    required this.sliderMax,
    required this.onSliderChanged,
    required this.onSliderChangeEnd,
    required this.onReplay15,
    required this.onForward15,
    required this.onPlayPause,
    required this.onSpeed,
  });

  final bool loading;
  final bool disabled;
  final bool playing;
  final bool completed;

  final String positionText;
  final String durationText;

  final double sliderValue;
  final double sliderMax;

  final ValueChanged<double>? onSliderChanged;
  final ValueChanged<double>? onSliderChangeEnd;

  final VoidCallback? onReplay15;
  final VoidCallback? onForward15;
  final VoidCallback? onPlayPause;
  final VoidCallback onSpeed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppTheme.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(14),
              blurRadius: 22,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  positionText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
                const Spacer(),
                Text(
                  durationText,
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            Slider(
              value: sliderValue,
              max: sliderMax,
              onChanged: onSliderChanged,
              onChangeEnd: onSliderChangeEnd,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundButton(icon: Icons.replay_rounded, onTap: onReplay15),

                const SizedBox(width: 14),
                _MainButton(
                  loading: loading && !disabled,
                  icon: completed
                      ? Icons.replay_rounded
                      : (playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded),
                  onTap: onPlayPause,
                ),
                const SizedBox(width: 14),
                _RoundButton(icon: Icons.forward_rounded, onTap: onForward15),
                const SizedBox(width: 14),
                _RoundButton(icon: Icons.speed_rounded, onTap: onSpeed),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}

class _MainButton extends StatelessWidget {
  const _MainButton({
    required this.loading,
    required this.icon,
    required this.onTap,
  });
  final bool loading;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.orange,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: SizedBox(
          width: 74,
          height: 74,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Icon(icon, size: 36, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.text, required this.maxLines});
  final String text;
  final int maxLines;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: AppTheme.ink.withAlpha(185),
      fontWeight: FontWeight.w700,
      height: 1.35,
      fontSize: 14.2,
    );

    return LayoutBuilder(
      builder: (ctx, c) {
        final span = TextSpan(text: widget.text, style: textStyle);
        final tp = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
          maxLines: _expanded ? null : widget.maxLines,
          ellipsis: '…',
        )..layout(maxWidth: c.maxWidth);

        final overflow = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: textStyle,
              maxLines: _expanded ? null : widget.maxLines,
              overflow: _expanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
            if (overflow)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Show less' : 'Read more',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

String _fmtDuration(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);

  String two(int v) => v.toString().padLeft(2, '0');
  if (h > 0) return '$h:${two(m)}:${two(s)}';
  return '${two(m)}:${two(s)}';
}
