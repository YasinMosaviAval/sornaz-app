import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum IntervalInstrument {
  piano('interval_piano'),
  guitar('interval_guitar'),
  violin('interval_violin'),
  viola('interval_viola'),
  cello('interval_cello');

  const IntervalInstrument(this.assetFolder);
  final String assetFolder;
  String get translationKey => 'interval.instrument.$name';
  String asset(int midi) => 'audio/$assetFolder/$midi.mp3';
}

class IntervalAudioSettings extends ChangeNotifier {
  IntervalAudioSettings({SharedPreferences? preferences})
    : _preferences = preferences {
    ready = _load();
  }
  static const key = 'solfege.interval.audioSettings.v1';
  static const minimumDurationMs = 500;
  static const maximumDurationMs = 2000;
  static const defaultDurationMs = 1000;
  final SharedPreferences? _preferences;
  late final Future<void> ready;
  int _noteDurationMs = defaultDurationMs;
  IntervalInstrument _instrument = IntervalInstrument.piano;
  int get noteDurationMs => _noteDurationMs;
  IntervalInstrument get instrument => _instrument;
  Duration get noteDuration => Duration(milliseconds: _noteDurationMs);
  bool loaded = false;
  String? errorKey;
  bool _disposed = false;
  Future<void> _writes = Future.value();

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<SharedPreferences> _prefs() async =>
      _preferences ?? await SharedPreferences.getInstance();
  Future<void> _load() async {
    try {
      final raw = (await _prefs()).getString(key);
      if (raw != null) {
        try {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final duration = data['durationMs'];
          if (duration is int &&
              duration >= minimumDurationMs &&
              duration <= maximumDurationMs &&
              duration % 50 == 0) {
            _noteDurationMs = duration;
          }
          _instrument = IntervalInstrument.values.firstWhere(
            (value) => value.name == data['instrument'],
            orElse: () => IntervalInstrument.piano,
          );
        } on FormatException {
          /* Corrupt settings fall back to defaults. */
        } on TypeError {
          /* Corrupt settings fall back to defaults. */
        }
      }
    } catch (_) {
      errorKey = 'interval.settingsLoadError';
    }
    loaded = true;
    _emit();
  }

  Future<void> setDuration(int milliseconds) async {
    await ready;
    if (_disposed) return;
    final normalized =
        ((milliseconds.clamp(minimumDurationMs, maximumDurationMs) / 50)
            .round() *
        50);
    if (_noteDurationMs == normalized) return;
    _noteDurationMs = normalized;
    await _save();
  }

  Future<void> setInstrument(IntervalInstrument instrument) async {
    await ready;
    if (_disposed || _instrument == instrument) return;
    _instrument = instrument;
    await _save();
  }

  Future<void> retrySave() async {
    await ready;
    if (!_disposed) await _save();
  }

  Future<void> _save() {
    final encoded = jsonEncode({
      'durationMs': _noteDurationMs,
      'instrument': _instrument.name,
    });
    errorKey = null;
    _emit();
    _writes = _writes.then((_) async {
      try {
        if (!await (await _prefs()).setString(key, encoded)) {
          throw StateError('Settings write failed');
        }
        errorKey = null;
      } catch (_) {
        errorKey = 'interval.settingsSaveError';
      }
      _emit();
    });
    return _writes;
  }

  Future<void> flush() => _writes;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
