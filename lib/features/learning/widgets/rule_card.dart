import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/custom_card.dart';
import '../models/rule_model.dart';

class RuleCard extends StatelessWidget {
  final RuleModel rule;

  const RuleCard({super.key, required this.rule});

  static const Color _softBorder = Color(0xFFD7E1FF);
  static const Color _primaryText = AppTheme.primaryBlue;
  static const Color _secondaryText = Color(0xFF4D5AA6);

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      color: Colors.white,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
      ),
      border: const Border.fromBorderSide(BorderSide(color: _softBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(rule.icon, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  rule.title,
                  style: const TextStyle(
                    color: _primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Description',
            style: TextStyle(
              color: _primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            rule.description,
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          _SignImage(
            imagePath: rule.image,
            onTap: () => _openImagePreview(context, rule),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.accentRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentRed.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              'Penalty: ${rule.penalty}',
              style: const TextStyle(
                color: AppTheme.accentRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openImagePreview(BuildContext context, RuleModel rule) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rule.title,
                      style: const TextStyle(
                        color: _primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close_rounded, color: _primaryText),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 3,
                  child: Image.asset(
                    rule.image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: const Color(0xFFEFF4FF),
                        padding: const EdgeInsets.all(24),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image_not_supported_rounded,
                              color: _secondaryText,
                              size: 40,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Sign image unavailable',
                              style: TextStyle(color: _secondaryText),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignImage extends StatelessWidget {
  final String imagePath;
  final VoidCallback onTap;

  const _SignImage({required this.imagePath, required this.onTap});

  static const Color _softBorder = Color(0xFFD7E1FF);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final imageHeight =
                (constraints.maxWidth * 0.62).clamp(180.0, 320.0);

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Container(
                width: double.infinity,
                height: imageHeight,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _softBorder),
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) {
                    return const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported_rounded,
                          color: Color(0xFF4D5AA6),
                          size: 34,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sign image unavailable',
                          style: TextStyle(color: Color(0xFF4D5AA6)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        const Text(
          'Tap sign image to zoom',
          style: TextStyle(color: Color(0xFF4D5AA6), fontSize: 12),
        ),
      ],
    );
  }
}
