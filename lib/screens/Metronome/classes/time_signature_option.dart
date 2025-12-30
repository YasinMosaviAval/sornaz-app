class TimeSignatureOption {
  final int beats;
  final int noteValue;
  final String label;

  const TimeSignatureOption(this.beats, this.noteValue)
      : label = '$beats';
  //     : label = '$beats/$noteValue';
}


final List<TimeSignatureOption> timeSignatures = const [
  TimeSignatureOption(2, 4),
  TimeSignatureOption(3, 4),
  TimeSignatureOption(4, 4),
  TimeSignatureOption(5, 4),
  TimeSignatureOption(6, 4),
  TimeSignatureOption(7, 4),
  TimeSignatureOption(8, 4),
];
