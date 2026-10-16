import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class IntervalProgress {
  IntervalProgress({
    Set<int> completed = const {},
    Set<int>? unlocked,
    this.music = IntervalMusic.western,
  }) : completed = Set.unmodifiable(
         completed.where((n) => n >= 1 && n <= music.levelCount),
       ),
       unlocked = Set.unmodifiable({
         1,
         ...?unlocked?.where((n) => n >= 1 && n <= music.levelCount),
       });
  final IntervalMusic music;
  bool _valid(int level) => level >= 1 && level <= music.levelCount;
  final Set<int> completed;
  final Set<int> unlocked;
  int get highestUnlocked {
    var level = 1;
    while (level < music.levelCount && completed.contains(level)) {
      level++;
    }
    return level;
  }

  bool isUnlocked(int level) =>
      _valid(level) &&
      (level <= highestUnlocked ||
          completed.contains(level) ||
          unlocked.contains(level));
  IntervalProgress complete(int level) {
    if (!_valid(level)) throw ArgumentError.value(level, 'level');
    return IntervalProgress(
      music: music,
      completed: {...completed, level},
      unlocked: {...unlocked, level, if (level < music.levelCount) level + 1},
    );
  }
}

abstract class IntervalProgressStore {
  Future<IntervalProgress> load();
  Future<void> save(IntervalProgress progress);
}

/// Legacy definitions are immutable migration metadata, not active levels.
class IntervalProgressMigration {
  static const legacyGroups = [
    [MusicalInterval.perfectFifth, MusicalInterval.perfectOctave],
    [
      MusicalInterval.minorThird,
      MusicalInterval.majorThird,
      MusicalInterval.perfectFifth,
      MusicalInterval.perfectOctave,
    ],
    [
      MusicalInterval.majorSecond,
      MusicalInterval.perfectFourth,
      MusicalInterval.majorSixth,
      MusicalInterval.majorSeventh,
    ],
    [
      MusicalInterval.minorSecond,
      MusicalInterval.tritone,
      MusicalInterval.augmentedFifth,
      MusicalInterval.minorSeventh,
    ],
    MusicalInterval.values,
  ];
  static Set<int> exactMatches(Set<int> legacyCompleted) {
    final mapped = <int>{};
    for (final number in legacyCompleted.where((n) => n >= 1 && n <= 20)) {
      final i = number - 1;
      final intervals = legacyGroups[i ~/ 4].toSet();
      final direction = i.isEven
          ? IntervalDirection.ascending
          : IntervalDirection.descending;
      for (final level in IntervalLevel.all) {
        if (level.direction == direction &&
            level.variableRoot == (i % 4 >= 2) &&
            level.intervals.length == intervals.length &&
            intervals.containsAll(level.intervals)) {
          mapped.add(level.number);
        }
      }
    }
    return mapped;
  }
}

class IntervalProgressRepository implements IntervalProgressStore {
  IntervalProgressRepository({this.userId, this.music = IntervalMusic.western});
  final IntervalMusic music;
  final int? userId;

  /// Retained untouched: legacy records have no owner information.
  static const key = 'solfege.interval.progress.v1';
  String get scopedKey =>
      'solfege.interval.${music.name}.progress.v2.${userId == null ? 'guest' : 'user.$userId'}';
  static final Map<String, Future<void>> _queues = {};
  Future<T> _locked<T>(Future<T> Function() operation) {
    final previous = _queues[scopedKey] ?? Future<void>.value();
    final gate = Completer<void>();
    _queues[scopedKey] = gate.future;
    return previous.then((_) async {
      try {
        return await operation();
      } finally {
        if (identical(_queues[scopedKey], gate.future)) {
          _queues.remove(scopedKey);
        }
        gate.complete();
      }
    });
  }

  static Set<int> _numbers(Object? raw) =>
      raw is List ? raw.whereType<int>().toSet() : {};
  @override
  Future<IntervalProgress> load() => _locked(() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(scopedKey);
    if (raw != null) {
      try {
        final record = jsonDecode(raw) as Map<String, dynamic>;
        if (record['schema'] != 2) return IntervalProgress(music: music);
        return IntervalProgress(
          music: music,
          completed: _numbers(record['completed']),
          unlocked: _numbers(record['unlocked']),
        );
      } on FormatException {
        return IntervalProgress(music: music);
      } on TypeError {
        return IntervalProgress(music: music);
      }
    }
    var progress = IntervalProgress(music: music);
    // Unowned legacy data is never assigned to an authenticated account.
    if (userId == null && music == IntervalMusic.western) {
      try {
        final old = prefs.getString(key);
        if (old != null) {
          progress = IntervalProgress(
            music: music,
            completed: IntervalProgressMigration.exactMatches(
              _numbers(jsonDecode(old)),
            ),
          );
        }
      } on FormatException {
        /* Leave the original data untouched. */
      }
    }
    await _write(prefs, progress);
    return progress;
  });
  Future<void> _write(
    SharedPreferences prefs,
    IntervalProgress progress,
  ) async {
    if (progress.music != music) {
      throw ArgumentError('Progress branch mismatch');
    }
    final ok = await prefs.setString(
      scopedKey,
      jsonEncode({
        'schema': 2,
        'completed': progress.completed.toList()..sort(),
        'unlocked': progress.unlocked.toList()..sort(),
        'legacyMigration': music == IntervalMusic.iranian
            ? 'not-applicable'
            : userId == null
            ? 'exact-matches-unowned'
            : 'unowned-legacy-not-assigned',
      }),
    );
    if (!ok) throw StateError('Progress could not be saved');
  }

  @override
  Future<void> save(IntervalProgress progress) => _locked(() async {
    await _write(await SharedPreferences.getInstance(), progress);
  });
}
