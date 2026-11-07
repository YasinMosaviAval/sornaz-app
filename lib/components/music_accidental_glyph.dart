import 'package:flutter/material.dart';

/// Official Bravura / SMuFL symbols shared by musical keyboards.
class MusicAccidentalGlyph extends StatelessWidget {
  const MusicAccidentalGlyph({
    super.key,
    required this.accidental,
    this.size = 18,
    this.color,
  }) : assert(accidental == 'k' || accidental == 'o');

  final String accidental;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Text(
      accidental == 'k' ? '\uE460' : '\uE461',
      style: TextStyle(
        fontFamily: 'Bravura',
        fontSize: size,
        height: 1,
        fontWeight: FontWeight.normal,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}
