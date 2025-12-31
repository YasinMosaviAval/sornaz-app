/*
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

class NotePlayer {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isInited = false;

  static const int sampleRate = 44100;

  Future<void> init() async {
    if (_isInited) return;
    await _player.openPlayer();
    _isInited = true;
  }

  Future<void> play(double frequency) async {
    await init();

    final pcmData = _generateSineWave(frequency);

    await _player.startPlayer(
      fromDataBuffer: pcmData,
      codec: Codec.pcm16,
      sampleRate: sampleRate,
      numChannels: 1,
      // whenFinished: () {
      //   // loop برای پخش ممتد
      //   play(frequency);
      // },
    );
  }

  Future<void> stop() async {
    if (_player.isPlaying) {
      await _player.stopPlayer();
    }
  }

  Uint8List _generateSineWave(double freq) {
    const durationSeconds = 60;
    final int samples = sampleRate * durationSeconds;
    final buffer = Int16List(samples);

    for (int i = 0; i < samples; i++) {
      buffer[i] = (sin(2 * pi * freq * i / sampleRate) * 32767).toInt();
    }

    return buffer.buffer.asUint8List();
  }
}
*/

import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

class NotePlayer {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isInited = false;
  bool isPlaying = false; // flag برای وضعیت پخش

  static const int sampleRate = 44100;

  /// آماده‌سازی player
  Future<void> init() async {
    if (_isInited) return;
    await _player.openPlayer();
    _isInited = true;
  }

  /// پخش یک نوت به مدت durationSeconds (مثلاً 60 ثانیه)
  Future<void> play(double frequency, {int durationSeconds = 60}) async {
    await init();

    final pcmData = _generateSineWave(frequency, durationSeconds);
    isPlaying = true;

    await _player.startPlayer(
      fromDataBuffer: pcmData,
      codec: Codec.pcm16,
      sampleRate: sampleRate,
      numChannels: 1,
      whenFinished: () {
        isPlaying = false; // پخش تمام شد
      },
    );
  }

  /// توقف پخش در هر لحظه
  Future<void> stop() async {
    if (_player.isPlaying) {
      await _player.stopPlayer();
      isPlaying = false;
    }
  }

  /// تولید PCM سینوسی برای frequency و مدت زمان durationSeconds
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
