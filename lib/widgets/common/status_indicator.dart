import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class StatusIndicator extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final bool compact;

  const StatusIndicator({
    super.key,
    required this.label,
    required this.icon,
    this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? AppTheme.secondaryWhite;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: indicatorColor.withValues(alpha: 0.55)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 180 : 220),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: indicatorColor, size: compact ? 14 : 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: indicatorColor,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 11 : 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
