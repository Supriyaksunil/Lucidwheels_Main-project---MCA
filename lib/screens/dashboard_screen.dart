import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/animated_reveal.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/custom_card.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_indicator.dart';
import '../widgets/driver_performance_sections.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    this.userOverride,
    this.title = 'Dashboard',
    this.welcomeTitle = 'Welcome Back',
    this.welcomeSubtitle = 'Safety intelligence at a glance',
    this.driverUniqueId,
  });

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

  final UserModel? userOverride;
  final String title;
  final String welcomeTitle;
  final String welcomeSubtitle;
  final String? driverUniqueId;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = userOverride ?? authProvider.currentUser;

    return AppScaffold(
      title: title,
      scaffoldBackgroundColor: _pageBackground,
      backgroundDecoration: const BoxDecoration(gradient: _pageGradient),
      appBarBackgroundColor: Colors.white,
      appBarForegroundColor: _primaryText,
      appBarTitleTextStyle: const TextStyle(
        color: _primaryText,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      body: SingleChildScrollView(
        padding: AppTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedReveal(
              delay: const Duration(milliseconds: 40),
              child: _buildWelcomeCard(user),
            ),
            const SizedBox(height: 18),
            AnimatedReveal(
              delay: const Duration(milliseconds: 120),
              child: DriverPerformanceSections(user: user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(UserModel? user) {
    final displayName = user == null
        ? 'Driver'
        : user.fullName.trim().isEmpty
            ? user.email
            : user.fullName;

    return CustomCard(
      padding: const EdgeInsets.all(18),
      color: _cardBackground,
      gradient: _cardGradient,
      border: const Border.fromBorderSide(BorderSide(color: _softBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: welcomeTitle,
            subtitle: welcomeSubtitle,
            leadingIcon: Icons.dashboard_customize_rounded,
            titleColor: _primaryText,
            subtitleColor: _secondaryText,
            iconColor: _primaryText,
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: const TextStyle(
              color: _primaryText,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusIndicator(
                label: user?.role.name.toUpperCase() ?? 'UNKNOWN',
                icon: Icons.verified_user_rounded,
                color: _primaryText,
                compact: true,
              ),
              const StatusIndicator(
                label: 'ACTIVE',
                icon: Icons.circle,
                color: _primaryText,
                compact: true,
              ),
              if (driverUniqueId != null && driverUniqueId!.trim().isNotEmpty)
                StatusIndicator(
                  label: 'ID: ${driverUniqueId!.trim()}',
                  icon: Icons.badge_rounded,
                  color: _primaryText,
                  compact: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
