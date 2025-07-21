import 'package:flutter/material.dart';

class NotFoundDialog extends StatelessWidget {
  const NotFoundDialog({super.key, required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(title: Text(title), content: Text(message));
  }
}
