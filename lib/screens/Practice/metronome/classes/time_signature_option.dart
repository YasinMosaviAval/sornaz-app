class TimeSignatureOption {
  final int beats;
  final int noteValue; // 4 or 8
  final String label;

  // const TimeSignatureOption(this.beats, this.noteValue)
  //     : label = '$beats/$noteValue';
  const TimeSignatureOption(this.beats, this.noteValue)
      : label = '$beats';
}


final List<TimeSignatureOption> timeSignatures = const [
  TimeSignatureOption(2, 4),
  TimeSignatureOption(3, 4),
  TimeSignatureOption(4, 4),
  TimeSignatureOption(5, 4),
  TimeSignatureOption(6, 4),
  TimeSignatureOption(7, 4),
  TimeSignatureOption(8, 4),
  // TimeSignatureOption(9, 4),
  // TimeSignatureOption(10, 4),
  // TimeSignatureOption(11, 4),
  // TimeSignatureOption(12, 4),
  // TimeSignatureOption(13, 4),
  // TimeSignatureOption(14, 4),
  // TimeSignatureOption(15, 4),
  // TimeSignatureOption(16, 4),
];
