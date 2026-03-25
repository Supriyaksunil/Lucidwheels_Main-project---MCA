import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/custom_card.dart';
import '../../../widgets/common/section_header.dart';
import '../data/learning_data.dart';
import 'category_screen.dart';
import 'quiz_screen.dart';

class LearningHomeScreen extends StatelessWidget {
  const LearningHomeScreen({super.key});

  static const Color _pageBackground = Color(0xFFF6F8FF);
  static const Color _cardBackground = Colors.white;
  static const Color _softBorder = Color(0xFFD7E1FF);
  static const Color _primaryText = AppTheme.primaryBlue;
  static const Color _secondaryText = Color(0xFF4D5AA6);
  static const LinearGradient _pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5FF)],
  );
  static const LinearGradient _cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
  );

  @override
  Widget build(BuildContext context) {
    const categories = LearningData.categories;

    return AppScaffold(
      title: 'Learn Driving Rules',
      scaffoldBackgroundColor: _pageBackground,
      backgroundDecoration: const BoxDecoration(gradient: _pageGradient),
      appBarBackgroundColor: Colors.white,
      appBarForegroundColor: _primaryText,
      appBarTitleTextStyle: const TextStyle(
        color: _primaryText,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      body: Padding(
        padding: AppTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Micro Learning Hub',
              subtitle:
                  'Explore signs, rules, and penalties with a quick card-based flow.',
              leadingIcon: Icons.menu_book_rounded,
              titleColor: _primaryText,
              subtitleColor: _secondaryText,
              iconColor: _primaryText,
            ),
            const SizedBox(height: 14),
            CustomCard(
              color: _cardBackground,
              gradient: _cardGradient,
              border:
                  const Border.fromBorderSide(BorderSide(color: _softBorder)),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Know the signs. Own the road.',
                          style: TextStyle(
                            color: _primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Learn road signs, safe driving rules, and quick practice lessons.',
                          style: TextStyle(
                            color: _secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 720
                      ? 3
                      : constraints.maxWidth > 470
                          ? 2
                          : 1;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: crossAxisCount == 1 ? 2.05 : 1.06,
                    children: [
                      ...categories.map(
                        (category) => _CategoryTile(
                          category: category,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CategoryScreen(category: category),
                              ),
                            );
                          },
                        ),
                      ),
                      _CategoryTile(
                        category: LearningData.quizModeCategory,
                        emphasized: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QuizScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final LearningCategory category;
  final bool emphasized;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = category.accentColor;
    final tagLabel = emphasized ? 'Practice mode' : 'Explore';

    return CustomCard(
      onTap: onTap,
      color: Colors.white,
      gradient: emphasized
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF5F8FF), Color(0xFFEFF4FF)],
            )
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF9FBFF)],
            ),
      border: Border.all(color: accent.withValues(alpha: 0.28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_rounded, color: accent),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            category.title,
            style: const TextStyle(
              color: AppTheme.primaryBlue,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              category.subtitle,
              style: const TextStyle(
                color: Color(0xFF4D5AA6),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tagLabel,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
