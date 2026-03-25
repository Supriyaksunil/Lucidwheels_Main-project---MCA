import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/custom_card.dart';

class QuestionCard extends StatelessWidget {
  final String question;
  final String imagePath;
  final List<String> options;
  final ValueChanged<String> onOptionSelected;
  final String? selectedOption;
  final bool lockAnswers;
  final String? correctAnswer;

  const QuestionCard({
    super.key,
    required this.question,
    required this.imagePath,
    required this.options,
    required this.onOptionSelected,
    this.selectedOption,
    this.lockAnswers = false,
    this.correctAnswer,
  });

  static const Color _softBorder = Color(0xFFD7E1FF);
  static const Color _primaryText = AppTheme.primaryBlue;
  static const Color _secondaryText = Color(0xFF4D5AA6);

  Color _backgroundForOption(String option) {
    if (!lockAnswers || selectedOption == null) {
      return option == selectedOption
          ? AppTheme.primaryBlue.withValues(alpha: 0.12)
          : const Color(0xFFF4F7FF);
    }

    if (correctAnswer != null && option == correctAnswer) {
      return AppTheme.primaryBlue.withValues(alpha: 0.14);
    }

    if (option == selectedOption) {
      return AppTheme.accentRed.withValues(alpha: 0.1);
    }

    return const Color(0xFFF4F7FF);
  }

  Color _borderForOption(String option) {
    if (!lockAnswers || selectedOption == null) {
      return option == selectedOption ? AppTheme.primaryBlue : _softBorder;
    }

    if (correctAnswer != null && option == correctAnswer) {
      return AppTheme.primaryBlue;
    }

    if (option == selectedOption) {
      return AppTheme.accentRed.withValues(alpha: 0.7);
    }

    return _softBorder;
  }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quiz Question',
            style: TextStyle(color: _secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: const TextStyle(
              color: _primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final imageHeight =
                  (constraints.maxWidth * 0.56).clamp(150.0, 280.0);

              return Container(
                width: double.infinity,
                height: imageHeight,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _softBorder),
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) {
                    return const Center(
                      child: Text(
                        'Question image unavailable',
                        style: TextStyle(color: _secondaryText),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          ...options.asMap().entries.map(
            (entry) {
              final idx = entry.key;
              final option = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: lockAnswers ? null : () => onOptionSelected(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _backgroundForOption(option),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _borderForOption(option),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color:
                                  AppTheme.primaryBlue.withValues(alpha: 0.25),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            String.fromCharCode(65 + idx),
                            style: const TextStyle(
                              color: _primaryText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            option,
                            style: const TextStyle(
                              color: _primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
