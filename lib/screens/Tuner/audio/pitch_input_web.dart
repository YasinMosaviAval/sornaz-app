import 'package:sornaz/helpers/browser_bridge.dart';

class PitchInput {
  Future<void> start([int sampleRate = 44100]) async {
    await browserCall('startPitch', {'sampleRate': sampleRate});
  }

  Future<void> stop() async {
    await browserCall('stopPitch');
  }

  Future<double> read() async =>
      ((await browserCall('readPitch')) as num).toDouble();
}
