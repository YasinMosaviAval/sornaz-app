import 'package:sornaz/helpers/browser_bridge.dart';
class PitchInput {
  Future<void> start() async { await browserCall('startPitch'); }
  Future<void> stop() async { await browserCall('stopPitch'); }
  Future<double> read() async => ((await browserCall('readPitch')) as num).toDouble();
}
