import 'package:flutter/material.dart';

import '../widgets/safety_alert_screen.dart';

class SafetyConfirmationService {
  const SafetyConfirmationService();

  Future<bool> showSafetyConfirmation(
    BuildContext context, {
    int countdownSeconds = 30,
    bool enableAudio = false,
  }) async {
    final isSafe = await showGeneralDialog<bool>(
      context: context,
      barrierLabel: 'Safety Confirmation',
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.86),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafetyAlertScreen(
          countdownSeconds: countdownSeconds,
          enableAudio: enableAudio,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

    return isSafe ?? false;
  }
}
