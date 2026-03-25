import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_card.dart';
import '../models/rule_model.dart';
import '../widgets/rule_card.dart';

class LearningScreen extends StatefulWidget {
  final String categoryTitle;
  final List<RuleModel> rules;
  final int initialIndex;

  const LearningScreen({
    super.key,
    required this.categoryTitle,
    required this.rules,
    this.initialIndex = 0,
  });

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  static const Color _pageBackground = Color(0xFFF6F8FF);
  static const Color _softBorder = Color(0xFFD7E1FF);
  static const Color _primaryText = AppTheme.primaryBlue;
  static const Color _secondaryText = Color(0xFF4D5AA6);
  static const LinearGradient _pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5FF)],
  );

  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    if (widget.rules.isEmpty) {
      _currentPage = 0;
      _pageController = PageController();
      return;
    }

    final safeIndex =
        widget.initialIndex.clamp(0, widget.rules.length - 1).toInt();
    _currentPage = safeIndex;
    _pageController = PageController(initialPage: safeIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int index) async {
    if (index < 0 || index >= widget.rules.length) {
      return;
    }

    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.rules.length;

    if (total == 0) {
      return AppScaffold(
        title: widget.categoryTitle,
        scaffoldBackgroundColor: _pageBackground,
        backgroundDecoration: const BoxDecoration(gradient: _pageGradient),
        appBarBackgroundColor: Colors.white,
        appBarForegroundColor: _primaryText,
        appBarTitleTextStyle: const TextStyle(
          color: _primaryText,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        body: const Center(
          child: Text(
            'No learning content is available in this category.',
            style: TextStyle(color: _secondaryText),
          ),
        ),
      );
    }

    final currentRule = widget.rules[_currentPage];

    return AppScaffold(
      title: widget.categoryTitle,
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
          children: [
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentRule.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Swipe left or right to move through the lessons.',
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: total <= 1 ? 1 : (_currentPage + 1) / total,
                      minHeight: 8,
                      backgroundColor: _primaryText.withValues(alpha: 0.12),
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: total,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final rule = widget.rules[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RuleCard(rule: rule),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Previous',
                    icon: Icons.arrow_back_rounded,
                    outlined: true,
                    foregroundColor: _primaryText,
                    onPressed: _currentPage > 0
                        ? () => _goToPage(_currentPage - 1)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    label: _currentPage == total - 1 ? 'Done' : 'Next',
                    icon: _currentPage == total - 1
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    onPressed: _currentPage == total - 1
                        ? () => Navigator.pop(context)
                        : () => _goToPage(_currentPage + 1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
