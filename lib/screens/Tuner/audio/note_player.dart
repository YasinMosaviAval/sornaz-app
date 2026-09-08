import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class NotePlayer {
  final AudioPlayer _player = AudioPlayer();
  bool _isInited = false;
  bool isPlaying = false;
  static const int sampleRate = 44100;

  Future<void> init() async {
    if (_isInited) return;
    _player.onPlayerComplete.listen((_) => isPlaying = false);
    _isInited = true;
  }

  Future<void> play(double frequency, int durationSeconds) async {
    await init();
    await stop();
    final wav = generateWave(frequency, durationSeconds);
    await _player.play(BytesSource(wav, mimeType: 'audio/wav'));
    isPlaying = true;
  }

  Future<void> stop() async {
    await _player.stop();
    isPlaying = false;
  }

  /// PCM16 mono WAV works with the existing Android and Windows audio backends.
  static Uint8List generateWave(double frequency, int durationSeconds) {
    if (!frequency.isFinite || frequency < 1 || frequency > 20000 || durationSeconds < 1 || durationSeconds > 60) {
      throw ArgumentError('Invalid tone frequency or duration.');
    }
    final samples = sampleRate * durationSeconds;
    final data = ByteData(44 + samples * 2);
    void tag(int offset, String value) {
      for (var i = 0; i < value.length; i++) { data.setUint8(offset + i, value.codeUnitAt(i)); }
    }
    tag(0, 'RIFF'); data.setUint32(4, 36 + samples * 2, Endian.little);
    tag(8, 'WAVE'); tag(12, 'fmt '); data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little); data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little); data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little); data.setUint16(34, 16, Endian.little);
    tag(36, 'data'); data.setUint32(40, samples * 2, Endian.little);
    for (var i = 0; i < samples; i++) {
      // Short fades prevent clicks when starting and ending a tone.
      final fade = min(1.0, min(i, samples - 1 - i) / 220);
      data.setInt16(44 + i * 2, (sin(2 * pi * frequency * i / sampleRate) * 32767 * fade).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }
}
