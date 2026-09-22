import 'package:record/record.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math' as math;

/// Gate room noise and map logarithmic dB measurements to visible amplitude.
double recordingAmplitude(double db) {
  if (!db.isFinite || db <= -50) return 0;
  final floor = math.pow(10, -50 / 30).toDouble();
  return ((math.pow(10, db / 30) - floor) / (1 - floor)).clamp(0.0, 1.0);
}

class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription? _ampSub;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> dispose() async {
    await _ampSub?.cancel();
    await _recorder.dispose();
  }

  Future<void> start({
    required String path,
    required void Function(double) onAmplitude,
  }) async {
    await _recorder.start(
      RecordConfig(
        encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: path,
    );

    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amp) {
          onAmplitude(recordingAmplitude(amp.current));
        });
  }

  Future<void> pause() async {
    await _recorder.pause();
  }

  Future<void> resume() async {
    await _recorder.resume();
  }

  Future<String?> stop() async {
    await _ampSub?.cancel();
    _ampSub = null;
    return await _recorder.stop();
  }
}
