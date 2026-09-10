import 'package:flutter/services.dart';

/// Calls the native contract directly: plugin 1.3.1's Dart precision setter
/// sends `setMinPrecision`, while Android requires `minPrecision`.
class PitchInput {
  static const channel = MethodChannel('pitch_detection/methods');
  Future<void> start() async {
    await channel.invokeMethod<void>('startDetection', {
      'sampleRate': 44100,
      // Android's detector enforces >=8192 samples. Match it explicitly.
      'bufferSize': 8192,
      'overlap': 6144,
      'minPrecision': 0.7,
      'toleranceCents': 0.5,
      'a4Reference': 440.0,
    });
  }

  Future<void> stop() => channel.invokeMethod<void>('stopDetection');
  Future<double> read() async =>
      (await channel.invokeMethod<num>('getFrequency'))?.toDouble() ?? -1;
}
