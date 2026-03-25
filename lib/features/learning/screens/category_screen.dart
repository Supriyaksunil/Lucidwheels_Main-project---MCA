import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/custom_card.dart';
import '../../../widgets/common/section_header.dart';
import '../data/learning_data.dart';
import 'learning_screen.dart';

class CategoryScreen extends StatelessWidget {
  final LearningCategory category;

  const CategoryScreen({super.key, required this.category});

  static const Color _pageBackground = Color(0xFFF6F8FF);
  static const Color _primaryText = AppTheme.primaryBlue;
  static const Color _secondaryText = Color(0xFF4D5AA6);
  static const LinearGradient _pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5FF)],
  );

  @override
  Widget build(BuildContext context) {
    final rules = LearningData.rulesForCategory(category.id);

    return AppScaffold(
      title: category.title,
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
            SectionHeader(
              title: '${category.emoji} ${category.title}',
              subtitle: category.subtitle,
              leadingIcon: Icons.list_alt_rounded,
              titleColor: _primaryText,
              subtitleColor: _secondaryText,
              iconColor: _primaryText,
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap any sign or rule card to open the full lesson.',
              style: TextStyle(color: _secondaryText, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: rules.isEmpty
                  ? const Center(
                      child: Text(
                        'No content available right now.',
                        style: TextStyle(color: _secondaryText),
                      ),
                    )
                  : ListView.separated(
                      itemCount: rules.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final rule = rules[index];
                        return _RuleListItem(
                          title: rule.title,
                          icon: rule.icon,
                          description: rule.description,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LearningScreen(
                                  categoryTitle: category.title,
                                  rules: rules,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
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

class _RuleListItem extends StatelessWidget {
  final String title;
  final String icon;
  final String description;
  final VoidCallback onTap;

  const _RuleListItem({
    required this.title,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      color: Colors.white,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
      ),
      border: const Border.fromBorderSide(BorderSide(color: Color(0xFFD7E1FF))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF4D5AA6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Open lesson',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF4D5AA6),
          ),
        ],
      ),
    );
  }
}
