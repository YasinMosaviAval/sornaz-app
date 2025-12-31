import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:sornaz/screens/Tuner/controller/tuner_provider.dart';

class PianoKeyboard extends StatefulWidget {
  final double a4;
  final int octaves;

  const PianoKeyboard({
    super.key,
    this.a4 = 440.0,
    this.octaves = 3,
  });

  @override
  PianoKeyboardState createState() => PianoKeyboardState();
}

class PianoKeyboardState extends State<PianoKeyboard> {
  final Set<int> activeKeys = {}; // کلیدهای فعال
  final List<String> noteNames = [
    "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
  ];

  bool _isBlack(String name) => name.contains("#");


  @override
  Widget build(BuildContext context) {
    final whiteKeyWidth = 60.0;
    final whiteKeyHeight = 100.0;
    final blackKeyWidth = 40.0;
    final blackKeyHeight = 60.0;

    // تعداد کل کلیدهای سفید
    final int totalWhiteKeys = widget.octaves * 7;
    final double containerWidth = totalWhiteKeys * whiteKeyWidth;

    // کلیدها با اطلاعات MIDI و نوع
    final List<Map<String, dynamic>> keys = [];
    for (int o = 0; o < widget.octaves; o++) {
      for (int i = 0; i < noteNames.length; i++) {
        final midi = 12 * (o + 4) + i;
        keys.add({
          "name": noteNames[i],
          "midi": midi,
          "isBlack": _isBlack(noteNames[i]),
          "octave": o,
        });
      }
    }

    final whiteKeys = keys.where((k) => !k["isBlack"]).toList();
    final blackKeys = keys.where((k) => k["isBlack"]).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: containerWidth,
        height: whiteKeyHeight,
        child: Stack(
          children: [
            // کلیدهای سفید
            Row(
              children: whiteKeys.map((k) {
                final freq = widget.a4 * pow(2, (k["midi"] - 69) / 12);
                final isActive = activeKeys.contains(k["midi"]);
                return GestureDetector(
                  onTapDown: (_) {
                    setState(() => activeKeys.add(k["midi"]));
                    context.read<TunerProvider>().playNote(freq);
                  },
                  onTapUp: (_) {
                    setState(() => activeKeys.remove(k["midi"]));
                    context.read<TunerProvider>().stopNote();
                  },
                  onTapCancel: () {
                    setState(() => activeKeys.remove(k["midi"]));
                    context.read<TunerProvider>().stopNote();
                  },
                  child: Container(
                    width: whiteKeyWidth,
                    height: whiteKeyHeight,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.yellow : Colors.white,
                      border: Border.all(color: Colors.black),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      k["name"],
                      style: TextStyle(
                        color: isActive ? Colors.black : Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            // کلیدهای سیاه
            ...blackKeys.map((k) {
              final freq = widget.a4 * pow(2, (k["midi"] - 69) / 12);
              final isActive = activeKeys.contains(k["midi"]);
              int indexInOctave = k["midi"] % 12;
              double baseOffset = 0;
              switch (indexInOctave) {
                case 1: baseOffset = whiteKeyWidth - blackKeyWidth / 2; break; // C#
                case 3: baseOffset = whiteKeyWidth * 2 - blackKeyWidth / 2; break; // D#
                case 6: baseOffset = whiteKeyWidth * 4 - blackKeyWidth / 2; break; // F#
                case 8: baseOffset = whiteKeyWidth * 5 - blackKeyWidth / 2; break; // G#
                case 10: baseOffset = whiteKeyWidth * 6 - blackKeyWidth / 2; break; // A#
                default: baseOffset = 0;
              }
              baseOffset += k["octave"] * whiteKeyWidth * 7;

              return Positioned(
                left: baseOffset,
                child: GestureDetector(
                  onTapDown: (_) {
                    setState(() => activeKeys.add(k["midi"]));
                    context.read<TunerProvider>().playNote(freq);
                  },
                  onTapUp: (_) {
                    setState(() => activeKeys.remove(k["midi"]));
                    context.read<TunerProvider>().stopNote();
                  },
                  onTapCancel: () {
                    setState(() => activeKeys.remove(k["midi"]));
                    context.read<TunerProvider>().stopNote();
                  },
                  child: Container(
                    width: blackKeyWidth,
                    height: blackKeyHeight,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.orange : Colors.black,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.black),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      k["name"],
                      style: TextStyle(
                        color: isActive ? Colors.black : Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
