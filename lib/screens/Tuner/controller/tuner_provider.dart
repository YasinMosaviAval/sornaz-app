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
  TunerProvider({NotePlayer? notePlayer})
    : notePlayer = notePlayer ?? NotePlayer() {
    _sampleRateLoaded = _loadSampleRate();
  }
  static const defaultSampleRate = 88200;
  static const defaultLineThickness = 2.0;
  static const defaultGraphFillDuration = 3.0;
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
  bool hasSignal = false;
  double a4 = 440.0;
  double noteFreq = 0.0;
  String note = AppConstants.EMPTY_TEXT;

  int noteDurationSeconds = 3;
  int silenceSeconds = 1;
  bool intermittentPlayback = false;
  bool professionalMode = false;
  Timer? _noteTimer;
  int _noteGeneration = 0;
  final NotePlayer notePlayer;

  Future<void> _loadSampleRate() async {
    final preferences = await SharedPreferences.getInstance();
    final sampleRateValue = preferences.getInt('tuner.sampleRate');
    final lineThicknessValue = preferences.getDouble('tuner.lineThickness');
    final graphFillDurationValue = preferences.getDouble(
      'tuner.graphFillDuration',
    );
    final durationValue = preferences.getInt('tuner.noteDurationSeconds');
    final silenceValue = preferences.getInt('tuner.silenceSeconds');
    if (_disposed) return;
    if (sampleRateValue != null &&
        sampleRateValue >= 8000 &&
        sampleRateValue <= 192000) {
      sampleRate = sampleRateValue;
    }
    if (lineThicknessValue != null &&
        lineThicknessValue >= 1 &&
        lineThicknessValue <= 3) {
      lineThickness = lineThicknessValue;
    }
    if (graphFillDurationValue != null &&
        graphFillDurationValue >= 0.1 &&
        graphFillDurationValue <= 30) {
      graphFillDuration = graphFillDurationValue;
    }
    if (durationValue != null && durationValue >= 1 && durationValue <= 60) {
      noteDurationSeconds = durationValue;
    }
    if (silenceValue != null && silenceValue >= 1 && silenceValue <= 10) {
      silenceSeconds = silenceValue;
    }
    intermittentPlayback =
        preferences.getBool('tuner.intermittentPlayback') ?? false;
    professionalMode = preferences.getBool('tuner.professionalMode') ?? false;
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
    final normalized = value.clamp(1.0, 3.0).toDouble();
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

  Future<void> setNoteDuration(int seconds) async {
    await _sampleRateLoaded;
    noteDurationSeconds = seconds.clamp(1, 60);
    notifyListeners();
    await _saveInt('tuner.noteDurationSeconds', noteDurationSeconds);
  }

  Future<void> setSilenceSeconds(int seconds) async {
    await _sampleRateLoaded;
    silenceSeconds = seconds.clamp(1, 10);
    notifyListeners();
    await _saveInt('tuner.silenceSeconds', silenceSeconds);
  }

  Future<void> _saveInt(String key, int value) async {
    await (await SharedPreferences.getInstance()).setInt(key, value);
  }

  Future<void> setIntermittentPlayback(bool value) async {
    await _sampleRateLoaded;
    if (intermittentPlayback == value) return;
    await stopNote();
    intermittentPlayback = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool(
      'tuner.intermittentPlayback',
      value,
    );
  }

  Future<void> setProfessionalMode(bool value) async {
    await _sampleRateLoaded;
    if (professionalMode == value) return;
    await stopNote();
    if (value) await stop();
    professionalMode = value;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool(
      'tuner.professionalMode',
      value,
    );
    if (!value) await start();
  }

  void setA4(double frequencyBase) {
    a4 = frequencyBase;
    notifyListeners();
  }

  Future<void> playNote(double freq) async {
    final generation = ++_noteGeneration;
    _noteTimer?.cancel();
    _noteTimer = null;
    await _playCycle(freq, generation, 1);
  }

  Future<void> _playCycle(double freq, int generation, int cycle) async {
    if (_disposed || generation != _noteGeneration) return;
    await notePlayer.play(freq, noteDurationSeconds);
    if (_disposed || generation != _noteGeneration || !professionalMode) return;
    _noteTimer = Timer(Duration(seconds: noteDurationSeconds), () async {
      if (_disposed || generation != _noteGeneration) return;
      await notePlayer.stop();
      if (_disposed || generation != _noteGeneration || cycle >= 10) return;
      _noteTimer = Timer(
        Duration(seconds: intermittentPlayback ? silenceSeconds : 0),
        () => unawaited(_playCycle(freq, generation, cycle + 1)),
      );
    });
  }

  Future<void> stopNote() async {
    ++_noteGeneration;
    _noteTimer?.cancel();
    _noteTimer = null;
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

  Future<void> start() async {
    await _sampleRateLoaded;
    if (_disposed || professionalMode) return;
    _requested = true;
    await _reconcile();
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
            _pauseMeasurement();
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
              _pauseMeasurement();
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
    unawaited(stopNote());
    super.dispose();
  }

  void _onPitchDetected(dynamic result) {
    final freq = (result[AppConstants.FREQUENCY] ?? 0).toDouble();
    if (_disposed) return;
    if (!freq.isFinite || freq < 25 || freq > 5000) {
      _pauseMeasurement();
      return;
    }
    hasSignal = true;
    frequency = freq;

    final analyzed = analyzePitch(freq);
    note = analyzed.note;
    noteFreq = analyzed.targetFreq;

    notifyListeners();
  }

  void _pauseMeasurement() {
    if (_disposed || !hasSignal) return;
    hasSignal = false;
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
