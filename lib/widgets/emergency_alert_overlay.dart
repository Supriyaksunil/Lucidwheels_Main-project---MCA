import 'package:flutter/material.dart';

import '../models/emergency_alert_model.dart';
import '../theme/app_theme.dart';
import 'common/custom_button.dart';

class EmergencyAlertOverlay extends StatelessWidget {
  const EmergencyAlertOverlay({
    super.key,
    required this.alert,
    required this.onDismiss,
    required this.onOpenMaps,
  });

  final EmergencyAlertRecord alert;
  final VoidCallback onDismiss;
  final VoidCallback onOpenMaps;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.74),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.accentRed.withValues(alpha: 0.65),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentRed.withValues(alpha: 0.24),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.emergency_rounded,
                size: 60,
                color: AppTheme.accentRed,
              ),
              const SizedBox(height: 12),
              Text(
                alert.driverName,
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                alert.message,
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (alert.reason.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  alert.reason,
                  style: const TextStyle(color: Color(0xFF4D5AA6)),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'Open in Maps',
                  icon: Icons.map_rounded,
                  backgroundColor: AppTheme.accentRed,
                  onPressed: onOpenMaps,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Dismiss'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
