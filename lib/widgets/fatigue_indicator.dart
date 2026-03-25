import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FatigueIndicator extends StatelessWidget {
  final double score;

  const FatigueIndicator({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final safeScore = score.clamp(0, 1);
    late final Color indicatorColor;
    late final String label;

    if (safeScore < 0.3) {
      indicatorColor = Colors.white;
      label = 'Low';
    } else if (safeScore < 0.6) {
      indicatorColor = const Color(0xFFFFD9D9);
      label = 'Moderate';
    } else {
      indicatorColor = AppTheme.accentRed;
      label = 'High';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: indicatorColor.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Fatigue Level',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 62,
            height: 62,
            child: CircularProgressIndicator(
              value: safeScore.toDouble(),
              strokeWidth: 7,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(safeScore * 100).toInt()}%',
            style: TextStyle(
              color: indicatorColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: indicatorColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
