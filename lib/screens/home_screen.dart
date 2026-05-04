import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/learning/screens/learning_home_screen.dart';
import '../models/emergency_alert_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/emergency_alert_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/custom_card.dart';
import '../widgets/emergency_alert_overlay.dart';
import 'dashboard_screen.dart';
import 'emergency_alerts_screen.dart';
import 'fleet_management_screen.dart';
import 'monitoring_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final emergencyAlertProvider = context.watch<EmergencyAlertProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = _getScreensForRole(user.role);
    final navItems = _getNavItemsForRole(user.role);
    final activeIndex = _currentIndex.clamp(0, screens.length - 1);

    final shell = Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.02, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          final scaleAnimation = Tween<double>(
            begin: 0.995,
            end: 1,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: offsetAnimation,
              child: ScaleTransition(scale: scaleAnimation, child: child),
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(activeIndex),
          child: screens[activeIndex],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: CustomCard(
          color: Colors.white,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF4F8FF)],
          ),
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: AppTheme.primaryBlue.withValues(alpha: 0.08),
              highlightColor: AppTheme.primaryBlue.withValues(alpha: 0.05),
            ),
            child: BottomNavigationBar(
              currentIndex: activeIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: navItems,
              backgroundColor: Colors.white,
              selectedItemColor: AppTheme.primaryBlue,
              unselectedItemColor: const Color(0xFF5B68A8),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w600),
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: true,
            ),
          ),
        ),
      ),
    );

    final activeAlert = emergencyAlertProvider.activeAlert;
    if (activeAlert == null) {
      return shell;
    }

    return Stack(
      children: [
        shell,
        Positioned.fill(
          child: EmergencyAlertOverlay(
            alert: activeAlert,
            onDismiss: emergencyAlertProvider.dismissActiveAlert,
            onOpenMaps: () => _openMapsForAlert(activeAlert),
          ),
        ),
      ],
    );
  }

  List<Widget> _getScreensForRole(UserRole role) {
    switch (role) {
      case UserRole.personal:
      case UserRole.commercial:
        return const [
          MonitoringScreen(),
          DashboardScreen(),
          LearningHomeScreen(),
          ProfileScreen(),
        ];
      case UserRole.fleetManager:
        return const [
          FleetManagementScreen(),
          ProfileScreen(),
        ];
      case UserRole.emergencyContact:
        return const [
          EmergencyAlertsScreen(),
          ProfileScreen(),
        ];
    }
  }

  List<BottomNavigationBarItem> _getNavItemsForRole(UserRole role) {
    if (role == UserRole.fleetManager) {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.groups_2), label: 'Fleet'),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ];
    }

    if (role == UserRole.emergencyContact) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_active_rounded),
          label: 'Alerts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ];
    }

    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.videocam_rounded),
        label: 'Monitor',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.space_dashboard_rounded),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.menu_book_rounded),
        label: 'Learning',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];
  }

  Future<void> _openMapsForAlert(EmergencyAlertRecord alert) async {
    final uri = Uri.tryParse(alert.mapUrl);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) {
      return;
    }
    context.read<EmergencyAlertProvider>().dismissActiveAlert();
  }
}
