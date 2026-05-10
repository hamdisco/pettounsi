import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../ui/app_theme.dart';
import 'arcade_claim_service.dart';

class BubblePawsPage extends StatefulWidget {
  const BubblePawsPage({super.key});

  @override
  State<BubblePawsPage> createState() => _BubblePawsPageState();
}

class _BubblePawsPageState extends State<BubblePawsPage> {
  static const int _gameSeconds = 35;
  final Random _random = Random();

  Timer? _clock;
  Timer? _spawner;
  final List<_BubbleItem> _items = [];

  int _score = 0;
  int _secondsLeft = _gameSeconds;
  bool _running = false;
  bool _finished = false;
  bool _claiming = false;
  bool _claimed = false;

  int get _reward => ArcadeClaimService.bubblePawsReward(_score);

  @override
  void dispose() {
    _clock?.cancel();
    _spawner?.cancel();
    super.dispose();
  }

  void _start() {
    _clock?.cancel();
    _spawner?.cancel();
    setState(() {
      _score = 0;
      _secondsLeft = _gameSeconds;
      _running = true;
      _finished = false;
      _claiming = false;
      _claimed = false;
      _items.clear();
    });
    _spawnWave();

    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_running) return;
      setState(() {
        _secondsLeft--;
        _items.removeWhere((item) => DateTime.now().difference(item.createdAt).inMilliseconds > 2200);
        if (_secondsLeft <= 0) {
          _running = false;
          _finished = true;
          _clock?.cancel();
          _spawner?.cancel();
          _items.clear();
        }
      });
    });

    _spawner = Timer.periodic(const Duration(milliseconds: 850), (_) {
      if (!mounted || !_running) return;
      setState(_spawnWave);
    });
  }

  void _spawnWave() {
    if (_items.length > 8) _items.removeAt(0);
    final isBad = _random.nextInt(6) == 0;
    _items.add(
      _BubbleItem(
        id: DateTime.now().microsecondsSinceEpoch + _random.nextInt(999),
        x: 0.05 + _random.nextDouble() * 0.78,
        y: 0.06 + _random.nextDouble() * 0.76,
        size: 48 + _random.nextDouble() * 22,
        isBad: isBad,
        createdAt: DateTime.now(),
      ),
    );
  }

  void _tapBubble(_BubbleItem item) {
    if (!_running) return;
    setState(() {
      _items.removeWhere((e) => e.id == item.id);
      _score = max(0, _score + (item.isBad ? -25 : 20));
    });
  }

  Future<void> _claim() async {
    if (_claiming || _claimed || !_finished) return;
    setState(() => _claiming = true);

    final result = await ArcadeClaimService.submitArcadeClaim(
      gameId: 'bubble_paws',
      gameTitle: 'Bubble Paws',
      score: _score,
      reward: _reward,
      durationSeconds: _gameSeconds,
      resultLabel: 'Score $_score',
    );

    if (!mounted) return;
    setState(() {
      _claiming = false;
      _claimed = result.success;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Bubble Paws'),
        backgroundColor: AppTheme.bg,
        foregroundColor: AppTheme.ink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          _ArcadeScoreBar(score: _score, seconds: _secondsLeft, reward: _reward),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 0.92,
            child: LayoutBuilder(
              builder: (context, box) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10A37F), Color(0xFFB6F3D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withAlpha(230)),
                    boxShadow: AppTheme.softShadows(0.16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        Positioned.fill(child: CustomPaint(painter: _BubbleFieldPainter())),
                        for (final item in _items)
                          AnimatedPositioned(
                            key: ValueKey(item.id),
                            duration: const Duration(milliseconds: 160),
                            left: (box.maxWidth - item.size) * item.x,
                            top: (box.maxHeight - item.size) * item.y,
                            child: GestureDetector(
                              onTap: () => _tapBubble(item),
                              child: _BubbleTarget(item: item),
                            ),
                          ),
                        if (!_running)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(235),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Text(
                                _finished ? 'Round complete' : 'Tap start',
                                style: const TextStyle(
                                  color: AppTheme.ink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _ArcadeActions(
            running: _running,
            finished: _finished,
            reward: _reward,
            claiming: _claiming,
            claimed: _claimed,
            onStart: _start,
            onClaim: _claim,
          ),
        ],
      ),
    );
  }
}

class _BubbleItem {
  const _BubbleItem({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.isBad,
    required this.createdAt,
  });

  final int id;
  final double x;
  final double y;
  final double size;
  final bool isBad;
  final DateTime createdAt;
}

class _BubbleTarget extends StatelessWidget {
  const _BubbleTarget({required this.item});
  final _BubbleItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: item.size,
      height: item.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha(235),
        boxShadow: AppTheme.softShadows(0.18),
      ),
      child: Icon(
        item.isBad ? Icons.close_rounded : Icons.pets_rounded,
        color: item.isBad ? const Color(0xFFE15B4F) : const Color(0xFF10A37F),
        size: item.size * 0.48,
      ),
    );
  }
}

class _ArcadeScoreBar extends StatelessWidget {
  const _ArcadeScoreBar({required this.score, required this.seconds, required this.reward});

  final int score;
  final int seconds;
  final int reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          _Metric(label: 'Score', value: '$score'),
          _Metric(label: 'Time', value: '${seconds}s'),
          _Metric(label: 'Reward', value: reward > 0 ? '+$reward' : '0'),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w900, fontSize: 21)),
        ],
      ),
    );
  }
}

class _ArcadeActions extends StatelessWidget {
  const _ArcadeActions({
    required this.running,
    required this.finished,
    required this.reward,
    required this.claiming,
    required this.claimed,
    required this.onStart,
    required this.onClaim,
  });

  final bool running;
  final bool finished;
  final int reward;
  final bool claiming;
  final bool claimed;
  final VoidCallback onStart;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: running ? null : onStart,
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), foregroundColor: AppTheme.ink),
            child: Text(finished ? 'Play again' : 'Start'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: finished && reward > 0 && !claiming && !claimed ? onClaim : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 50),
              backgroundColor: AppTheme.orangeDark,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(claiming ? 'Sending...' : claimed ? 'Sent' : 'Claim points'),
          ),
        ),
      ],
    );
  }
}

class _BubbleFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withAlpha(42);
    canvas.drawCircle(Offset(size.width * 0.16, size.height * 0.18), 48, paint);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.28), 72, paint);
    canvas.drawCircle(Offset(size.width * 0.56, size.height * 0.76), 64, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
