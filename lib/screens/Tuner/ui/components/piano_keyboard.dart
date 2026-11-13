import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_piano_keyboard.dart';
import 'package:sornaz/screens/Tuner/controller/tuner_provider.dart';

/// Domain adapter; presentation and gestures belong to AppPianoKeyboard.
class PianoKeyboard extends StatelessWidget {
  const PianoKeyboard({super.key, this.a4 = 440});
  final double a4;
  @override
  Widget build(BuildContext context) {
    final tuner = context.watch<TunerProvider>(),
        settings = tuner.keyboardSettings;
    return AppPianoKeyboard(
      firstMidi: (settings.startOctave + 1) * 12,
      lastMidi: (settings.startOctave + settings.octaveCount + 1) * 12 - 1,
      showQuarterTones: settings.showQuarterTones,
      a4: a4,
      highlightA4: settings.highlightA4,
      showWhiteFrequencies: settings.showWhiteKeyFrequencies,
      showBlackFrequencies: settings.showBlackKeyFrequencies,
      onPointer: (key, phase, _) {
        if (phase == PianoPointerPhase.down) tuner.playNote(key.frequency(a4));
      },
    );
  }
}
