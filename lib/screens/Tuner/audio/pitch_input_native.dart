import 'package:flutter/services.dart';
import 'package:sornaz/helpers/app_platform.dart';
import 'desktop_pitch_input.dart';

/// Calls the native contract directly: plugin 1.3.1's Dart precision setter
/// sends `setMinPrecision`, while Android requires `minPrecision`.
class PitchInput {
  PitchInput({DesktopPitchInput? pcmInput})
    : _desktop = pcmInput ?? DesktopPitchInput();
  final DesktopPitchInput _desktop;
  bool get _usePcm => AppPlatform.isWindows || AppPlatform.isIOS;
  static const channel = MethodChannel('pitch_detection/methods');
  Future<void> start([int sampleRate = 44100]) async {
    if (_usePcm) return _desktop.start(sampleRate);
    await channel.invokeMethod<void>('startDetection', {
      'sampleRate': sampleRate,
      // Android's detector enforces >=8192 samples. Match it explicitly.
      'bufferSize': 8192,
      'overlap': 6144,
      'minPrecision': 0.7,
      'toleranceCents': 0.5,
      'a4Reference': 440.0,
    });
  }

  Future<void> stop() =>
      _usePcm ? _desktop.stop() : channel.invokeMethod<void>('stopDetection');
  Future<double> read() async => _usePcm
      ? _desktop.read()
      : (await channel.invokeMethod<num>('getFrequency'))?.toDouble() ?? -1;
}
