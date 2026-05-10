import 'package:flutter/material.dart';

import '../../../ui/app_theme.dart';
import 'arcade_claim_service.dart';

class PetQuizPage extends StatefulWidget {
  const PetQuizPage({super.key});

  @override
  State<PetQuizPage> createState() => _PetQuizPageState();
}

class _PetQuizPageState extends State<PetQuizPage> {
  static const List<_QuizQuestion> _questions = [
    _QuizQuestion(
      question: 'What should a pet report include first?',
      options: ['Clear location', 'A funny caption', 'Only the pet name'],
      answerIndex: 0,
    ),
    _QuizQuestion(
      question: 'Before booking a sitter, owners should confirm:',
      options: ['Care routine', 'Favorite TV show', 'Phone brand'],
      answerIndex: 0,
    ),
    _QuizQuestion(
      question: 'A new food should usually be introduced:',
      options: ['Gradually', 'All at once', 'Only at night'],
      answerIndex: 0,
    ),
    _QuizQuestion(
      question: 'A trusted local business listing needs:',
      options: ['Contact details', 'Random emojis', 'No address'],
      answerIndex: 0,
    ),
    _QuizQuestion(
      question: 'For lost pets, a recent photo is:',
      options: ['Important', 'Not useful', 'Only optional for cats'],
      answerIndex: 0,
    ),
  ];

  int _index = 0;
  int _correct = 0;
  bool _finished = false;
  bool _claiming = false;
  bool _claimed = false;

  int get _reward => ArcadeClaimService.petQuizReward(_correct);

  void _answer(int selected) {
    if (_finished) return;
    final isCorrect = selected == _questions[_index].answerIndex;
    setState(() {
      if (isCorrect) _correct++;
      if (_index >= _questions.length - 1) {
        _finished = true;
      } else {
        _index++;
      }
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _correct = 0;
      _finished = false;
      _claiming = false;
      _claimed = false;
    });
  }

  Future<void> _claim() async {
    if (_claiming || _claimed || !_finished) return;
    setState(() => _claiming = true);

    final result = await ArcadeClaimService.submitArcadeClaim(
      gameId: 'pet_quiz',
      gameTitle: 'Pet Quiz',
      score: _correct * 100,
      reward: _reward,
      durationSeconds: 60,
      resultLabel: '$_correct/${_questions.length} correct',
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
    final question = _questions[_index];
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Pet Quiz'),
        backgroundColor: AppTheme.bg,
        foregroundColor: AppTheme.ink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF355C7D), Color(0xFFA6D8FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.softShadows(0.16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _QuizPill(text: '${_index + 1}/${_questions.length}'),
                    const SizedBox(width: 8),
                    _QuizPill(text: '$_correct correct'),
                    const Spacer(),
                    _QuizPill(text: _reward > 0 ? '+$_reward pts' : '0 pts'),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  _finished ? 'Quiz complete' : question.question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 22),
                if (!_finished)
                  for (int i = 0; i < question.options.length; i++) ...[
                    _AnswerButton(text: question.options[i], onTap: () => _answer(i)),
                    if (i != question.options.length - 1) const SizedBox(height: 10),
                  ]
                else
                  Text(
                    'You answered $_correct of ${_questions.length} correctly.',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _restart,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), foregroundColor: AppTheme.ink),
                  child: const Text('Restart'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _finished && _reward > 0 && !_claiming && !_claimed ? _claim : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    backgroundColor: AppTheme.orangeDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: Text(_claiming ? 'Sending...' : _claimed ? 'Sent' : 'Claim points'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizQuestion {
  const _QuizQuestion({required this.question, required this.options, required this.answerIndex});
  final String question;
  final List<String> options;
  final int answerIndex;
}

class _QuizPill extends StatelessWidget {
  const _QuizPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withAlpha(235), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(245),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Text(text, style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w900, fontSize: 14.4)),
        ),
      ),
    );
  }
}
