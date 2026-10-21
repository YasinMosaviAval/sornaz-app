import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:flutter/foundation.dart' show compute;

/// Normalized difference (YIN) detector for Windows and iOS microphone PCM.
/// Returns -1 for silence or aperiodic input instead of inventing a note.
double detectDesktopPitch(List<double> samples, int sampleRate) {
  if (samples.length < 1024 || sampleRate < 8000) return -1;
  final length = samples.length ~/ 2;
  final maxLag = math.min(length - 1, sampleRate ~/ 20);
  final minLag = math.max(2, sampleRate ~/ 5000);
  var energy = 0.0;
  for (final value in samples) energy += value * value;
  if (energy / samples.length < 0.00001) return -1;
  final difference = Float64List(maxLag + 1);
  final rawDifference = Float64List(maxLag + 1);
  var sum = 0.0;
  for (var lag = 1; lag <= maxLag; lag++) {
    var value = 0.0;
    for (var i = 0; i < length; i++) {
      final delta = samples[i] - samples[i + lag];
      value += delta * delta;
    }
    sum += value;
    rawDifference[lag] = value;
    difference[lag] = sum > 0 ? value * lag / sum : 1;
  }
  for (var lag = minLag; lag < maxLag; lag++) {
    if (difference[lag] >= .15) continue;
    while (lag + 1 <= maxLag && difference[lag + 1] < difference[lag]) lag++;
    var period = lag.toDouble();
    if (lag > 1 && lag < maxLag) {
      final left = rawDifference[lag - 1], center = rawDifference[lag];
      final right = rawDifference[lag + 1];
      final divisor = 2 * (left - 2 * center + right);
      if (divisor.abs() > 1e-12) period += (left - right) / divisor;
    }
    return sampleRate / period;
  }
  return -1;
}

double _detectFrame((Float64List, int) frame) =>
    detectDesktopPitch(frame.$1, frame.$2);

class DesktopPitchInput {
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _subscription;
  final _bytes = <int>[];
  double _frequency = -1;
  Object? _error;
  int _generation = 0;
  bool _processing = false;

  Future<void> start(int sampleRate) async {
    if (sampleRate < 8000 || sampleRate > 192000)
      throw ArgumentError('Invalid sample rate');
    await stop();
    final generation = _generation;
    final recorder = AudioRecorder();
    _recorder = recorder;
    try {
      if (!await recorder.hasPermission())
        throw StateError('Microphone permission');
      final stream = await recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
          echoCancel: false,
          noiseSuppress: false,
          autoGain: false,
        ),
      );
      if (generation != _generation) return;
      _subscription = stream.listen(
        (chunk) {
          if (generation != _generation) return;
          _bytes.addAll(chunk);
          final decimation = math.max(1, (sampleRate / 22050).round());
          final windowBytes = 4096 * decimation * 2;
          if (_bytes.length < windowBytes) return;
          if (_processing) {
            if (_bytes.length > windowBytes)
              _bytes.removeRange(0, _bytes.length - windowBytes);
            return;
          }
          final frame = Uint8List.fromList(
            _bytes.sublist(_bytes.length - windowBytes),
          );
          _bytes.clear();
          final data = ByteData.sublistView(frame);
          // Box-filter before decimation; retain the configured capture rate.
          final samples = Float64List(4096);
          for (var i = 0; i < samples.length; i++) {
            var value = 0;
            for (var j = 0; j < decimation; j++) {
              value += data.getInt16((i * decimation + j) * 2, Endian.little);
            }
            samples[i] = value / (decimation * 32768);
          }
          _processing = true;
          unawaited(
            compute(_detectFrame, (samples, (sampleRate / decimation).round()))
                .then(
                  (value) {
                    if (generation == _generation) _frequency = value;
                  },
                  onError: (Object error) {
                    if (generation == _generation) _error = error;
                  },
                )
                .whenComplete(() {
                  if (generation == _generation) _processing = false;
                }),
          );
        },
        onError: (Object error) {
          _error = error;
        },
      );
    } catch (_) {
      await stop();
      rethrow;
    }
  }

  Future<void> stop() async {
    _generation++;
    await _subscription?.cancel();
    _subscription = null;
    final recorder = _recorder;
    _recorder = null;
    try {
      await recorder?.stop();
    } finally {
      await recorder?.dispose();
    }
    _bytes.clear();
    _processing = false;
    _frequency = -1;
    _error = null;
  }

  double read() {
    if (_error != null) throw StateError('Microphone stream failed: $_error');
    return _frequency;
  }
}
