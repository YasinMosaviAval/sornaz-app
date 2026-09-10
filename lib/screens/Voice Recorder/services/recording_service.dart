import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:record/record.dart';

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
      final db = amp.current;
      final normalized = db < -60 ? 0.0 : (db + 60) / 60;
      onAmplitude(normalized.clamp(0.0, 1.0));
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
