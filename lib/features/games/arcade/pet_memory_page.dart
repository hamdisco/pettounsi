import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../ui/app_theme.dart';
import 'arcade_claim_service.dart';

class PetMemoryPage extends StatefulWidget {
  const PetMemoryPage({super.key});

  @override
  State<PetMemoryPage> createState() => _PetMemoryPageState();
}

class _PetMemoryPageState extends State<PetMemoryPage> {
  final Random _random = Random();
  late List<_MemoryCardData> _cards;
  final Set<int> _matched = <int>{};
  final List<int> _flipped = <int>[];

  Timer? _timer;
  int _seconds = 0;
  int _moves = 0;
  bool _busy = false;
  bool _started = false;
  bool _finished = false;
  bool _claiming = false;
  bool _claimed = false;

  int get _score => _finished ? ArcadeClaimService.petMemoryScore(moves: _moves, seconds: _seconds) : 0;
  int get _reward => ArcadeClaimService.petMemoryReward(_score);

  @override
  void initState() {
    super.initState();
    _cards = _buildCards();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<_MemoryCardData> _buildCards() {
    final symbols = ['🐶', '🐱', '🐰', '🦴', '🐾', '🎾'];
    final cards = <_MemoryCardData>[];
    for (var i = 0; i < symbols.length; i++) {
      cards.add(_MemoryCardData(pairId: i, symbol: symbols[i]));
      cards.add(_MemoryCardData(pairId: i, symbol: symbols[i]));
    }
    cards.shuffle(_random);
    return cards;
  }

  void _reset() {
    final cards = _buildCards();

    setState(() {
      _cards = cards;
      _matched.clear();
      _flipped.clear();
      _seconds = 0;
      _moves = 0;
      _busy = false;
      _started = false;
      _finished = false;
      _claiming = false;
      _claimed = false;
    });
    _timer?.cancel();
  }

  void _startTimerIfNeeded() {
    if (_started) return;
    _started = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _finished) return;
      setState(() => _seconds++);
    });
  }

  Future<void> _tapCard(int index) async {
    if (_busy || _finished || _matched.contains(index) || _flipped.contains(index)) return;
    _startTimerIfNeeded();

    setState(() => _flipped.add(index));

    if (_flipped.length < 2) return;

    setState(() {
      _busy = true;
      _moves++;
    });

    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    if (_flipped.length < 2) {
      setState(() => _busy = false);
      return;
    }

    final a = _flipped[0];
    final b = _flipped[1];
    final isMatch = _cards[a].pairId == _cards[b].pairId;

    setState(() {
      if (isMatch) {
        _matched.add(a);
        _matched.add(b);
      }
      _flipped.clear();
      _busy = false;
      if (_matched.length == _cards.length) {
        _finished = true;
        _timer?.cancel();
      }
    });
  }

  Future<void> _claimPoints() async {
    if (_claiming || _claimed || !_finished) return;
    setState(() => _claiming = true);

    final result = await ArcadeClaimService.submitArcadeClaim(
      gameId: 'pet_memory',
      gameTitle: 'Pet Memory',
      score: _score,
      reward: _reward,
      durationSeconds: _seconds,
      resultLabel: '$_moves moves · ${_seconds}s',
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
      appBar: AppBar(title: const Text('Pet Memory')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          _MemoryHeader(
            score: _score,
            reward: _reward,
            moves: _moves,
            seconds: _seconds,
            finished: _finished,
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final show = _matched.contains(index) || _flipped.contains(index);
              return _MemoryCard(
                symbol: _cards[index].symbol,
                visible: show,
                matched: _matched.contains(index),
                onTap: () => _tapCard(index),
              );
            },
          ),
          const SizedBox(height: 12),
          _MemoryActionPanel(
            finished: _finished,
            score: _score,
            reward: _reward,
            claimed: _claimed,
            claiming: _claiming,
            onReset: _reset,
            onClaim: _claimPoints,
          ),
        ],
      ),
    );
  }
}

class _MemoryHeader extends StatelessWidget {
  const _MemoryHeader({
    required this.score,
    required this.reward,
    required this.moves,
    required this.seconds,
    required this.finished,
  });

  final int score;
  final int reward;
  final int moves;
  final int seconds;
  final bool finished;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.blush,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: const Icon(Icons.grid_view_rounded, color: AppTheme.orangeDark),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pet Memory', style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w900, fontSize: 18)),
                    SizedBox(height: 4),
                    Text('Match all pet cards with fewer moves.', style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniMemoryStat(label: 'Moves', value: '$moves')),
              const SizedBox(width: 8),
              Expanded(child: _MiniMemoryStat(label: 'Time', value: '${seconds}s')),
              const SizedBox(width: 8),
              Expanded(child: _MiniMemoryStat(label: 'Score', value: finished ? '$score' : '—')),
              const SizedBox(width: 8),
              Expanded(child: _MiniMemoryStat(label: 'Reward', value: finished && reward > 0 ? '+$reward' : '—')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMemoryStat extends StatelessWidget {
  const _MiniMemoryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.mist,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w800, fontSize: 11)),
          const SizedBox(height: 3),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.symbol, required this.visible, required this.matched, required this.onTap});

  final String symbol;
  final bool visible;
  final bool matched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: visible ? Colors.white : AppTheme.orangeDark,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: matched ? AppTheme.orange : AppTheme.outline, width: matched ? 1.4 : 1),
            boxShadow: AppTheme.softShadows(0.14),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Text(
              visible ? symbol : '🐾',
              key: ValueKey('$visible$symbol'),
              style: TextStyle(fontSize: visible ? 32 : 26, color: visible ? null : Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryActionPanel extends StatelessWidget {
  const _MemoryActionPanel({
    required this.finished,
    required this.score,
    required this.reward,
    required this.claimed,
    required this.claiming,
    required this.onReset,
    required this.onClaim,
  });

  final bool finished;
  final int score;
  final int reward;
  final bool claimed;
  final bool claiming;
  final VoidCallback onReset;
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
                ? 'Completed: $score score · ${reward > 0 ? '+$reward pts available' : 'play again for points'}'
                : 'Start by flipping any card. Finish the board to unlock points.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Restart'),
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

class _MemoryCardData {
  const _MemoryCardData({required this.pairId, required this.symbol});
  final int pairId;
  final String symbol;
}
