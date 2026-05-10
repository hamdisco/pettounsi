import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../ui/app_theme.dart';
import 'arcade_claim_service.dart';

class PawDashPage extends StatefulWidget {
  const PawDashPage({super.key});

  @override
  State<PawDashPage> createState() => _PawDashPageState();
}

class _PawDashPageState extends State<PawDashPage> {
  static const int _gameSeconds = 30;

  final Random _random = Random();
  Timer? _timer;

  double _x = 0.50;
  double _y = 0.50;
  int _score = 0;
  int _secondsLeft = _gameSeconds;
  bool _running = false;
  bool _finished = false;
  bool _claiming = false;
  bool _claimed = false;

  int get _reward => ArcadeClaimService.pawDashReward(_score);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _score = 0;
      _secondsLeft = _gameSeconds;
      _running = true;
      _finished = false;
      _claiming = false;
      _claimed = false;
      _moveTarget();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_running) return;
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _running = false;
          _finished = true;
          _timer?.cancel();
        }
      });
    });
  }

  void _moveTarget() {
    _x = 0.12 + _random.nextDouble() * 0.76;
    _y = 0.12 + _random.nextDouble() * 0.72;
  }

  void _hit() {
    if (!_running) return;
    setState(() {
      _score += 10;
      _moveTarget();
    });
  }

  Future<void> _claim() async {
    if (_claiming || _claimed || !_finished) return;
    setState(() => _claiming = true);

    final result = await ArcadeClaimService.submitArcadeClaim(
      gameId: 'paw_dash',
      gameTitle: 'Paw Dash',
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
        title: const Text('Paw Dash'),
        backgroundColor: AppTheme.bg,
        foregroundColor: AppTheme.ink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          _DashScore(score: _score, seconds: _secondsLeft, reward: _reward),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 0.92,
            child: LayoutBuilder(
              builder: (context, box) {
                final targetLeft = (box.maxWidth - 74) * _x;
                final targetTop = (box.maxHeight - 74) * _y;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppTheme.outline),
                    boxShadow: AppTheme.softShadows(0.12),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: CustomPaint(painter: _DashPainter())),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        left: targetLeft,
                        top: targetTop,
                        child: GestureDetector(
                          onTap: _hit,
                          child: Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF8A67), Color(0xFFFFC47D)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: AppTheme.softShadows(0.22),
                            ),
                            child: const Icon(
                              Icons.pets_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                      if (!_running)
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              _finished ? 'Finished' : 'Tap start',
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _DashActions(
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

class _DashScore extends StatelessWidget {
  const _DashScore({
    required this.score,
    required this.seconds,
    required this.reward,
  });

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
          _DashMetric(label: 'Score', value: '$score'),
          _DashMetric(label: 'Time', value: '${seconds}s'),
          _DashMetric(label: 'Reward', value: reward > 0 ? '+$reward' : '0'),
        ],
      ),
    );
  }
}

class _DashMetric extends StatelessWidget {
  const _DashMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.muted,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 21,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashActions extends StatelessWidget {
  const _DashActions({
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
          child: OutlinedButton.icon(
            onPressed: running ? null : onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(finished ? 'Play again' : 'Start'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              foregroundColor: AppTheme.ink,
              side: const BorderSide(color: AppTheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: finished && reward > 0 && !claiming && !claimed
                ? onClaim
                : null,
            icon: claiming
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_circle_outline_rounded),
            label: Text(claimed ? 'Claimed' : 'Claim'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 48),
              backgroundColor: AppTheme.orangeDark,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppTheme.outline.withAlpha(90)
      ..strokeWidth = 1.2;
    for (var i = 1; i < 4; i++) {
      final dx = size.width * i / 4;
      final dy = size.height * i / 4;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), line);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
