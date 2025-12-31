import 'package:flutter/material.dart';
import 'package:flutter_pitch_detection/flutter_pitch_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/screens/Tuner/utils/tuner_math.dart';

class TunerProvider extends ChangeNotifier {
  final FlutterPitchDetection _pitch = FlutterPitchDetection();

  double frequency = 0.0;
  double a4 = 440.0;
  double noteFreq = 0.0;
  String note = AppStrings.epmty_text;

  final notes = [
    AppStrings.note_c,
    AppStrings.note_c_sharp,
    AppStrings.note_d,
    AppStrings.note_d_sharp,
    AppStrings.note_e,
    AppStrings.note_f,
    AppStrings.note_f_sharp,
    AppStrings.note_g,
    AppStrings.note_g_sharp,
    AppStrings.note_a,
    AppStrings.note_a_sharp,
    AppStrings.note_b
  ];

  Future<void> start() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    _pitch.startDetection();
    _pitch.onPitchDetected.listen(_onPitchDetected);
  }

  void stop() {
    _pitch.stopDetection();
  }

  void setA4(double value) {
    a4 = value;
    notifyListeners();
  }

  void _onPitchDetected(dynamic result) {
    final freq = (result['frequency'] ?? 0).toDouble();
    frequency = freq;

    final analyzed = analyzePitch(freq);
    note = analyzed.note;
    noteFreq = analyzed.targetFreq;

    notifyListeners();
  }

  TunerResult analyzePitch(double freq) {
    return TunerMath.analyze(freq, a4, notes);
  }
}
