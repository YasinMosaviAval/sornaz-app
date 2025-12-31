import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

class NotePlayer {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isInited = false;
  bool isPlaying = false;

  static const int sampleRate = 44100;

  Future<void> init() async {
    if (_isInited) return;
    await _player.openPlayer();
    _isInited = true;
  }

  Future<void> play(double frequency, {int durationSeconds = 5}) async {
    await init();

    final pcmData = _generateSineWave(frequency, durationSeconds);
    isPlaying = true;

    await _player.startPlayer(
      fromDataBuffer: pcmData,
      codec: Codec.pcm16,
      sampleRate: sampleRate,
      numChannels: 1,
      whenFinished: () {
        isPlaying = false;
      },
    );
  }

  Future<void> stop() async {
    if (_player.isPlaying) {
      await _player.stopPlayer();
      isPlaying = false;
    }
  }

  Uint8List _generateSineWave(double freq, int durationSeconds) {
    final int samples = sampleRate * durationSeconds;
    final buffer = Int16List(samples);
    final double twoPi = 2 * pi;

    for (int i = 0; i < samples; i++) {
      buffer[i] = (sin(twoPi * freq * i / sampleRate) * 32767).toInt();
    }

    return buffer.buffer.asUint8List();
  }
}
