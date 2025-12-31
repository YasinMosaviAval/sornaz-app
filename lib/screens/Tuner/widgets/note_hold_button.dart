import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Tuner/controller/tuner_provider.dart';

class NoteHoldButton extends StatelessWidget {
  final String label;
  final int midiNote;

  const NoteHoldButton({
    super.key,
    required this.label,
    required this.midiNote,
  });

  @override
  Widget build(BuildContext context) {
    final tuner = context.read<TunerProvider>();

    return GestureDetector(
      onLongPressStart: (_) {
        final freq = tuner.a4 * pow(2, (midiNote - 69) / 12);
        tuner.playNote(freq);
      },
      onLongPressEnd: (_) {
        tuner.stopNote();
      },
      
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.blueGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
