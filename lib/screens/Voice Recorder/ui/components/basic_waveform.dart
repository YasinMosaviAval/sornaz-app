import 'package:flutter/material.dart';
import 'seekable_waveform.dart';

class BasicWaveformWidget extends StatelessWidget {
  const BasicWaveformWidget({
    super.key,
    required this.amplitudes,
    required this.totalSamples,
    this.bookmarks = const [],
    this.elapsedMilliseconds = 0,
    required this.isRecording,
    required this.isPaused,
  });
  final List<double> amplitudes;
  final int totalSamples, elapsedMilliseconds;
  final List<int> bookmarks;
  final bool isRecording, isPaused;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 250,
    child: SeekableWaveform(
      samples: amplitudes,
      duration: elapsedMilliseconds,
      position: elapsedMilliseconds,
      markers: bookmarks,
    ),
  );
}
