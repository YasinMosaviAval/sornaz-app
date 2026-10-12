import 'dart:async';
import 'package:flutter/foundation.dart';
import 'audio.dart';
import 'models.dart';
import 'progress.dart';

class IntervalTrainingController extends ChangeNotifier {
  IntervalTrainingController({
    required int levelNumber,
    required this.audio,
    required this.store,
    required this.progress,
    IntervalQuestionGenerator? generator,
    this.feedbackDuration = IntervalAudioTiming.feedback,
  }) : generator = generator ?? IntervalQuestionGenerator(),
       level = IntervalLevel.all[levelNumber - 1] {
    if (!progress.isUnlocked(levelNumber)) throw ArgumentError('Locked level');
    question = this.generator.generate(level);
  }
  final IntervalAudio audio;
  final IntervalProgressStore store;
  final IntervalQuestionGenerator generator;
  final Duration feedbackDuration;
  IntervalProgress progress;
  IntervalLevel level;
  late IntervalQuestion question;
  MusicalInterval? selected;
  int wins = 0;
  bool playing = false;
  bool checking = false;
  bool transitioning = false;
  bool finished = false;
  bool? correct;
  String? errorKey;
  int? completedLevel;
  Timer? _timer;
  bool _disposed = false;
  int _playGeneration = 0;

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void select(MusicalInterval interval) {
    if (_disposed ||
        checking ||
        finished ||
        !level.intervals.contains(interval)) {
      return;
    }
    selected = interval;
    _emit();
  }

  Future<void> play() async {
    if (_disposed || checking || finished) return;
    final generation = ++_playGeneration;
    playing = true;
    errorKey = null;
    _emit();
    try {
      // Serialize stopping before restarting the same question. Stale taps
      // cannot start a voice after the most recent tap or an answer check.
      await audio.stop();
      if (_disposed || generation != _playGeneration) return;
      await audio.play(question);
    } catch (_) {
      if (!_disposed && generation == _playGeneration) {
        errorKey = 'interval.audioError';
      }
    } finally {
      if (!_disposed && generation == _playGeneration) {
        playing = false;
        _emit();
      }
    }
  }

  Future<void> stopPlayback() async {
    ++_playGeneration;
    playing = false;
    try {
      await audio.stop();
    } catch (_) {
      if (!_disposed) errorKey = 'interval.audioError';
    }
    _emit();
  }

  Future<void> check() async {
    if (_disposed || checking || finished || selected == null) return;
    checking = true;
    errorKey = null;
    correct = selected == question.interval;
    wins = correct! ? wins + 1 : 0;
    _emit();
    await stopPlayback();
    if (_disposed) return;
    if (wins == IntervalLevel.requiredWins) {
      transitioning = true;
      completedLevel = level.number;
      _emit();
      await _saveCompletion();
    } else {
      _scheduleNext();
    }
  }

  Future<void> _saveCompletion() async {
    final updated = progress.complete(level.number);
    try {
      await store.save(updated);
      if (_disposed) return;
      progress = updated;
      errorKey = null;
      _scheduleNext();
    } catch (_) {
      if (!_disposed) {
        errorKey = 'interval.saveError';
        transitioning = false;
        _emit();
      }
    }
  }

  Future<void> retrySave() async {
    if (_disposed || errorKey != 'interval.saveError' || transitioning) return;
    transitioning = true;
    _emit();
    await _saveCompletion();
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(feedbackDuration, () {
      if (_disposed) return;
      if (wins == IntervalLevel.requiredWins) {
        if (level.number == 20) {
          finished = true;
          checking = false;
          transitioning = false;
          _emit();
          return;
        }
        level = IntervalLevel.all[level.number];
        wins = 0;
      }
      selected = null;
      correct = null;
      checking = false;
      transitioning = false;
      completedLevel = null;
      question = generator.generate(level);
      _emit();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    ++_playGeneration;
    _timer?.cancel();
    unawaited(audio.dispose().catchError((Object _) {}));
    super.dispose();
  }
}
