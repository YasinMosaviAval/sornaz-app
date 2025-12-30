import 'dart:async';
import 'package:record/record.dart';

class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription? _ampSub;

  Future<void> start({
    required String path,
    required void Function(double) onAmplitude,
  }) async {
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: path,
    );

    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
      final db = amp.current;
      final norm = db < -60 ? 0 : (db + 60) / 60;
      // onAmplitude(norm);
      onAmplitude(norm as double);
    });
  }

  Future<void> stop() async {
    await _ampSub?.cancel();
    await _recorder.stop();
  }
}
