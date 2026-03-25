import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/custom_card.dart';

class AboutLucidWheelsScreen extends StatelessWidget {
  const AboutLucidWheelsScreen({super.key});

  static const Color _pageBackground = Color(0xFFF6F8FF);
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
    return const AppScaffold(
      title: 'About LucidWheels',
      scaffoldBackgroundColor: _pageBackground,
      backgroundDecoration: BoxDecoration(gradient: _pageGradient),
      appBarBackgroundColor: Colors.white,
      appBarForegroundColor: AppTheme.primaryBlue,
      appBarTitleTextStyle: TextStyle(
        color: AppTheme.primaryBlue,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      body: SingleChildScrollView(
        padding: AppTheme.pagePadding,
        child: Column(
          children: [
            CustomCard(
              color: Colors.white,
              gradient: _cardGradient,
              border: Border.fromBorderSide(
                BorderSide(color: Color(0xFFD7E1FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car_filled_rounded,
                        color: AppTheme.primaryBlue,
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'LucidWheels',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'LucidWheels helps drivers stay safer with real-time monitoring, accident detection, and learning tools designed for everyday and commercial driving.',
                    style: TextStyle(
                      color: Color(0xFF4D5AA6),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 16),
                  _FeatureLine(
                    icon: Icons.visibility_rounded,
                    text: 'Driver fatigue and distraction monitoring',
                  ),
                  SizedBox(height: 10),
                  _FeatureLine(
                    icon: Icons.warning_amber_rounded,
                    text: 'Automatic accident and incident alert support',
                  ),
                  SizedBox(height: 10),
                  _FeatureLine(
                    icon: Icons.menu_book_rounded,
                    text: 'Interactive road-sign learning and quiz module',
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF4D5AA6),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
