import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/custom_card.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
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

  bool _locationAccess = true;
  bool _cameraAccess = true;
  bool _shareIncidentReports = true;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Privacy & Security',
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
                  _buildSwitch(
                    title: 'Location Access',
                    subtitle: 'Required for trip and incident positioning',
                    value: _locationAccess,
                    onChanged: (value) =>
                        setState(() => _locationAccess = value),
                  ),
                  Divider(color: AppTheme.primaryBlue.withValues(alpha: 0.14)),
                  _buildSwitch(
                    title: 'Camera Access',
                    subtitle: 'Needed for driver monitoring and alerts',
                    value: _cameraAccess,
                    onChanged: (value) => setState(() => _cameraAccess = value),
                  ),
                  Divider(color: AppTheme.primaryBlue.withValues(alpha: 0.14)),
                  _buildSwitch(
                    title: 'Share Incident Reports',
                    subtitle: 'Share incident metadata with emergency contacts',
                    value: _shareIncidentReports,
                    onChanged: (value) =>
                        setState(() => _shareIncidentReports = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const CustomCard(
              color: Colors.white,
              gradient: _cardGradient,
              border: Border.fromBorderSide(
                BorderSide(color: Color(0xFFD7E1FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Note',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your profile and driving data are tied to your account. Keep your login credentials secure and avoid sharing one-time codes.',
                    style: TextStyle(
                      color: Color(0xFF4D5AA6),
                      height: 1.5,
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

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeThumbColor: AppTheme.primaryBlue,
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
    );
  }
}
