import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'equalizer_presets.dart';

class EqualizerSettings extends ChangeNotifier {
  static const frequencies5 = <double>[60, 230, 910, 3600, 14000];
  static const frequencies10 = <double>[
    31,
    62,
    125,
    250,
    500,
    1000,
    2000,
    4000,
    8000,
    16000,
  ];
  static const channel = MethodChannel('sornaz/music_equalizer');
  final Future<void> Function(Map<String, Object>)? applyOverride;
  EqualizerSettings({this.applyOverride});
  bool enabled = true, ready = false;
  int bands = 5;
  String selected = 'Custom';
  String? error;
  final custom = <int, List<double>>{
    5: List.filled(5, 0),
    10: List.filled(10, 0),
  };
  int? _session;
  Future<void>? _loading;
  Future<void> _pending = Future.value();
  bool _disposed = false;
  List<double> get frequencies => bands == 5 ? frequencies5 : frequencies10;
  List<double> get gains => List.unmodifiable(
    selected == 'Custom'
        ? custom[bands]!
        : equalizerPresets[selected]![bands == 5 ? 0 : 1],
  );
  void changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() => _loading ??= _load();
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('music_equalizer_v2');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        enabled = data['enabled'] == true;
        bands = data['bands'] == 10 ? 10 : 5;
        final name = data['selected'];
        selected = equalizerPresets.containsKey(name)
            ? name as String
            : 'Custom';
        for (final n in [5, 10]) {
          final values = data['custom$n'];
          if (values is List &&
              values.length == n &&
              values.every((v) => v is num && v.isFinite)) {
            custom[n] = values
                .map((v) => (v as num).toDouble().clamp(-15.0, 15.0))
                .toList();
          }
        }
      }
    } catch (_) {
      error = 'load';
    }
    ready = true;
    changed();
  }

  Future<void> attach(int? session) async {
    _session = session;
    await load();
    if (_disposed) return;
    await _commit(persist: false);
  }

  Future<void> setEnabled(bool value) {
    enabled = value;
    return _commit();
  }

  Future<void> select(String value) {
    if (value != 'Custom' && !equalizerPresets.containsKey(value)) {
      throw ArgumentError(value);
    }
    selected = value;
    return _commit();
  }

  Future<void> setBands(int value) {
    if (value != 5 && value != 10) throw ArgumentError(value);
    bands = value;
    return _commit();
  }

  Future<void> setGain(int index, double value) {
    final next = gains.toList();
    next[index] = value.clamp(-15.0, 15.0);
    custom[bands] = next;
    selected = 'Custom';
    return _commit();
  }

  Future<void> reset() {
    custom[bands] = List.filled(bands, 0);
    selected = 'Custom';
    return _commit();
  }

  Future<void> _commit({bool persist = true}) {
    changed();
    final state = jsonEncode({
      'enabled': enabled,
      'bands': bands,
      'selected': selected,
      'custom5': custom[5],
      'custom10': custom[10],
    });
    final payload = <String, Object>{
      'enabled': enabled,
      'frequencies': frequencies,
      'gains': gains,
    };
    final session = _session;
    _pending = _pending
        .then((_) async {
          if (_disposed) return;
          if (persist) {
            final prefs = await SharedPreferences.getInstance();
            if (!await prefs.setString('music_equalizer_v2', state)) {
              throw StateError('save');
            }
          }
          if (applyOverride != null) {
            await applyOverride!(payload);
          } else if (!kIsWeb &&
              defaultTargetPlatform == TargetPlatform.android &&
              session != null &&
              session > 0 &&
              session == _session) {
            await channel.invokeMethod<void>('apply', {
              ...payload,
              'session': session,
            });
          }
          error = null;
          changed();
        })
        .catchError((Object e) {
          error = e.toString();
          changed();
        });
    return _pending;
  }

  @override
  void dispose() {
    _disposed = true;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _pending
          .then((_) => channel.invokeMethod<void>('release'))
          .catchError((Object _) {});
    }
    super.dispose();
  }
}
