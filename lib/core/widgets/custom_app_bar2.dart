import 'package:flutter/material.dart';

class CustomAppBar2 extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar2({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 50); // Increased height to accommodate safe area
}
