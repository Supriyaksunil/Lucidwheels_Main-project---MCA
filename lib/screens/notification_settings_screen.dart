import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/custom_card.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
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

  bool _tripReminders = true;
  bool _monitoringWarnings = true;
  bool _accidentAlerts = true;
  bool _weeklySummary = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Notification Settings',
      scaffoldBackgroundColor: _pageBackground,
      backgroundDecoration: const BoxDecoration(gradient: _pageGradient),
      appBarBackgroundColor: Colors.white,
      appBarForegroundColor: AppTheme.primaryBlue,
      appBarTitleTextStyle: const TextStyle(
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
              border: const Border.fromBorderSide(
                BorderSide(color: Color(0xFFD7E1FF)),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Trip Reminders',
                    subtitle: 'Get reminders before scheduled drives',
                    value: _tripReminders,
                    onChanged: (value) =>
                        setState(() => _tripReminders = value),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    title: 'Driver Monitoring Warnings',
                    subtitle: 'Instant fatigue and distraction updates',
                    value: _monitoringWarnings,
                    onChanged: (value) =>
                        setState(() => _monitoringWarnings = value),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    title: 'Accident Alerts',
                    subtitle: 'Notify emergency workflow for incidents',
                    value: _accidentAlerts,
                    onChanged: (value) =>
                        setState(() => _accidentAlerts = value),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    title: 'Weekly Summary',
                    subtitle: 'Receive weekly performance recap',
                    value: _weeklySummary,
                    onChanged: (value) =>
                        setState(() => _weeklySummary = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Save Preferences',
              icon: Icons.save_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification settings saved'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF4D5AA6)),
      ),
      secondary: Icon(
        value ? Icons.notifications_active_rounded : Icons.notifications_none,
        color: AppTheme.primaryBlue,
      ),
      value: value,
      activeThumbColor: AppTheme.primaryBlue,
      onChanged: onChanged,
    );
  }

  Widget _buildDivider() {
    return Divider(color: AppTheme.primaryBlue.withValues(alpha: 0.14));
  }
}
