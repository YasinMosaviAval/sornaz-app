import 'dart:async';
import 'package:flutter/foundation.dart';
import 'audio.dart';
import 'models.dart';
import 'progress.dart';
import 'access.dart';
import 'settings.dart';
import 'results.dart';

class IntervalTrainingController extends ChangeNotifier {
  IntervalTrainingController({
    required int levelNumber,
    required this.audio,
    required this.store,
    required this.progress,
    IntervalQuestionGenerator? generator,
    this.feedbackDuration = IntervalAudioTiming.feedback,
    this.access = const IntervalAccess(),
    this.music = IntervalMusic.western,
    this.settings,
    IntervalResultJournal? journal,
    this.onResultSaved,
  }) : generator = generator ?? IntervalQuestionGenerator(),
       journal =
           journal ??
           (store is IntervalProgressRepository ? store.journal : null),
       level = IntervalLevel.levelsFor(music)[levelNumber - 1] {
    if (!access.canEnter(levelNumber, progress, music: music)) {
      throw ArgumentError('Locked level');
    }
    question = this.generator.generate(
      level,
      startingMidi: settings?.startingMidi ?? 60,
    );
    initializing = settings != null && !settings!.loaded;
    if (initializing) {
      settings!.ready.then((_) {
        if (_disposed || accessRevoked) return;
        question = this.generator.generate(
          level,
          startingMidi: settings!.startingMidi,
        );
        initializing = false;
        _emit();
      });
    }
  }
  final IntervalAudio audio;
  final IntervalResultJournal? journal;
  final Future<void> Function(bool force)? onResultSaved;
  String _runId = newIntervalRunId();
  int _sequence = 0;
  final _questionWatch = Stopwatch()..start();
  Map<String, dynamic>? _pendingAnswer;
  final IntervalAccess access;
  final IntervalMusic music;
  final IntervalAudioSettings? settings;
  bool initializing = false;
  bool accessRevoked = false;
  final IntervalProgressStore store;
  final IntervalQuestionGenerator generator;
  final Duration feedbackDuration;
  IntervalProgress progress;
  IntervalLevel level;
  late IntervalQuestion question;
  TrainingInterval? selected;
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

  void select(TrainingInterval interval) {
    if (_disposed ||
        accessRevoked ||
        initializing ||
        checking ||
        finished ||
        !level.intervals.contains(interval)) {
      return;
    }
    selected = interval;
    _emit();
  }

  Future<void> play() async {
    if (_disposed || accessRevoked || initializing || checking || finished) {
      return;
    }
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
    if (_disposed ||
        accessRevoked ||
        initializing ||
        checking ||
        finished ||
        selected == null) {
      return;
    }
    checking = true;
    errorKey = null;
    correct = selected == question.interval;
    _pendingAnswer = {
      'sequence': _sequence + 1,
      'expectedQuarterSteps': question.quarterSteps,
      'selectedQuarterSteps': selected!.quarterSteps,
      'rootMidi': question.rootMidi,
      'direction': question.direction.name,
      'answeredAt': DateTime.now().toUtc().toIso8601String(),
      'elapsedMs': _questionWatch.elapsedMilliseconds.clamp(0, 86400000),
    };
    _emit();
    await stopPlayback();
    if (_disposed || accessRevoked) return;
    await _recordAnswer();
  }

  void _sync({bool force = false}) {
    final callback = onResultSaved;
    if (callback != null) unawaited(callback(force).catchError((Object _) {}));
  }

  Future<void> _recordAnswer() async {
    try {
      await journal?.append(
        runId: _runId,
        level: level.number,
        answer: _pendingAnswer!,
      );
    } catch (_) {
      if (!_disposed && !accessRevoked) {
        errorKey = 'interval.resultSaveError';
        transitioning = false;
        _emit();
      }
      return;
    }
    if (_disposed || accessRevoked) return;
    _sequence++;
    wins = correct! ? wins + 1 : 0;
    errorKey = null;
    _emit();
    _sync(force: wins == IntervalLevel.requiredWins);
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
    final updated = progress.complete(level.number, runId: _runId);
    try {
      await store.save(updated);
      if (_disposed || accessRevoked) return;
      progress = updated;
      errorKey = null;
      _emit();
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
    if (_disposed ||
        accessRevoked ||
        ![
          'interval.saveError',
          'interval.resultSaveError',
        ].contains(errorKey) ||
        transitioning) {
      return;
    }
    transitioning = true;
    _emit();
    if (errorKey == 'interval.resultSaveError') {
      await _recordAnswer();
    } else {
      await _saveCompletion();
    }
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(feedbackDuration, () {
      if (_disposed || accessRevoked) return;
      if (wins == IntervalLevel.requiredWins) {
        if (level.number == music.levelCount) {
          finished = true;
          checking = false;
          transitioning = false;
          _emit();
          return;
        }
        level = IntervalLevel.levelsFor(music)[level.number];
        wins = 0;
        _runId = newIntervalRunId();
        _sequence = 0;
      }
      selected = null;
      correct = null;
      checking = false;
      transitioning = false;
      completedLevel = null;
      _pendingAnswer = null;
      _questionWatch
        ..reset()
        ..start();
      question = generator.generate(
        level,
        startingMidi: settings?.startingMidi ?? 60,
      );
      _emit();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    ++_playGeneration;
    _timer?.cancel();
    _closeRun();
    unawaited(audio.dispose().catchError((Object _) {}));
    super.dispose();
  }

  void revokeAccess() {
    if (_disposed || accessRevoked) return;
    accessRevoked = true;
    initializing = false;
    _timer?.cancel();
    _closeRun();
    unawaited(stopPlayback());
    _emit();
  }

  void _closeRun() {
    final log = journal;
    if (log != null)
      unawaited(
        log
            .close(_runId)
            .then((_) => _sync(force: true))
            .catchError((Object _) {}),
      );
  }
}
