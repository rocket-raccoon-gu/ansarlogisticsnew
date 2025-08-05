import 'package:flutter/material.dart';

class SafeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final TextStyle? titleTextStyle;

  const SafeAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.titleTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AppBar(
        title: Text(title, style: titleTextStyle),
        actions: actions,
        leading: leading,
        centerTitle: centerTitle,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: elevation,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10); // Increased height to accommodate safe area
}
