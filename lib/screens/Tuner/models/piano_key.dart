class PianoKey {
  final String name;
  final int octave;
  final int midi;
  final bool isBlack;
  final MicroToneType microTone;

  const PianoKey({
    required this.name,
    required this.octave,
    required this.midi,
    required this.isBlack,
    this.microTone = MicroToneType.normal,
  });

  // String get label => "$name$octave";

  String get label {
    switch (microTone) {
      case MicroToneType.koron:
        return "$name↓";
      case MicroToneType.sori:
        return "$name↑";
      default:
        return name;
    }
  }

}


enum MicroToneType {
  normal,
  koron,
  sori,
}
