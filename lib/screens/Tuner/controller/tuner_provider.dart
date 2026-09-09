import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../audio/pitch_input.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/screens/Tuner/audio/note_player.dart';
import 'package:sornaz/screens/Tuner/models/tuner_keyboard_settings.dart';
import 'package:sornaz/screens/Tuner/utils/tuner_math.dart';

class TunerProvider extends ChangeNotifier {
  Timer? _pitchTimer;
  bool _polling = false;
  bool _running = false;
  bool _disposed = false;
  Future<void> _transition = Future.value();
  bool _requested = false;
  String? detectionError;
  final PitchInput _pitch = PitchInput();

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
    AppConstants.B,
  ];

  bool get supportsPitchDetection => Platform.isAndroid || Platform.isIOS;

  Future<void> start() {
    _requested = true;
    return _reconcile();
  }

  Future<void> stop() {
    _requested = false;
    return _reconcile();
  }

  Future<void> _reconcile() {
    _transition = _transition
        .then((_) async {
          if (_disposed || !_requested) {
            _pitchTimer?.cancel();
            _pitchTimer = null;
            if (_running) await _pitch.stop();
            _running = false;
            return;
          }
          if (_running || !supportsPitchDetection) return;
          detectionError = null;
          final permission = await Permission.microphone.request();
          if (_disposed || !_requested) return;
          if (!permission.isGranted) {
            detectionError = 'permission';
            notifyListeners();
            return;
          }
          // No call to the broken plugin precision setter after startup.
          await _pitch.start();
          _running = true;
          if (_disposed || !_requested) {
            await _pitch.stop();
            _running = false;
            return;
          }
          notifyListeners();
          var failures = 0;
          _pitchTimer = Timer.periodic(const Duration(milliseconds: 40), (
            _,
          ) async {
            if (_polling || !_running || _disposed) return;
            _polling = true;
            try {
              final value = await _pitch.read();
              failures = 0;
              if (_running && !_disposed && _requested) {
                _onPitchDetected({AppConstants.FREQUENCY: value});
              }
            } catch (_) {
              if (++failures >= 5 && !_disposed && _requested) {
                detectionError = 'input';
                notifyListeners();
                unawaited(stop());
              }
            } finally {
              _polling = false;
            }
          });
        })
        .catchError((Object error) async {
          _pitchTimer?.cancel();
          try {
            await _pitch.stop();
          } catch (_) {}
          _running = false;
          if (!_disposed) {
            detectionError = 'input';
            notifyListeners();
          }
        });
    return _transition;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(stop());
    unawaited(notePlayer.stop());
    super.dispose();
  }

  void _onPitchDetected(dynamic result) {
    final freq = (result[AppConstants.FREQUENCY] ?? 0).toDouble();
    if (_disposed || !freq.isFinite || freq < 25 || freq > 5000) return;
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
