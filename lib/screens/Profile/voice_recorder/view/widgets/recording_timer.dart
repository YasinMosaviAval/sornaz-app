import 'package:flutter/material.dart';

class RecordingTimer extends StatelessWidget {
  final String text;

  const RecordingTimer({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
