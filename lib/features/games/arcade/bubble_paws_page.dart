import 'dart:math';

import 'package:flutter/material.dart';

import '../../../ui/app_theme.dart';
import 'arcade_claim_service.dart';

const int _gridSize = 5;

class BubblePawsPage extends StatefulWidget {
  const BubblePawsPage({super.key});

  @override
  State<BubblePawsPage> createState() => _BubblePawsPageState();
}

class _BubblePawsPageState extends State<BubblePawsPage> {
  static const int _gridSize = 5;
  static const String _gameId = 'bubble_paws';
  final Random _random = Random();

  late _MazeRound _round;
  _Point _pet = const _Point(0, 4);
  int _moves = 0;
  int _score = 0;
  int _snacks = 0;
  int _bumps = 0;
  bool _running = false;
  bool _finished = false;
  bool _claiming = false;
  bool _claimed = false;
  bool _lockedToday = false;
  bool _checkingLock = true;

  int get _reward =>
      _finished && _score > 0 ? ArcadeClaimService.dailyGameReward : 0;

  @override
  void initState() {
    super.initState();
    _round = _buildRound();
    _loadTodayLock();
  }

  Future<void> _loadTodayLock() async {
    final locked = await ArcadeClaimService.hasCollectedToday(_gameId);
    if (!mounted) return;
    setState(() {
      _lockedToday = locked;
      _checkingLock = false;
    });
  }

  _MazeRound _buildRound() {
    final hazards = <_Point>{};
    final snacks = <_Point>{};
    const start = _Point(0, 4);
    const goal = _Point(4, 0);

    final safeRoute = <_Point>{
      start,
      const _Point(1, 4),
      const _Point(2, 4),
      const _Point(2, 3),
      const _Point(2, 2),
      const _Point(3, 2),
      const _Point(4, 2),
      const _Point(4, 1),
      goal,
    };

    final all = <_Point>[
      for (var y = 0; y < _gridSize; y++)
        for (var x = 0; x < _gridSize; x++) _Point(x, y),
    ]..shuffle(_random);

    for (final point in all) {
      if (hazards.length >= 5) break;
      if (safeRoute.contains(point)) continue;
      hazards.add(point);
    }

    final snackCandidates =
        safeRoute.where((p) => p != start && p != goal).toList()
          ..shuffle(_random);
    snacks.addAll(snackCandidates.take(4));

    return _MazeRound(
      start: start,
      goal: goal,
      hazards: hazards,
      snacks: snacks,
    );
  }

  Future<void> _start() async {
    if (_checkingLock) return;
    final locked = await ArcadeClaimService.hasCollectedToday(_gameId);
    if (!mounted) return;
    if (locked) {
      setState(() => _lockedToday = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paw Maze already counted today. Come back tomorrow.'),
        ),
      );
      return;
    }

    final round = _buildRound();
    setState(() {
      _round = round;
      _pet = round.start;
      _moves = 0;
      _score = 0;
      _snacks = 0;
      _bumps = 0;
      _running = true;
      _finished = false;
      _claiming = false;
      _claimed = false;
      _lockedToday = false;
    });
  }

  void _move(_Direction direction) {
    if (!_running || _finished || _lockedToday) return;
    final next = switch (direction) {
      _Direction.up => _Point(_pet.x, _pet.y - 1),
      _Direction.down => _Point(_pet.x, _pet.y + 1),
      _Direction.left => _Point(_pet.x - 1, _pet.y),
      _Direction.right => _Point(_pet.x + 1, _pet.y),
    };

    if (next.x < 0 ||
        next.x >= _gridSize ||
        next.y < 0 ||
        next.y >= _gridSize) {
      setState(() {
        _bumps++;
        _score = max(0, _score - 5);
      });
      return;
    }

    final snacks = Set<_Point>.of(_round.snacks);
    var nextScore = _score + 10;
    var nextSnacks = _snacks;
    if (snacks.remove(next)) {
      nextScore += 35;
      nextSnacks++;
    }
    if (_round.hazards.contains(next)) {
      nextScore = max(0, nextScore - 25);
      setState(() {
        _pet = next;
        _moves++;
        _score = nextScore;
        _bumps++;
        _snacks = nextSnacks;
        _round = _round.copyWith(snacks: snacks);
      });
      return;
    }

    final reachedGoal = next == _round.goal;
    if (reachedGoal) {
      nextScore += max(20, 120 - (_moves * 5));
    }

    setState(() {
      _pet = next;
      _moves++;
      _score = nextScore;
      _snacks = nextSnacks;
      _round = _round.copyWith(snacks: snacks);
      if (reachedGoal) {
        _running = false;
        _finished = true;
      }
    });

    if (reachedGoal) {
      Future<void>.microtask(_claim);
    }
  }

  Future<void> _claim() async {
    if (_claiming || _claimed || !_finished || _score <= 0) return;
    setState(() => _claiming = true);

    final result = await ArcadeClaimService.submitArcadeClaim(
      gameId: _gameId,
      gameTitle: 'Paw Maze',
      score: _score,
      reward: _reward,
      durationSeconds: _moves,
      resultLabel: 'Score $_score · $_moves moves · $_snacks snacks',
    );

    if (!mounted) return;
    setState(() {
      _claiming = false;
      _claimed = result.success || result.collectedToday;
      _lockedToday = result.success || result.collectedToday;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Paw Maze'),
        backgroundColor: AppTheme.bg,
        foregroundColor: AppTheme.ink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          const _MazeIntro(),
          const SizedBox(height: 12),
          _MazeStatusCard(
            score: _score,
            moves: _moves,
            snacks: _snacks,
            reward: _reward,
            lockedToday: _lockedToday,
            checkingLock: _checkingLock,
          ),
          const SizedBox(height: 12),
          _MazeBoard(
            round: _round,
            pet: _pet,
            running: _running,
            finished: _finished,
          ),
          const SizedBox(height: 12),
          _MazeControls(
            enabled: _running && !_finished && !_lockedToday,
            onMove: _move,
          ),
          const SizedBox(height: 12),
          _MazeResultCard(
            finished: _finished,
            lockedToday: _lockedToday,
            score: _score,
            moves: _moves,
            snacks: _snacks,
            bumps: _bumps,
            claiming: _claiming,
            claimed: _claimed,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _lockedToday || _checkingLock ? null : _start,
            icon: Icon(
              _finished ? Icons.refresh_rounded : Icons.play_arrow_rounded,
            ),
            label: Text(
              _checkingLock
                  ? 'Checking today\'s play...'
                  : _lockedToday
                  ? 'Played today'
                  : _finished
                  ? 'New maze'
                  : 'Start maze',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D5B),
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.outline,
              disabledForegroundColor: AppTheme.muted,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MazeIntro extends StatelessWidget {
  const _MazeIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
        boxShadow: AppTheme.softShadows(0.12),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D5B), Color(0xFF9CCC65)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(
              Icons.travel_explore_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paw Maze',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Guide the pet home, collect treats, and avoid unsafe tiles. One point can count per day.',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                    height: 1.22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MazeStatusCard extends StatelessWidget {
  const _MazeStatusCard({
    required this.score,
    required this.moves,
    required this.snacks,
    required this.reward,
    required this.lockedToday,
    required this.checkingLock,
  });

  final int score;
  final int moves;
  final int snacks;
  final int reward;
  final bool lockedToday;
  final bool checkingLock;

  @override
  Widget build(BuildContext context) {
    final rewardText = checkingLock
        ? 'Checking'
        : lockedToday
        ? 'Done today'
        : reward > 0
        ? '+1'
        : '+1 ready';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          _MazeMetric(label: 'Score', value: '$score'),
          _MazeMetric(label: 'Moves', value: '$moves'),
          _MazeMetric(label: 'Treats', value: '$snacks'),
          _MazeMetric(label: 'Reward', value: rewardText),
        ],
      ),
    );
  }
}

class _MazeMetric extends StatelessWidget {
  const _MazeMetric({required this.label, required this.value});
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
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _MazeBoard extends StatelessWidget {
  const _MazeBoard({
    required this.round,
    required this.pet,
    required this.running,
    required this.finished,
  });

  final _MazeRound round;
  final _Point pet;
  final bool running;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF8F1), Color(0xFFFFFAF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withAlpha(235)),
        boxShadow: AppTheme.softShadows(0.16),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _gridSize * _gridSize,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridSize,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final point = _Point(index % _gridSize, index ~/ _gridSize);
            final isPet = point == pet;
            final isGoal = point == round.goal;
            final isHazard = round.hazards.contains(point);
            final isSnack = round.snacks.contains(point);
            return _MazeTile(
              isPet: isPet,
              isGoal: isGoal,
              isHazard: isHazard,
              isSnack: isSnack,
              dimmed: !running && !finished,
            );
          },
        ),
      ),
    );
  }
}

class _MazeTile extends StatelessWidget {
  const _MazeTile({
    required this.isPet,
    required this.isGoal,
    required this.isHazard,
    required this.isSnack,
    required this.dimmed,
  });

  final bool isPet;
  final bool isGoal;
  final bool isHazard;
  final bool isSnack;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final color = isGoal
        ? const Color(0xFFDFF4E7)
        : isHazard
        ? const Color(0xFFFFE4DF)
        : isSnack
        ? const Color(0xFFFFF4D8)
        : Colors.white;
    final icon = isPet
        ? Icons.pets_rounded
        : isGoal
        ? Icons.home_rounded
        : isHazard
        ? Icons.warning_amber_rounded
        : isSnack
        ? Icons.cookie_rounded
        : Icons.grass_rounded;
    final iconColor = isPet
        ? AppTheme.orangeDark
        : isGoal
        ? const Color(0xFF2E7D5B)
        : isHazard
        ? const Color(0xFFB74C3C)
        : isSnack
        ? const Color(0xFFB98218)
        : AppTheme.muted.withAlpha(130);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: dimmed ? color.withAlpha(180) : color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPet ? AppTheme.orange : Colors.white.withAlpha(235),
          width: isPet ? 2 : 1,
        ),
      ),
      child: Icon(icon, color: iconColor, size: isPet ? 29 : 23),
    );
  }
}

class _MazeControls extends StatelessWidget {
  const _MazeControls({required this.enabled, required this.onMove});

  final bool enabled;
  final ValueChanged<_Direction> onMove;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, _Direction direction) {
      return SizedBox(
        width: 58,
        height: 48,
        child: FilledButton(
          onPressed: enabled ? () => onMove(direction) : null,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2E7D5B),
            disabledBackgroundColor: Colors.white.withAlpha(170),
            disabledForegroundColor: AppTheme.muted.withAlpha(150),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Icon(icon),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          button(Icons.keyboard_arrow_up_rounded, _Direction.up),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              button(Icons.keyboard_arrow_left_rounded, _Direction.left),
              const SizedBox(width: 8),
              button(Icons.keyboard_arrow_down_rounded, _Direction.down),
              const SizedBox(width: 8),
              button(Icons.keyboard_arrow_right_rounded, _Direction.right),
            ],
          ),
        ],
      ),
    );
  }
}

class _MazeResultCard extends StatelessWidget {
  const _MazeResultCard({
    required this.finished,
    required this.lockedToday,
    required this.score,
    required this.moves,
    required this.snacks,
    required this.bumps,
    required this.claiming,
    required this.claimed,
  });

  final bool finished;
  final bool lockedToday;
  final int score;
  final int moves;
  final int snacks;
  final int bumps;
  final bool claiming;
  final bool claimed;

  @override
  Widget build(BuildContext context) {
    final message = lockedToday && !finished
        ? 'Paw Maze already counted today. Come back tomorrow.'
        : finished
        ? 'Finished with $score score, $snacks treats, and $moves moves.'
        : 'Reach the home tile to finish the maze.';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: finished || lockedToday
                  ? const Color(0xFFE8F5E9)
                  : AppTheme.blush,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              finished || lockedToday
                  ? Icons.check_circle_rounded
                  : Icons.flag_rounded,
              color: finished || lockedToday
                  ? const Color(0xFF2E7D5B)
                  : AppTheme.orangeDark,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              claiming
                  ? 'Adding your point...'
                  : claimed
                  ? '+1 point added.'
                  : message,
              style: const TextStyle(
                color: AppTheme.ink,
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

enum _Direction { up, down, left, right }

class _Point {
  const _Point(this.x, this.y);
  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is _Point && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

class _MazeRound {
  const _MazeRound({
    required this.start,
    required this.goal,
    required this.hazards,
    required this.snacks,
  });

  final _Point start;
  final _Point goal;
  final Set<_Point> hazards;
  final Set<_Point> snacks;

  _MazeRound copyWith({Set<_Point>? snacks}) {
    return _MazeRound(
      start: start,
      goal: goal,
      hazards: hazards,
      snacks: snacks ?? this.snacks,
    );
  }
}
