import 'package:flutter/material.dart';

class RecorderControls extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onRecord;
  final VoidCallback onStop;

  const RecorderControls({
    super.key,
    required this.isRecording,
    required this.onRecord,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: isRecording ? onStop : onRecord,
      child: Icon(isRecording ? Icons.stop : Icons.mic),
    );
  }
}
