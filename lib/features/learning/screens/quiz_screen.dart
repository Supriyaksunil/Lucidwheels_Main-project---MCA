import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/custom_card.dart';
import '../data/learning_data.dart';
import '../models/quiz_model.dart';
import '../widgets/question_card.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final List<QuizModel>? questions;

  const QuizScreen({super.key, this.questions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const Color _pageBackground = Color(0xFFF6F8FF);
  static const Color _softBorder = Color(0xFFD7E1FF);
  static const Color _primaryText = AppTheme.primaryBlue;
  static const Color _secondaryText = Color(0xFF4D5AA6);
  static const LinearGradient _pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5FF)],
  );

  late final List<QuizModel> _questions;
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedOption;
  bool _locked = false;
  Timer? _nextTimer;

  @override
  void initState() {
    super.initState();
    final source = widget.questions ?? LearningData.quizQuestions();
    _questions = List<QuizModel>.from(source)..shuffle(Random());
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    super.dispose();
  }

  int get _answeredCount => _currentIndex + (_locked ? 1 : 0);

  String get _level {
    final attempted = _answeredCount;
    if (attempted == 0) {
      return 'Beginner';
    }
    final ratio = _score / attempted;
    return ratio >= 0.6 ? 'Intermediate' : 'Beginner';
  }

  void _selectOption(String option) {
    if (_locked) {
      return;
    }

    final current = _questions[_currentIndex];
    final isCorrect = current.isCorrect(option);

    setState(() {
      _selectedOption = option;
      _locked = true;
      if (isCorrect) {
        _score += 1;
      }
    });

    _nextTimer?.cancel();
    _nextTimer = Timer(const Duration(milliseconds: 850), _goNext);
  }

  void _goNext() {
    if (!mounted) {
      return;
    }

    if (_currentIndex == _questions.length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            title: 'Quiz Mode',
            score: _score,
            total: _questions.length,
            restartBuilder: (_) => const QuizScreen(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _currentIndex += 1;
      _selectedOption = null;
      _locked = false;
    });
  }

  Future<void> _stopQuizAndShowScore() async {
    _nextTimer?.cancel();

    final attempted = _answeredCount;
    final shouldStop = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Stop Quiz?',
              style: TextStyle(color: _primaryText),
            ),
            content: Text(
              'Current score: $_score\nAnswered: $attempted\nRemaining: ${_questions.length - attempted}',
              style: const TextStyle(color: _secondaryText),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: _primaryText),
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Continue'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryText,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Show Score'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldStop || !mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          title: 'Quiz Stopped',
          score: _score,
          total: attempted,
          restartBuilder: (_) => const QuizScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const AppScaffold(
        title: 'Quiz Mode',
        scaffoldBackgroundColor: _pageBackground,
        backgroundDecoration: BoxDecoration(gradient: _pageGradient),
        appBarBackgroundColor: Colors.white,
        appBarForegroundColor: _primaryText,
        appBarTitleTextStyle: TextStyle(
          color: _primaryText,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        body: Center(
          child: Text(
            'No quiz questions available.',
            style: TextStyle(color: _secondaryText),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];

    return AppScaffold(
      title: 'Quiz Mode',
      scaffoldBackgroundColor: _pageBackground,
      backgroundDecoration: const BoxDecoration(gradient: _pageGradient),
      appBarBackgroundColor: Colors.white,
      appBarForegroundColor: _primaryText,
      appBarTitleTextStyle: const TextStyle(
        color: _primaryText,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      actions: [
        IconButton(
          tooltip: 'Stop Quiz',
          onPressed: _stopQuizAndShowScore,
          icon: const Icon(Icons.stop_circle_outlined),
        ),
      ],
      body: Padding(
        padding: AppTheme.pagePadding,
        child: Column(
          children: [
            _QuizHeaderCard(
              currentIndex: _currentIndex,
              total: _questions.length,
              score: _score,
              level: _level,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey(
                            'q_$_currentIndex$_locked$_selectedOption'),
                        child: QuestionCard(
                          question: question.question,
                          imagePath: question.image,
                          options: question.options,
                          selectedOption: _selectedOption,
                          lockAnswers: _locked,
                          correctAnswer: _locked ? question.answer : null,
                          onOptionSelected: _selectOption,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomCard(
                      color: Colors.white,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
                      ),
                      border: const Border.fromBorderSide(
                        BorderSide(color: _softBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _locked
                                ? (question.isCorrect(_selectedOption ?? '')
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded)
                                : Icons.touch_app_rounded,
                            color: _locked &&
                                    !question.isCorrect(_selectedOption ?? '')
                                ? AppTheme.accentRed
                                : _primaryText,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _locked
                                  ? (question.isCorrect(_selectedOption ?? '')
                                      ? 'Correct answer. Moving to next question...'
                                      : 'Incorrect answer. Moving to next question...')
                                  : 'Select one option to continue.',
                              style: const TextStyle(
                                color: _secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizHeaderCard extends StatelessWidget {
  static const Color _softBorder = Color(0xFFD7E1FF);
  static const Color _primaryText = AppTheme.primaryBlue;
  static const Color _secondaryText = Color(0xFF4D5AA6);

  final int currentIndex;
  final int total;
  final int score;
  final String level;

  const _QuizHeaderCard({
    required this.currentIndex,
    required this.total,
    required this.score,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      color: Colors.white,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
      ),
      border: const Border.fromBorderSide(BorderSide(color: _softBorder)),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Question ${currentIndex + 1} / $total',
                style: const TextStyle(
                  color: _primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Score: $score',
                style: const TextStyle(
                  color: _primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Level: $level',
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${((currentIndex + 1) / total * 100).round()}%',
                style: const TextStyle(
                  color: _secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (currentIndex + 1) / total,
              minHeight: 8,
              backgroundColor: _primaryText.withValues(alpha: 0.12),
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}
