import 'package:flutter/material.dart';


class NoteLength {
  final String name;
  final double multiplier;
  final Widget icon;

  const NoteLength({
    required this.name,
    required this.multiplier,
    required this.icon,
  });
}

const noteLengths = [
  NoteLength(
    name: 'Quarter',
    multiplier: 1.0,
    icon: Icon(Icons.music_note), // بعداً با آیکن واقعی جایگزین
  ),
  NoteLength(
    name: 'Eighth',
    multiplier: 0.5,
    icon: Icon(Icons.library_music),
  ),
  NoteLength(
    name: 'Triplet',
    multiplier: 1 / 3,
    icon: Icon(Icons.queue_music),
  ),
  NoteLength(
    name: 'Half',
    multiplier: 2.0,
    icon: Icon(Icons.audiotrack),
  ),
];
