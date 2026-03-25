import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? leadingIcon;
  final Color? titleColor;
  final Color? subtitleColor;
  final Color? iconColor;
  final Color? actionColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.leadingIcon,
    this.titleColor,
    this.subtitleColor,
    this.iconColor,
    this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedTitleColor = titleColor;
    final resolvedSubtitleColor = subtitleColor;
    final resolvedIconColor =
        iconColor ?? resolvedTitleColor ?? Theme.of(context).iconTheme.color;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: resolvedTitleColor,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: resolvedSubtitleColor,
                ),
          ),
        ],
      ],
    );

    final actionButton = actionLabel == null
        ? null
        : TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: actionColor ?? resolvedTitleColor,
            ),
            child: Text(
              actionLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useVerticalLayout =
            actionButton != null && constraints.maxWidth < 360;

        if (useVerticalLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, color: resolvedIconColor, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Expanded(child: titleBlock),
                ],
              ),
              const SizedBox(height: 8),
              actionButton,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, color: resolvedIconColor, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(child: titleBlock),
            if (actionButton != null) actionButton,
          ],
        );
      },
    );
  }
}
