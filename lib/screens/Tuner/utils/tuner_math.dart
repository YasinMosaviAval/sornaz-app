import 'dart:math';

class TunerResult {
  final String note;
  final double targetFreq;
  final double cents;

  TunerResult(this.note, this.targetFreq, this.cents);
}

class TunerMath {
  static TunerResult analyze(
      double freq, double a4, List<String> notes) {
    if (freq <= 0) {
      return TunerResult("--", 0, 0);
    }

    final midi = 69 + 12 * log(freq / a4) / ln2;
    final midiNote = midi.round();
    final noteName = notes[midiNote % 12];
    final targetFreq =
        a4 * pow(2, (midiNote - 69) / 12).toDouble();

    final cents =
        1200 * log(freq / targetFreq) / ln2;

    return TunerResult(
      noteName,
      targetFreq,
      cents.clamp(-50, 50),
    );
  }

  static double noteFrequency(
    int midiNote,
    double a4,
  ) {
    return a4 * pow(2, (midiNote - 69) / 12);
  }

}
