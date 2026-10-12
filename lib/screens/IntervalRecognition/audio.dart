import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'models.dart';
import 'settings.dart';

abstract class IntervalAudio {
  Future<void> play(IntervalQuestion question);
  Future<void> stop();
  Future<void> dispose();
}

class IntervalAudioTiming {
  static const gap = Duration(milliseconds: 150);
  static const feedback = Duration(seconds: 1);
  static const releaseStep = Duration(milliseconds: 10);
}

/// A narrow adapter makes sample choice and timing testable without a device.
abstract class IntervalSampleOutput {
  Future<void> start(String asset);
  Future<void> volume(double value);
  Future<void> stop();
  Future<void> dispose();
}

class _PlayerOutput implements IntervalSampleOutput {
  final AudioPlayer _player = AudioPlayer();
  @override
  Future<void> start(String asset) async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(1);
    await _player.play(AssetSource(asset));
  }

  @override
  Future<void> volume(double value) => _player.setVolume(value);
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> dispose() => _player.dispose();
}

/// One voice, with an immutable settings snapshot for each two-note replay.
class InstrumentIntervalAudio implements IntervalAudio {
  InstrumentIntervalAudio({
    required this.settings,
    IntervalSampleOutput? output,
    Future<void> Function(Duration)? delay,
  }) : _output = output ?? _PlayerOutput(),
       _delay = delay ?? Future<void>.delayed;
  final IntervalAudioSettings settings;
  final IntervalSampleOutput _output;
  final Future<void> Function(Duration) _delay;
  int _generation = 0;
  bool _disposed = false;
  Future<void> _operations = Future.value();

  Future<void> _serial(Future<void> Function() operation) {
    final next = _operations.then((_) => operation());
    _operations = next.catchError((Object _) {});
    return next;
  }

  bool _current(int generation) => !_disposed && generation == _generation;

  Future<void> _note(String asset, Duration duration, int generation) async {
    await _serial(() async {
      if (_current(generation)) await _output.start(asset);
    });
    if (!_current(generation)) return;
    await _delay(duration - IntervalAudioTiming.releaseStep * 2);
    // A short release avoids abrupt cuts on sustained string samples.
    for (final gain in [.5, .15]) {
      await _serial(() async {
        if (_current(generation)) await _output.volume(gain);
      });
      if (!_current(generation)) return;
      await _delay(IntervalAudioTiming.releaseStep);
    }
    await _serial(() async {
      if (_current(generation)) await _output.stop();
    });
  }

  @override
  Future<void> play(IntervalQuestion question) async {
    if (_disposed) return;
    final generation = ++_generation;
    await settings.ready;
    if (!_current(generation)) return;
    final instrument = settings.instrument;
    final duration = settings.noteDuration;
    try {
      await _serial(() async {
        if (_current(generation)) await _output.stop();
      });
      await _note(instrument.asset(question.rootMidi), duration, generation);
      if (!_current(generation)) return;
      await _delay(IntervalAudioTiming.gap);
      if (!_current(generation)) return;
      await _note(instrument.asset(question.targetMidi), duration, generation);
    } catch (_) {
      if (_current(generation)) await stop();
      rethrow;
    }
  }

  @override
  Future<void> stop() {
    ++_generation;
    return _serial(() async {
      if (!_disposed) await _output.stop();
    });
  }

  @override
  Future<void> dispose() {
    ++_generation;
    _disposed = true;
    return _serial(() => _output.dispose());
  }
}
