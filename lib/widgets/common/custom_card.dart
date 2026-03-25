import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class CustomCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Border? border;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final bool animateOnBuild;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.color,
    this.border,
    this.borderRadius,
    this.gradient,
    this.animateOnBuild = true,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  double _scale = 1;
  late bool _isVisible;

  @override
  void initState() {
    super.initState();
    _isVisible = !widget.animateOnBuild;
    if (widget.animateOnBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isVisible = true;
        });
      });
    }
  }

  void _press(bool down) {
    if (widget.onTap == null) {
      return;
    }
    setState(() {
      _scale = down ? 0.985 : 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius =
        widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusMedium);

    Widget content = Padding(
      padding: widget.padding,
      child: widget.child,
    );

    if (widget.onTap != null) {
      content = InkWell(
        borderRadius: radius,
        onTap: widget.onTap,
        onTapDown: (_) => _press(true),
        onTapCancel: () => _press(false),
        onTapUp: (_) => _press(false),
        child: content,
      );
    }

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _isVisible ? 1 : 0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: _isVisible ? Offset.zero : const Offset(0, 0.015),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          child: Container(
            margin: widget.margin,
            decoration: BoxDecoration(
              color: widget.color ?? AppTheme.surface,
              gradient: widget.gradient,
              borderRadius: radius,
              border: widget.border ??
                  const Border.fromBorderSide(
                    BorderSide(color: AppTheme.border),
                  ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: radius,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
