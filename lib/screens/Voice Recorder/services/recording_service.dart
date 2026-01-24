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
      final normalized = db < -60 ? 0.0 : (db + 60) / 60;
      onAmplitude(normalized);
    });
  }

  Future<void> pause() async {
    await _recorder.pause();
  }

  Future<void> resume() async {
    await _recorder.resume();
  }

  Future<void> stop() async {
    await _ampSub?.cancel();
    _ampSub = null;
    await _recorder.stop();
  }
}
