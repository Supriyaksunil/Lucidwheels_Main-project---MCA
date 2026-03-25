import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common/custom_button.dart';

class AlertOverlay extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onAcknowledge;

  const AlertOverlay({
    super.key,
    required this.title,
    required this.message,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.accentRed.withValues(alpha: 0.55),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentRed.withValues(alpha: 0.25),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: AppTheme.accentRed,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.accentRed,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'I AM ALERT',
                  icon: Icons.check_circle_rounded,
                  backgroundColor: AppTheme.accentRed,
                  onPressed: onAcknowledge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
