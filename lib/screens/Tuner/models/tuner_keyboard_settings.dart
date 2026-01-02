class TunerKeyboardSettings {
  int startOctave;
  int octaveCount;
  bool highlightA4;
  bool showWhiteKeyFrequencies;
  bool showBlackKeyFrequencies;

  TunerKeyboardSettings({
    required this.startOctave,
    required this.octaveCount,
    required this.highlightA4,
    this.showWhiteKeyFrequencies = true,
    this.showBlackKeyFrequencies = false,
  });
}
