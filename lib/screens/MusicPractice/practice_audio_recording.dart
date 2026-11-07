import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import '../Tuner/audio/desktop_pitch_input.dart' show detectDesktopPitch;

/// Captures one PCM stream for both replay and pitch/rhythm observations.
class PracticeAudioRecording {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _subscription;
  Timer? _limit;
  final BytesBuilder _bytes = BytesBuilder(copy: false);
  bool _disposed = false;
  Object? _error;

  Future<void> start(void Function() onLimit) async {
    if (_disposed) throw StateError('Recorder is closed');
    _bytes.clear();
    _error = null;
    if (!await _recorder.hasPermission()) {
      throw StateError('Microphone permission');
    }
    if (_disposed) throw StateError('Recorder is closed');
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        echoCancel: false,
        noiseSuppress: false,
        autoGain: false,
      ),
    );
    if (_disposed) {
      await _recorder.stop();
      throw StateError('Recorder is closed');
    }
    _subscription = stream.listen(
      (chunk) {
        if (_disposed) return;
        final remaining = 1280000 - _bytes.length;
        if (remaining > 0) {
          _bytes.add(
            chunk.length <= remaining
                ? chunk
                : Uint8List.sublistView(chunk, 0, remaining),
          );
        }
        if (_bytes.length >= 1280000) onLimit();
      },
      onError: (Object error) {
        _error = error;
        onLimit();
      },
    );
    _limit = Timer(const Duration(seconds: 40), onLimit);
  }

  Future<({Uint8List wav, Map<String, dynamic> observations})> stop() async {
    _limit?.cancel();
    await _recorder.stop();
    await _subscription?.cancel();
    _subscription = null;
    if (_error != null) throw StateError('Recording failed');
    final pcm = _bytes.takeBytes();
    if (pcm.length < 9600) throw StateError('Recording is too short');
    final observations = await compute(analyzePracticePcm, pcm);
    final wav = Uint8List(pcm.length + 44), data = ByteData.sublistView(wav);
    void text(int at, String value) =>
        wav.setRange(at, at + value.length, value.codeUnits);
    text(0, 'RIFF');
    data.setUint32(4, pcm.length + 36, Endian.little);
    text(8, 'WAVE');
    text(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, 16000, Endian.little);
    data.setUint32(28, 32000, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    text(36, 'data');
    data.setUint32(40, pcm.length, Endian.little);
    wav.setRange(44, wav.length, pcm);
    return (wav: wav, observations: observations);
  }

  Future<void> dispose() async {
    _disposed = true;
    _limit?.cancel();
    await _subscription?.cancel();
    await _recorder.dispose();
    _bytes.clear();
  }
}

Map<String, dynamic> analyzePracticePcm(Uint8List pcm) {
  final source = ByteData.sublistView(pcm), frames = <List<int>>[];
  final count = pcm.length ~/ 4, samples = Float64List(count);
  for (var i = 0; i < count; i++) {
    samples[i] =
        (source.getInt16(i * 4, Endian.little) +
            source.getInt16(i * 4 + 2, Endian.little)) /
        65536;
  }
  for (var at = 0; at < count && frames.length < 800; at += 400) {
    final length = math.min(1024, count - at), frame = Float64List(1024);
    frame.setRange(0, length, samples, at);
    var energy = 0.0;
    for (var i = 0; i < math.min(400, length); i++) {
      energy += frame[i] * frame[i];
    }
    final rms = math.sqrt(energy / math.min(400, length));
    final hz = rms > .003 ? detectDesktopPitch(frame, 8000) : -1.0;
    frames.add([
      (at * 1000 / 8000).round(),
      hz > 0 ? (hz * 100).round().clamp(0, 500000) : 0,
      (rms * 1000).round().clamp(0, 1000),
    ]);
  }
  return {'durationMs': (pcm.length * 1000 / 32000).floor(), 'frames': frames};
}
