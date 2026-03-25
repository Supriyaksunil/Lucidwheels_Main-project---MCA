import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_card.dart';

class ResultScreen extends StatelessWidget {
  final String title;
  final int score;
  final int total;
  final WidgetBuilder? restartBuilder;

  const ResultScreen({
    super.key,
    required this.title,
    required this.score,
    required this.total,
    this.restartBuilder,
  });

  static const Color _pageBackground = Color(0xFFF6F8FF);
  static const Color _softBorder = Color(0xFFD7E1FF);
  static const Color _primaryText = AppTheme.primaryBlue;
  static const Color _secondaryText = Color(0xFF4D5AA6);
  static const LinearGradient _pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5FF)],
  );

  String get _level {
    if (total == 0) {
      return 'Beginner';
    }
    return (score / total) >= 0.6 ? 'Intermediate' : 'Beginner';
  }

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final ratio = (score / safeTotal).clamp(0, 1);

    return AppScaffold(
      title: 'Session Result',
      scaffoldBackgroundColor: _pageBackground,
      backgroundDecoration: const BoxDecoration(gradient: _pageGradient),
      appBarBackgroundColor: Colors.white,
      appBarForegroundColor: _primaryText,
      appBarTitleTextStyle: const TextStyle(
        color: _primaryText,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: CustomCard(
              color: Colors.white,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
              ),
              border: const Border.fromBorderSide(
                BorderSide(color: _softBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: _primaryText,
                    size: 52,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: _primaryText,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: ratio.toDouble()),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOut,
                    builder: (context, value, _) {
                      return SizedBox(
                        width: 130,
                        height: 130,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: value,
                              strokeWidth: 10,
                              backgroundColor:
                                  _primaryText.withValues(alpha: 0.12),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryBlue,
                              ),
                            ),
                            Text(
                              '${(value * 100).round()}%',
                              style: const TextStyle(
                                color: _primaryText,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Score: $score / $total',
                    style: const TextStyle(
                      color: _primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Level: $_level',
                    style: const TextStyle(
                      color: _secondaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    label: 'Back',
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (restartBuilder != null) ...[
                    const SizedBox(height: 10),
                    CustomButton(
                      label: 'Try Again',
                      icon: Icons.replay_rounded,
                      outlined: true,
                      foregroundColor: _primaryText,
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: restartBuilder!),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
