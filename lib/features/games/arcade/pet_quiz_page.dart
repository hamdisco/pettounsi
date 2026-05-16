import 'dart:math';

import 'package:flutter/material.dart';

import '../../../ui/app_theme.dart';
import 'arcade_claim_service.dart';

class PetQuizPage extends StatefulWidget {
  const PetQuizPage({super.key});

  @override
  State<PetQuizPage> createState() => _PetQuizPageState();
}

class _PetQuizPageState extends State<PetQuizPage> {
  static const int _roundLength = 8;

  static const List<_QuizQuestion> _bank = [
    _QuizQuestion(
      category: 'Lost pet safety',
      question: 'What should a lost pet report show first?',
      options: [
        'Clear location and recent photo',
        'Only the pet name',
        'A funny caption',
      ],
      answerIndex: 0,
      explanation:
          'A recent photo and a clear location help nearby people act quickly.',
    ),
    _QuizQuestion(
      category: 'Sitter trust',
      question: 'Before booking a sitter, what should an owner confirm?',
      options: [
        'Daily routine, dates, and emergency contact',
        'The sitter\'s favorite TV show',
        'Only the pet color',
      ],
      answerIndex: 0,
      explanation:
          'Routine, dates, and emergency details reduce confusion during the stay.',
    ),
    _QuizQuestion(
      category: 'Food care',
      question: 'How should a new pet food usually be introduced?',
      options: ['Gradually over several days', 'All at once', 'Only at night'],
      answerIndex: 0,
      explanation:
          'Gradual changes are safer for digestion and make reactions easier to notice.',
    ),
    _QuizQuestion(
      category: 'Local services',
      question: 'A trusted vet or pet shop listing should include:',
      options: [
        'Contact details and location',
        'Random emojis only',
        'No address',
      ],
      answerIndex: 0,
      explanation:
          'Useful listings need real contact information and a clear place to visit.',
    ),
    _QuizQuestion(
      category: 'Photos',
      question: 'For adoption or rescue posts, the best photo is:',
      options: [
        'Clear, recent, and honest',
        'Very dark and blurry',
        'A random image from the internet',
      ],
      answerIndex: 0,
      explanation:
          'Clear real photos help people understand the pet and build trust.',
    ),
    _QuizQuestion(
      category: 'Messages',
      question: 'When contacting a sitter, the first message should be:',
      options: [
        'Specific and respectful',
        'Only “hi”',
        'A repeated spam message',
      ],
      answerIndex: 0,
      explanation:
          'Specific messages help sitters answer faster and more accurately.',
    ),
    _QuizQuestion(
      category: 'Events',
      question: 'Before going to a pet event, you should check:',
      options: [
        'Date, time, location, and pet rules',
        'Only the poster color',
        'Nothing',
      ],
      answerIndex: 0,
      explanation:
          'Good preparation avoids arriving late or bringing a pet where it is not allowed.',
    ),
    _QuizQuestion(
      category: 'Pet Sitting',
      question: 'A strong sitter listing should clearly explain:',
      options: [
        'Accepted pets, routine, price, and availability',
        'Only one emoji',
        'Nothing about the stay',
      ],
      answerIndex: 0,
      explanation:
          'Clear details help owners decide safely before sending a request.',
    ),
    _QuizQuestion(
      category: 'Safety',
      question: 'If a pet seems sick during a stay, the sitter should:',
      options: [
        'Contact the owner and a vet if needed',
        'Ignore it',
        'Post jokes about it',
      ],
      answerIndex: 0,
      explanation:
          'Fast communication protects the pet and keeps the owner informed.',
    ),
    _QuizQuestion(
      category: 'Community',
      question: 'A useful pet community comment should be:',
      options: ['Helpful and respectful', 'Insulting', 'Unrelated spam'],
      answerIndex: 0,
      explanation:
          'Respectful comments make the community safer and more useful.',
    ),
    _QuizQuestion(
      category: 'Reviews',
      question: 'A good review after pet sitting should mention:',
      options: [
        'Real experience and care quality',
        'Fake praise only',
        'Someone else\'s story',
      ],
      answerIndex: 0,
      explanation:
          'Real reviews help future owners choose with more confidence.',
    ),
    _QuizQuestion(
      category: 'Profile trust',
      question: 'A trustworthy profile usually has:',
      options: [
        'Clear name, photo, and honest details',
        'Confusing fake information',
        'No useful information',
      ],
      answerIndex: 0,
      explanation:
          'A clear profile makes messages, reviews, and requests easier to trust.',
    ),
    _QuizQuestion(
      category: 'Pet comfort',
      question: 'When a pet arrives at a new sitter home, it helps to:',
      options: [
        'Bring familiar food or a small familiar item',
        'Change every routine immediately',
        'Avoid sharing care notes',
      ],
      answerIndex: 0,
      explanation:
          'Familiar items and clear notes can reduce stress during the stay.',
    ),
    _QuizQuestion(
      category: 'Adoption',
      question: 'Before adopting a pet, a family should think about:',
      options: [
        'Time, budget, space, and long-term care',
        'Only the pet color',
        'Only social media likes',
      ],
      answerIndex: 0,
      explanation:
          'Adoption is a long-term responsibility, not only a quick emotional choice.',
    ),
    _QuizQuestion(
      category: 'Health',
      question: 'A pet vaccination or health question is best handled by:',
      options: [
        'A veterinarian',
        'Random comments only',
        'Guessing without help',
      ],
      answerIndex: 0,
      explanation:
          'Health decisions should come from a qualified professional.',
    ),
    _QuizQuestion(
      category: 'Marketplace safety',
      question: 'When buying pet accessories locally, check:',
      options: [
        'Condition, size, price, and seller details',
        'Only the background color',
        'Nothing before paying',
      ],
      answerIndex: 0,
      explanation: 'Clear checks reduce bad purchases and misunderstandings.',
    ),
  ];

  late List<_QuizQuestion> _roundQuestions;
  int _index = 0;
  int _correct = 0;
  int? _selectedIndex;
  bool _answered = false;
  bool _finished = false;
  bool _claiming = false;
  bool _claimed = false;

  int get _reward => _finished ? ArcadeClaimService.dailyGameReward : 0;

  _QuizQuestion get _question => _roundQuestions[_index];

  @override
  void initState() {
    super.initState();
    _startNewRound();
  }

  void _startNewRound() {
    final shuffled = List<_QuizQuestion>.of(_bank)..shuffle(Random());
    _roundQuestions = shuffled.take(_roundLength).toList();
    _index = 0;
    _correct = 0;
    _selectedIndex = null;
    _answered = false;
    _finished = false;
    _claiming = false;
  }

  void _answer(int selected) {
    if (_finished || _answered) return;
    final isCorrect = selected == _question.answerIndex;
    setState(() {
      _selectedIndex = selected;
      _answered = true;
      if (isCorrect) _correct++;
    });
  }

  void _next() {
    if (!_answered || _finished) return;
    if (_index >= _roundQuestions.length - 1) {
      setState(() => _finished = true);
      Future<void>.microtask(_claim);
      return;
    }
    setState(() {
      _index++;
      _selectedIndex = null;
      _answered = false;
    });
  }

  void _restart() {
    setState(_startNewRound);
  }

  Future<void> _claim() async {
    if (_claiming || _claimed || !_finished) return;
    setState(() => _claiming = true);

    final result = await ArcadeClaimService.submitArcadeClaim(
      gameId: 'pet_quiz',
      gameTitle: 'Pet Quiz',
      score: _correct * 125,
      reward: _reward,
      durationSeconds: 90,
      resultLabel: '$_correct/${_roundQuestions.length} correct',
    );

    if (!mounted) return;
    setState(() {
      _claiming = false;
      _claimed = result.success || result.collectedToday;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) {
    final progress = _finished
        ? 1.0
        : (_index + (_answered ? 1 : 0)) / _roundQuestions.length;
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
          _HeroCard(
            correct: _correct,
            total: _roundQuestions.length,
            progress: progress,
            rewardText: _claimed ? 'Added today' : '+1 point',
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _finished ? _buildResultCard() : _buildQuestionCard(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _restart,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    foregroundColor: AppTheme.ink,
                    side: BorderSide(color: AppTheme.ink.withAlpha(35)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('New round'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _finished ? null : (_answered ? _next : null),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    backgroundColor: AppTheme.orangeDark,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.orangeDark.withAlpha(90),
                    disabledForegroundColor: Colors.white.withAlpha(210),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    _finished
                        ? (_claiming ? 'Adding...' : 'Completed')
                        : 'Continue',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final question = _question;
    return Container(
      key: ValueKey('question_$_index'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadows(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _QuizPill(text: question.category),
              const Spacer(),
              Text(
                '${_index + 1}/${_roundQuestions.length}',
                style: TextStyle(
                  color: AppTheme.muted.withAlpha(210),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            question.question,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < question.options.length; i++) ...[
            _AnswerButton(
              text: question.options[i],
              isSelected: _selectedIndex == i,
              isCorrect: i == question.answerIndex,
              reveal: _answered,
              onTap: () => _answer(i),
            ),
            if (i != question.options.length - 1) const SizedBox(height: 10),
          ],
          if (_answered) ...[
            const SizedBox(height: 14),
            _ExplanationBox(
              correct: _selectedIndex == question.answerIndex,
              text: question.explanation,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final percent = ((_correct / _roundQuestions.length) * 100).round();
    final title = percent >= 80
        ? 'Excellent pet care instincts'
        : percent >= 50
        ? 'Good progress'
        : 'Keep learning';
    final body = percent >= 80
        ? 'You are ready to help the community with safer, clearer pet care decisions.'
        : percent >= 50
        ? 'You know the basics. A few more rounds will make the answers feel natural.'
        : 'Try another round and focus on safety, trust, and clear information.';

    return Container(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadows(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.orange.withAlpha(28),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppTheme.orangeDark,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: AppTheme.muted.withAlpha(235),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ResultTile(
                  label: 'Score',
                  value: '$_correct/${_roundQuestions.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ResultTile(
                  label: 'Reward',
                  value: _claimed ? 'Added' : '+1 point',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _claiming
                ? 'Adding your point...'
                : _claimed
                ? 'This quiz already counted for today.'
                : 'Finish the round to collect today\'s quiz point.',
            style: TextStyle(
              color: AppTheme.muted.withAlpha(210),
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.correct,
    required this.total,
    required this.progress,
    required this.rewardText,
  });

  final int correct;
  final int total;
  final double progress;
  final String rewardText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF355C7D), Color(0xFF7CC8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppTheme.softShadows(0.16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(235),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Color(0xFF355C7D),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pet Care Quiz',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Learn safer choices for real PetTounsi situations.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: Colors.white.withAlpha(70),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeroPill(text: '$correct/$total correct'),
              const SizedBox(width: 8),
              _HeroPill(text: rewardText),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizQuestion {
  const _QuizQuestion({
    required this.category,
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.explanation,
  });

  final String category;
  final String question;
  final List<String> options;
  final int answerIndex;
  final String explanation;
}

class _QuizPill extends StatelessWidget {
  const _QuizPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.orange.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.orangeDark,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.ink,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.text,
    required this.onTap,
    required this.isSelected,
    required this.isCorrect,
    required this.reveal,
  });

  final String text;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isCorrect;
  final bool reveal;

  @override
  Widget build(BuildContext context) {
    final showCorrect = reveal && isCorrect;
    final showWrong = reveal && isSelected && !isCorrect;
    final bg = showCorrect
        ? const Color(0xFFE9F8EF)
        : showWrong
        ? const Color(0xFFFFEEEE)
        : AppTheme.bg;
    final border = showCorrect
        ? const Color(0xFF4FAE75)
        : showWrong
        ? const Color(0xFFE46A6A)
        : Colors.transparent;
    final icon = showCorrect
        ? Icons.check_circle_rounded
        : showWrong
        ? Icons.cancel_rounded
        : Icons.radio_button_unchecked_rounded;
    final iconColor = showCorrect
        ? const Color(0xFF2F8F55)
        : showWrong
        ? const Color(0xFFC94D4D)
        : AppTheme.muted.withAlpha(150);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: reveal ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: reveal ? 1.2 : 0),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: iconColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplanationBox extends StatelessWidget {
  const _ExplanationBox({required this.correct, required this.text});

  final bool correct;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: correct ? const Color(0xFFE9F8EF) : const Color(0xFFFFF5EA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct ? Icons.lightbulb_rounded : Icons.tips_and_updates_rounded,
            color: correct ? const Color(0xFF2F8F55) : AppTheme.orangeDark,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.ink.withAlpha(220),
                fontWeight: FontWeight.w800,
                height: 1.32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.muted.withAlpha(210),
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
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
