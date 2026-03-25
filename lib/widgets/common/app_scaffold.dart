import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;
  final bool applySafeArea;
  final EdgeInsetsGeometry? padding;
  final Decoration? backgroundDecoration;
  final Color? scaffoldBackgroundColor;
  final Color? appBarBackgroundColor;
  final Color? appBarForegroundColor;
  final TextStyle? appBarTitleTextStyle;

  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottom,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
    this.applySafeArea = true,
    this.padding,
    this.backgroundDecoration,
    this.scaffoldBackgroundColor,
    this.appBarBackgroundColor,
    this.appBarForegroundColor,
    this.appBarTitleTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    if (applySafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor:
          scaffoldBackgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              actions: actions,
              bottom: bottom,
              backgroundColor: appBarBackgroundColor,
              foregroundColor: appBarForegroundColor,
              titleTextStyle: appBarTitleTextStyle,
            ),
      body: DecoratedBox(
        decoration: backgroundDecoration ?? AppTheme.backgroundDecoration,
        child: content,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
