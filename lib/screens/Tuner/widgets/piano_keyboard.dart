/*
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Tuner/controller/tuner_provider.dart';
import 'package:sornaz/screens/Tuner/models/piano_key.dart';
import 'package:sornaz/screens/Tuner/models/tuner_keyboard_settings.dart';
import 'package:sornaz/screens/Tuner/utils/tuner_math.dart';

class PianoKeyboard extends StatefulWidget {
  final double a4;

  const PianoKeyboard({
    super.key,
    this.a4 = 440.0,
  });

  @override
  PianoKeyboardState createState() => PianoKeyboardState();
}

class PianoKeyboardState extends State<PianoKeyboard> {
  final Set<int> activeKeys = {};

  static const List<String> _noteNames = [
    "C", "C#", "D", "D#", "E", "F",
    "F#", "G", "G#", "A", "A#", "B"
  ];

  // ---------- UI constants ----------
  final double whiteKeyWidth = 60;
  final double whiteKeyHeight = 160;
  final double blackKeyWidth = 40;
  final double blackKeyHeight = 100;

  bool _isBlack(String note) => note.contains("#");

  @override
  Widget build(BuildContext context) {
    final tuner = context.watch<TunerProvider>();
    final settings = tuner.keyboardSettings;

    final keys = _buildKeys(settings);
    final whiteKeys = keys.where((k) => !k.isBlack).toList();
    final blackKeys = keys.where((k) => k.isBlack).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: settings.octaveCount * 7 * whiteKeyWidth,
        height: whiteKeyHeight,
        child: Stack(
          children: [
            _buildWhiteKeys(context, whiteKeys, settings, tuner),
            ..._buildBlackKeys(context, blackKeys, settings, tuner),
          ],
        ),
      ),
    );
  }

  // ---------- Key builders ----------
  List<PianoKey> _buildKeys(TunerKeyboardSettings settings) {
    final List<PianoKey> keys = [];

    for (int octaveLengthIndex = 0; octaveLengthIndex < settings.octaveCount; octaveLengthIndex++) {
      final octave = settings.startOctave + octaveLengthIndex;

      for (int i = 0; i < _noteNames.length; i++) {
        final midi = (octave + 1) * 12 + i;

        keys.add(
          PianoKey(
            name: _noteNames[i],
            octave: octave,
            midi: midi,
            isBlack: _isBlack(_noteNames[i]),
          ),
        );
      }
    }
    return keys;
  }

  Widget _buildWhiteKeys(
    BuildContext context,
    List<PianoKey> keys,
    TunerKeyboardSettings settings, TunerProvider tuner,
  ) {
    return Row(
      children: keys.map((key) {
        final isActive = activeKeys.contains(key.midi);
        final isA4 = settings.highlightA4 && key.midi == 69;

        return GestureDetector(
          onTapDown: (_) => _onKeyDown(context, key),
          onTapUp: (_) => _onKeyUp(context, key),
          onTapCancel: () => _onKeyUp(context, key),
          child: Container(
            width: whiteKeyWidth,
            height: whiteKeyHeight,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              color: isA4
                  ? Colors.lightBlueAccent
                  : isActive
                      ? Colors.yellow
                      : Colors.white,
              border: Border.all(width: 0.5, color: Colors.black),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(key.label, style: const TextStyle(fontSize: 12)),
                if (tuner.keyboardSettings.showWhiteKeyFrequencies)
                  Text(
                    "${TunerMath.removeUnusedZERO(_frequencyFromMidi(key.midi))} Hz",
                    style: const TextStyle(fontSize: 9),
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildBlackKeys(
    BuildContext context,
    List<PianoKey> keys,
    TunerKeyboardSettings settings, TunerProvider tuner,
  ) {
    return keys.map((key) {
      final isActive = activeKeys.contains(key.midi);
      final isA4 = settings.highlightA4 && key.midi == 69;

      return Positioned(
        left: _blackKeyOffset(key, settings),
        child: GestureDetector(
          onTapDown: (_) => _onKeyDown(context, key),
          onTapUp: (_) => _onKeyUp(context, key),
          onTapCancel: () => _onKeyUp(context, key),
          child: Container(
            width: blackKeyWidth,
            height: blackKeyHeight,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              color: isA4
                  ? Colors.blue
                  : isActive
                      ? Colors.orange
                      : Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  key.label,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                if (tuner.keyboardSettings.showBlackKeyFrequencies)
                  Text(
                    "${TunerMath.removeUnusedZERO(_frequencyFromMidi(key.midi))} Hz",
                    style: const TextStyle(fontSize: 8, color: Colors.white),
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  List<PianoKey> _buildMicroToneKeys(TunerKeyboardSettings settings) {
    final List<PianoKey> keys = [];

    for (int o = 0; o < settings.octaveCount; o++) {
      final octave = settings.startOctave + o;

      for (int i = 0; i < _noteNames.length; i++) {
        final baseMidi = (octave + 1) * 12 + i;
        final name = _noteNames[i];
        final isBlack = _isBlack(name);

        // نت اصلی
        keys.add(
          PianoKey(
            name: name,
            octave: octave,
            midi: baseMidi,
            isBlack: isBlack,
          ),
        );

        // کرن (¼-)
        keys.add(
          PianoKey(
            name: name,
            octave: octave,
            midi: baseMidi,
            isBlack: true,
            microTone: MicroToneType.koron,
          ),
        );

        // سری (¼+)
        keys.add(
          PianoKey(
            name: name,
            octave: octave,
            midi: baseMidi,
            isBlack: true,
            microTone: MicroToneType.sori,
          ),
        );
      }
    }
    return keys;
  }

  // ---------- Interaction ----------
  void _onKeyDown(BuildContext context, PianoKey key) {
    setState(() => activeKeys.add(key.midi));
    context.read<TunerProvider>().playNote(_frequencyFromMidi(key.midi));
  }

  void _onKeyUp(BuildContext context, PianoKey key) {
    setState(() => activeKeys.remove(key.midi));
    if (activeKeys.isEmpty) {
      context.read<TunerProvider>().stopNote();
    }
  }

  // ---------- Math ----------
  double _frequencyFromMidi(int midi) {
    return widget.a4 * pow(2, (midi - 69) / 12);
  }

  double _blackKeyOffset(
    PianoKey key, 
    TunerKeyboardSettings settings
  ) {
    const pattern = {
      1: 1.0,
      3: 2.0,
      6: 4.0,
      8: 5.0,
      10: 6.0,
    };

    final index = key.midi % 12;
    final base = pattern[index]! * whiteKeyWidth;
    final octaveOffset = (key.octave - settings.startOctave) * 7 * whiteKeyWidth;

    return base + octaveOffset - blackKeyWidth / 2;
  }
}
*/


import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Tuner/controller/tuner_provider.dart';
import 'package:sornaz/screens/Tuner/models/piano_key.dart';
import 'package:sornaz/screens/Tuner/models/tuner_keyboard_settings.dart';
import 'package:sornaz/screens/Tuner/utils/tuner_math.dart';


class PianoKeyboard extends StatefulWidget {
  final double a4;

  const PianoKeyboard({
    super.key,
    this.a4 = 440.0,
  });

  @override
  PianoKeyboardState createState() => PianoKeyboardState();
}


class PianoKeyboardState extends State<PianoKeyboard> {
  final Set<int> activeKeys = {};

  static const List<String> _noteNames = [
    "C", "C#", "D", "D#", "E", "F",
    "F#", "G", "G#", "A", "A#", "B"
  ];

  // ---------- UI constants ----------
  final double whiteKeyWidth = 60;
  final double whiteKeyHeight = 160;
  final double blackKeyWidth = 40;
  final double blackKeyHeight = 90;

  bool _isBlack(String note) => note.contains("#");

  @override
  Widget build(BuildContext context) {
    final tuner = context.watch<TunerProvider>();
    final settings = tuner.keyboardSettings;

    final keys = _buildKeys(settings);
    final whiteKeys = keys.where((k) => !k.isBlack && k.microTone == MicroToneType.normal).toList();
    final blackKeys = keys.where((k) => k.isBlack).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: settings.octaveCount * 7 * whiteKeyWidth,
        height: whiteKeyHeight,
        child: Stack(
          children: [
            _buildWhiteKeys(context, whiteKeys, settings, tuner),
            ..._buildBlackKeys(context, blackKeys, settings, tuner),
          ],
        ),
      ),
    );
  }

  // ---------- Build Keys ----------
  List<PianoKey> _buildKeys(TunerKeyboardSettings settings) {
    final List<PianoKey> keys = [];

    for (int o = 0; o < settings.octaveCount; o++) {
      final octave = settings.startOctave + o;

      for (int i = 0; i < _noteNames.length; i++) {
        final name = _noteNames[i];
        final midi = (octave + 1) * 12 + i;

        // نت اصلی
        keys.add(
          PianoKey(
            name: name,
            octave: octave,
            midi: midi,
            isBlack: _isBlack(name),
          ),
        );

        // ربع پرده پایین (کرن)
        keys.add(
          PianoKey(
            name: name,
            octave: octave,
            midi: midi,
            isBlack: true,
            microTone: MicroToneType.koron,
          ),
        );

        // ربع پرده بالا (سری)
        keys.add(
          PianoKey(
            name: name,
            octave: octave,
            midi: midi,
            isBlack: true,
            microTone: MicroToneType.sori,
          ),
        );
      }
    }
    return keys;
  }

  // ---------- White Keys ----------
  Widget _buildWhiteKeys(
    BuildContext context,
    List<PianoKey> keys,
    TunerKeyboardSettings settings,
    TunerProvider tuner,
  ) {
    return Row(
      children: keys.map((key) {
        final isActive = activeKeys.contains(key.midi);
        final isA4 = settings.highlightA4 && key.midi == 69;

        return GestureDetector(
          onTapDown: (_) => _onKeyDown(context, key),
          onTapUp: (_) => _onKeyUp(context, key),
          onTapCancel: () => _onKeyUp(context, key),
          child: Container(
            width: whiteKeyWidth,
            height: whiteKeyHeight,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              color: isA4
                  ? Colors.lightBlueAccent
                  : isActive
                      ? Colors.yellow
                      : Colors.white,
              border: Border.all(width: 0.5, color: Colors.black),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(key.label, style: const TextStyle(fontSize: 12)),
                if (settings.showWhiteKeyFrequencies)
                  Text(
                    "${TunerMath.removeUnusedZERO(_frequencyFromKey(key))} Hz",
                    style: const TextStyle(fontSize: 9),
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------- Black & Microtone Keys ----------
  List<Widget> _buildBlackKeys(
    BuildContext context,
    List<PianoKey> keys,
    TunerKeyboardSettings settings,
    TunerProvider tuner,
  ) {
    return keys.map((key) {
      final isActive = activeKeys.contains(key.midi);
      final isA4 = settings.highlightA4 && key.midi == 69;

      return Positioned(
        top: _microToneTop(key),
        left: _blackKeyOffset(key, settings),
        child: GestureDetector(
          onTapDown: (_) => _onKeyDown(context, key),
          onTapUp: (_) => _onKeyUp(context, key),
          onTapCancel: () => _onKeyUp(context, key),
          child: Container(
            width: blackKeyWidth,
            height: blackKeyHeight,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              color: isA4
                  ? Colors.blue
                  : isActive
                      ? Colors.orange
                      : _microToneColor(key),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  key.label,
                  style: const TextStyle(fontSize: 9, color: Colors.white),
                ),
                if (settings.showBlackKeyFrequencies)
                  Text(
                    "${TunerMath.removeUnusedZERO(_frequencyFromKey(key))}",
                    style: const TextStyle(fontSize: 8, color: Colors.white),
                  ),
                const SizedBox(height: 3),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // ---------- Interaction ----------
  void _onKeyDown(BuildContext context, PianoKey key) {
    setState(() => activeKeys.add(key.midi));
    context.read<TunerProvider>().playNote(_frequencyFromKey(key));
  }

  void _onKeyUp(BuildContext context, PianoKey key) {
    setState(() => activeKeys.remove(key.midi));
    if (activeKeys.isEmpty) {
      context.read<TunerProvider>().stopNote();
    }
  }

  // ---------- Frequency ----------
  double _frequencyFromKey(PianoKey key) {
    double base = widget.a4 * pow(2, (key.midi - 69) / 12);

    switch (key.microTone) {
      case MicroToneType.koron:
        return base * pow(2, -0.5 / 12);
      case MicroToneType.sori:
        return base * pow(2, 0.5 / 12);
      default:
        return base;
    }
  }

  // ---------- Layout helpers ----------
  double _blackKeyOffset(PianoKey key, TunerKeyboardSettings settings) {
    const pattern = {
      1: 1.0,
      3: 2.0,
      6: 4.0,
      8: 5.0,
      10: 6.0,
    };

    final index = key.midi % 12;
    final base = pattern[index]! * whiteKeyWidth;
    final octaveOffset = (key.octave - settings.startOctave) * 7 * whiteKeyWidth;

    return base + octaveOffset - blackKeyWidth / 2;
  }

  double _microToneTop(PianoKey key) {
    switch (key.microTone) {
      case MicroToneType.koron:
        return whiteKeyHeight - 55;
      case MicroToneType.sori:
        return whiteKeyHeight - 95;
      default:
        return 0;
    }
  }

  Color _microToneColor(PianoKey key) {
    switch (key.microTone) {
      case MicroToneType.koron:
        return Colors.deepPurple;
      case MicroToneType.sori:
        return Colors.green;
      default:
        return Colors.black;
    }
  }
}

