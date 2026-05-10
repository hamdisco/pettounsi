import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../ui/app_theme.dart';
import 'arcade_claim_service.dart';

class CatchTheTreatPage extends StatefulWidget {
  const CatchTheTreatPage({super.key});

  @override
  State<CatchTheTreatPage> createState() => _CatchTheTreatPageState();
}

class _CatchTheTreatPageState extends State<CatchTheTreatPage> {
  static const int _gameSeconds = 45;
  static const int _ticksPerSecond = 20;

  final Random _random = Random();
  final List<_TreatItem> _items = [];

  Timer? _timer;
  double _playerX = 0.5;
  int _score = 0;
  int _health = 3;
  int _remainingTicks = _gameSeconds * _ticksPerSecond;
  int _tick = 0;
  bool _running = false;
  bool _finished = false;
  bool _claiming = false;
  bool _claimed = false;

  int get _secondsLeft => min(max((_remainingTicks / _ticksPerSecond).ceil(), 0), _gameSeconds);
  int get _reward => ArcadeClaimService.catchTreatReward(_score);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _timer?.cancel();
    setState(() {
      _items.clear();
      _playerX = 0.5;
      _score = 0;
      _health = 3;
      _remainingTicks = _gameSeconds * _ticksPerSecond;
      _tick = 0;
      _running = true;
      _finished = false;
      _claiming = false;
      _claimed = false;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _step());
  }

  void _step() {
    if (!mounted || !_running) return;

    setState(() {
      _tick++;
      _remainingTicks--;

      if (_tick % 14 == 0) {
        _items.add(
          _TreatItem(
            x: 0.08 + _random.nextDouble() * 0.84,
            y: -0.08,
            bad: _random.nextInt(5) == 0,
            speed: 0.012 + _random.nextDouble() * 0.010,
          ),
        );
      }

      for (final item in _items) {
        item.y += item.speed;
      }

      final toRemove = <_TreatItem>[];
      for (final item in _items) {
        final nearBasket = item.y > 0.74 && item.y < 0.96 && (item.x - _playerX).abs() < 0.13;
        if (nearBasket) {
          if (item.bad) {
            _health--;
            _score = max(0, _score - 15);
          } else {
            _score += 10;
          }
          toRemove.add(item);
        } else if (item.y > 1.10) {
          toRemove.add(item);
        }
      }
      _items.removeWhere(toRemove.contains);

      if (_health <= 0 || _remainingTicks <= 0) {
        _finishGame();
      }
    });
  }

  void _finishGame() {
    _timer?.cancel();
    _running = false;
    _finished = true;
  }

  Future<void> _claimPoints() async {
    if (_claiming || _claimed) return;
    setState(() => _claiming = true);

    final result = await ArcadeClaimService.submitArcadeClaim(
      gameId: 'catch_treat',
      gameTitle: 'Catch the Treat',
      score: _score,
      reward: _reward,
      durationSeconds: _gameSeconds - _secondsLeft,
      resultLabel: 'Score $_score · Health $_health',
    );

    if (!mounted) return;
    setState(() {
      _claiming = false;
      _claimed = result.success;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Catch the Treat')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          _ArcadeHeader(
            title: 'Catch the Treat',
            subtitle: 'Move the bowl. Catch treats. Avoid spoiled food.',
            icon: Icons.sports_esports_rounded,
          ),
          const SizedBox(height: 12),
          _ScoreStrip(score: _score, seconds: _secondsLeft, health: _health, reward: _reward),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 0.82,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    if (!_running) return;
                    setState(() {
                      _playerX = (details.localPosition.dx / constraints.maxWidth).clamp(0.06, 0.94).toDouble();
                    });
                  },
                  onHorizontalDragUpdate: (details) {
                    if (!_running) return;
                    setState(() {
                      _playerX = (_playerX + details.delta.dx / constraints.maxWidth).clamp(0.06, 0.94).toDouble();
                    });
                  },
                  child: CustomPaint(
                    painter: _CatchTreatPainter(
                      items: List<_TreatItem>.from(_items),
                      playerX: _playerX,
                      running: _running,
                      finished: _finished,
                    ),
                    child: const SizedBox.expand(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _GameActionPanel(
            running: _running,
            finished: _finished,
            score: _score,
            reward: _reward,
            claimed: _claimed,
            claiming: _claiming,
            onStart: _startGame,
            onClaim: _claimPoints,
          ),
        ],
      ),
    );
  }
}

class _CatchTreatPainter extends CustomPainter {
  const _CatchTreatPainter({
    required this.items,
    required this.playerX,
    required this.running,
    required this.finished,
  });

  final List<_TreatItem> items;
  final double playerX;
  final bool running;
  final bool finished;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = AppTheme.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(28));
    canvas.drawRRect(rect, bgPaint);
    canvas.drawRRect(rect, borderPaint);

    final groundPaint = Paint()..color = AppTheme.softOrange.withAlpha(115);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12, size.height * 0.82, size.width - 24, size.height * 0.12),
        const Radius.circular(22),
      ),
      groundPaint,
    );

    for (final item in items) {
      _drawEmoji(canvas, item.bad ? '🧅' : '🦴', Offset(item.x * size.width, item.y * size.height), item.bad ? 24 : 27);
    }

    final bowlX = playerX * size.width;
    final bowlY = size.height * 0.86;
    final bowlPaint = Paint()..color = AppTheme.orangeDark;
    final bowlShadow = Paint()..color = Colors.black.withAlpha(20);
    canvas.drawOval(Rect.fromCenter(center: Offset(bowlX, bowlY + 5), width: 94, height: 22), bowlShadow);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(bowlX, bowlY), width: 86, height: 34),
        const Radius.circular(20),
      ),
      bowlPaint,
    );
    _drawEmoji(canvas, '🐶', Offset(bowlX, bowlY - 34), 34);

    if (!running && !finished) {
      _drawCenterLabel(canvas, size, 'Tap Start', 'Drag or tap to move the bowl');
    } else if (finished) {
      _drawCenterLabel(canvas, size, 'Game finished', 'Claim your daily arcade points');
    }
  }

  void _drawEmoji(Canvas canvas, String text, Offset center, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawCenterLabel(Canvas canvas, Size size, String title, String subtitle) {
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(color: AppTheme.ink, fontSize: 22, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width - 48);
    final subtitlePainter = TextPainter(
      text: TextSpan(
        text: subtitle,
        style: const TextStyle(color: AppTheme.muted, fontSize: 13, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width - 48);
    final y = size.height * 0.40;
    titlePainter.paint(canvas, Offset((size.width - titlePainter.width) / 2, y));
    subtitlePainter.paint(canvas, Offset((size.width - subtitlePainter.width) / 2, y + titlePainter.height + 6));
  }

  @override
  bool shouldRepaint(covariant _CatchTreatPainter oldDelegate) {
    return oldDelegate.items != items ||
        oldDelegate.playerX != playerX ||
        oldDelegate.running != running ||
        oldDelegate.finished != finished;
  }
}

class _TreatItem {
  _TreatItem({required this.x, required this.y, required this.bad, required this.speed});
  final double x;
  double y;
  final bool bad;
  final double speed;
}

class _ArcadeHeader extends StatelessWidget {
  const _ArcadeHeader({required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.18),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.blush,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Icon(icon, color: AppTheme.orangeDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w700, height: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreStrip extends StatelessWidget {
  const _ScoreStrip({required this.score, required this.seconds, required this.health, required this.reward});

  final int score;
  final int seconds;
  final int health;
  final int reward;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MiniScore(label: 'Score', value: '$score')),
        const SizedBox(width: 8),
        Expanded(child: _MiniScore(label: 'Time', value: '${seconds}s')),
        const SizedBox(width: 8),
        Expanded(child: _MiniScore(label: 'Lives', value: List.filled(max(0, min(3, health)), '❤').join())),
        const SizedBox(width: 8),
        Expanded(child: _MiniScore(label: 'Reward', value: reward > 0 ? '+$reward' : '—')),
      ],
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w800, fontSize: 11)),
          const SizedBox(height: 3),
          Text(value.isEmpty ? '—' : value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _GameActionPanel extends StatelessWidget {
  const _GameActionPanel({
    required this.running,
    required this.finished,
    required this.score,
    required this.reward,
    required this.claimed,
    required this.claiming,
    required this.onStart,
    required this.onClaim,
  });

  final bool running;
  final bool finished;
  final int score;
  final int reward;
  final bool claimed;
  final bool claiming;
  final VoidCallback onStart;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final canClaim = finished && reward > 0 && !claimed;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            finished
                ? 'Final score: $score · ${reward > 0 ? '+$reward pts available' : 'no points this round'}'
                : 'Daily arcade points are reviewed before they become official.',
            style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: running ? null : onStart,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(finished ? 'Play again' : 'Start'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canClaim && !claiming ? onClaim : null,
                  icon: claiming
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(claimed ? Icons.check_circle_rounded : Icons.emoji_events_rounded),
                  label: Text(claimed ? 'Submitted' : 'Claim'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
