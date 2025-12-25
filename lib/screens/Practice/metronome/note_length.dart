import 'package:flutter/material.dart';

/*
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
*/
class NoteLength {
  final String name;
  final double multiplier;
  final Widget Function(Color color, double size) iconBuilder;
  final Widget Function(Color color, double size) selectedIconBuilder;

  const NoteLength({
    required this.name,
    required this.multiplier,
    required this.iconBuilder,
    required this.selectedIconBuilder,
  });

  Widget icon({required Color color, bool isSelectedIcon = false, double size = 36}) {
    return isSelectedIcon? selectedIconBuilder(color, size) : iconBuilder(color, size);
  }
}

final noteLengths = [
  NoteLength(
    name: 'Quarter',
    multiplier: 1.0,
    iconBuilder: (color, size) => Icon(
      Icons.looks_one_outlined,

      // Icons.music_note,
      color: color,
      size: size,
    ),
    selectedIconBuilder: (color, size) => Icon(
      Icons.looks_one,

      // Icons.music_note,
      color: color,
      size: size,
    ),
    
  ),
  NoteLength(
    name: 'Eighth',
    multiplier: 0.5,
    iconBuilder: (color, size) => Icon(
      Icons.looks_two_outlined,
      // Icons.library_music,
      color: color,
      size: size,
    ),
    selectedIconBuilder: (color, size) => Icon(
      Icons.looks_two_rounded,
      // Icons.library_music,
      color: color,
      size: size,
    ),
    
  ),
  NoteLength(
    name: 'Triplet',
    multiplier: 1 / 3,
    iconBuilder: (color, size) => Icon(
      Icons.looks_3_outlined,
      color: color,
      size: size,
    ),
    selectedIconBuilder: (color, size) => Icon(
      Icons.looks_3_sharp,
      color: color,
      size: size,
    ),
    
  ),
  NoteLength(
    name: 'Half',
    multiplier: 2.0,
    iconBuilder: (color, size) => Icon(
      Icons.looks_4_outlined,
      color: color,
      size: size,
    ),
    selectedIconBuilder: (color, size) => Icon(
      Icons.looks_4,
      color: color,
      size: size,
    ),
    
  ),
];

