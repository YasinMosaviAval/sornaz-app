import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pitch_detection/flutter_pitch_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/screens/Tuner/audio/note_player.dart';
import 'package:sornaz/screens/Tuner/models/tuner_keyboard_settings.dart';
import 'package:sornaz/screens/Tuner/utils/tuner_math.dart';

class TunerProvider extends ChangeNotifier {
  final FlutterPitchDetection _pitch = FlutterPitchDetection();

  double frequency = 0.0;
  double a4 = 440.0;
  double noteFreq = 0.0;
  String note = AppConstants.EMPTY_TEXT;

  int noteDurationSeconds = 1;

  void setNoteDuration(int seconds) {
    noteDurationSeconds = seconds;
    notifyListeners();
  }

  void setA4(double frequencyBase) {
    a4 = frequencyBase;
    notifyListeners();
  }

  void playNote(double freq) async {
    await notePlayer.play(freq, noteDurationSeconds);
  }

  final NotePlayer notePlayer = NotePlayer();

  Future<void> stopNote() async {
    await notePlayer.stop();
  }

  final notes = [
    AppConstants.C,
    AppConstants.C_SHARP,
    AppConstants.D,
    AppConstants.D_SHARP,
    AppConstants.E,
    AppConstants.F,
    AppConstants.F_SHARP,
    AppConstants.G,
    AppConstants.G_SHARP,
    AppConstants.A,
    AppConstants.A_SHARP,
    AppConstants.B
  ];

  bool get supportsPitchDetection => Platform.isAndroid || Platform.isIOS;

  Future<void> start() async {
    await notePlayer.init();
    if (!supportsPitchDetection) return;

    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    _pitch.startDetection();
    _pitch.onPitchDetected.listen(_onPitchDetected);
  }

  void stop() {
    if (supportsPitchDetection) _pitch.stopDetection();
  }

  void _onPitchDetected(dynamic result) {
    final freq = (result[AppConstants.FREQUENCY] ?? 0).toDouble();
    frequency = freq;

    final analyzed = analyzePitch(freq);
    note = analyzed.note;
    noteFreq = analyzed.targetFreq;

    notifyListeners();
  }

  TunerResult analyzePitch(double freq) {
    return TunerMath.analyze(freq, a4, notes);
  }



  final keyboardSettings = TunerKeyboardSettings(
    startOctave: 3,
    octaveCount: 3,
    highlightA4: true,
  );

  // ---------- setters ----------
  void setStartOctave(int value) {
    keyboardSettings.startOctave = value;
    notifyListeners();
  }

  void setOctaveCount(int value) {
    keyboardSettings.octaveCount = value;
    notifyListeners();
  }

  void setHighlightA4(bool value) {
    keyboardSettings.highlightA4 = value;
    notifyListeners();
  }


  void setShowWhiteKeyFrequencies(bool value) {
    keyboardSettings.showWhiteKeyFrequencies = value;
    notifyListeners();
  }

  void setShowBlackKeyFrequencies(bool value) {
    keyboardSettings.showBlackKeyFrequencies = value;
    notifyListeners();
  }

  // void toggleQuarterTones(bool value) {
  //   keyboardSettings.showQuarterTones = value;
  //   notifyListeners();
  // }

  void toggleQuarterTones() { 
    keyboardSettings.showQuarterTones = !keyboardSettings.showQuarterTones;
    notifyListeners();
  }

}
