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
        return "$name♭¼$octave";
      case MicroToneType.sori:
        return "$name♯¼$octave";
      default:
        return "$name$octave";
    }
  }

}


enum MicroToneType {
  normal,
  koron, // ربع پرده پایین
  sori,  // ربع پرده بالا
}
