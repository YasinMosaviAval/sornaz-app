import 'package:flutter/foundation.dart';
import 'package:sornaz/helpers/app_platform.dart';
import 'dart:async';
import '../audio/pitch_input.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/screens/Tuner/audio/note_player.dart';
import 'package:sornaz/screens/Tuner/models/tuner_keyboard_settings.dart';
import 'package:sornaz/screens/Tuner/utils/tuner_math.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TunerProvider extends ChangeNotifier {
  TunerProvider() {
    _sampleRateLoaded = _loadSampleRate();
  }
  static const defaultSampleRate = 44100;
  static const defaultLineThickness = 1.2;
  static const defaultGraphFillDuration = 0.96;
  int sampleRate = defaultSampleRate;
  double lineThickness = defaultLineThickness;
  double graphFillDuration = defaultGraphFillDuration;
  late final Future<void> _sampleRateLoaded;
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

  Future<void> _loadSampleRate() async {
    final preferences = await SharedPreferences.getInstance();
    final sampleRateValue = preferences.getInt('tuner.sampleRate');
    final lineThicknessValue = preferences.getDouble('tuner.lineThickness');
    final graphFillDurationValue = preferences.getDouble(
      'tuner.graphFillDuration',
    );
    if (_disposed) return;
    if (sampleRateValue != null &&
        sampleRateValue >= 8000 &&
        sampleRateValue <= 192000) {
      sampleRate = sampleRateValue;
    }
    if (lineThicknessValue != null &&
        lineThicknessValue >= defaultLineThickness / 2 &&
        lineThicknessValue <= defaultLineThickness * 5) {
      lineThickness = lineThicknessValue;
    }
    if (graphFillDurationValue != null &&
        graphFillDurationValue >= 0.1 &&
        graphFillDurationValue <= 30) {
      graphFillDuration = graphFillDurationValue;
    }
    notifyListeners();
  }

  Future<void> setSampleRate(int value) async {
    if (value < 8000 || value > 192000 || value == sampleRate) return;
    sampleRate = value;
    await (await SharedPreferences.getInstance()).setInt(
      'tuner.sampleRate',
      value,
    );
    notifyListeners();
    if (_requested) {
      _pitchTimer?.cancel();
      _pitchTimer = null;
      if (_running) await _pitch.stop();
      _running = false;
      await _reconcile();
    }
  }

  Future<void> setLineThickness(double value) async {
    final normalized = value
        .clamp(defaultLineThickness / 2, defaultLineThickness * 5)
        .toDouble();
    if (normalized == lineThickness) return;
    lineThickness = normalized;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setDouble(
      'tuner.lineThickness',
      normalized,
    );
  }

  Future<void> setGraphFillDuration(double value) async {
    if (value < 0.1 || value > 30 || value == graphFillDuration) return;
    graphFillDuration = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setDouble(
      'tuner.graphFillDuration',
      value,
    );
  }

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

  bool get supportsPitchDetection =>
      kIsWeb || AppPlatform.isAndroid || AppPlatform.isIOS;

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
          await _sampleRateLoaded;
          if (_disposed || !_requested) return;
          detectionError = null;
          final granted =
              kIsWeb || (await Permission.microphone.request()).isGranted;
          if (_disposed || !_requested) return;
          if (!granted) {
            detectionError = 'permission';
            notifyListeners();
            return;
          }
          // No call to the broken plugin precision setter after startup.
          await _pitch.start(sampleRate);
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
