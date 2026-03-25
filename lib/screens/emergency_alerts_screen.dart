import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/emergency_alert_model.dart';
import '../providers/emergency_alert_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/animated_reveal.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/custom_card.dart';
import '../widgets/common/section_header.dart';

class EmergencyAlertsScreen extends StatelessWidget {
  const EmergencyAlertsScreen({super.key});

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
    final provider = context.watch<EmergencyAlertProvider>();

    return AppScaffold(
      title: 'Emergency Alerts',
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
            const AnimatedReveal(
              delay: Duration(milliseconds: 40),
              child: CustomCard(
                color: _cardBackground,
                gradient: _cardGradient,
                border: Border.fromBorderSide(BorderSide(color: _softBorder)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Emergency Contact Inbox',
                      subtitle:
                          'Live emergency alerts with driver location links',
                      leadingIcon: Icons.notification_important_rounded,
                      titleColor: _primaryText,
                      subtitleColor: _secondaryText,
                      iconColor: AppTheme.accentRed,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.error != null)
              _ErrorCard(message: provider.error!)
            else if (provider.recentAlerts.isEmpty)
              const _EmptyAlertsCard()
            else
              ...provider.recentAlerts.asMap().entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: entry.key == provider.recentAlerts.length - 1
                          ? 0
                          : 12),
                  child: _EmergencyAlertCard(alert: entry.value),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _EmergencyAlertCard extends StatelessWidget {
  const _EmergencyAlertCard({required this.alert});

  final EmergencyAlertRecord alert;

  @override
  Widget build(BuildContext context) {
    return AnimatedReveal(
      delay: const Duration(milliseconds: 100),
      child: CustomCard(
        color: EmergencyAlertsScreen._cardBackground,
        gradient: EmergencyAlertsScreen._cardGradient,
        border: const Border.fromBorderSide(
          BorderSide(color: EmergencyAlertsScreen._softBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.emergency_rounded,
                  color: AppTheme.accentRed,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    alert.driverName,
                    style: const TextStyle(
                      color: EmergencyAlertsScreen._primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  DateFormat('dd MMM, hh:mm a')
                      .format(alert.triggeredAt.toLocal()),
                  style: const TextStyle(
                    color: EmergencyAlertsScreen._secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              alert.message,
              style: const TextStyle(
                color: EmergencyAlertsScreen._primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (alert.reason.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                alert.reason,
                style: const TextStyle(
                    color: EmergencyAlertsScreen._secondaryText),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openMaps(context, alert),
                icon: const Icon(Icons.map_rounded),
                label: const Text('Open in Maps'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentRed,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMaps(
      BuildContext context, EmergencyAlertRecord alert) async {
    final uri = Uri.tryParse(alert.mapUrl);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _EmptyAlertsCard extends StatelessWidget {
  const _EmptyAlertsCard();

  @override
  Widget build(BuildContext context) {
    return const CustomCard(
      color: EmergencyAlertsScreen._cardBackground,
      gradient: EmergencyAlertsScreen._cardGradient,
      border: Border.fromBorderSide(
        BorderSide(color: EmergencyAlertsScreen._softBorder),
      ),
      child: Text(
        'No emergency alerts received yet.',
        style: TextStyle(color: EmergencyAlertsScreen._secondaryText),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      color: Colors.white,
      gradient: EmergencyAlertsScreen._cardGradient,
      border: const Border.fromBorderSide(
        BorderSide(color: EmergencyAlertsScreen._softBorder),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppTheme.accentRed),
      ),
    );
  }
}
