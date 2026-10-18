import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'results.dart';

class IntervalProgress {
  IntervalProgress({
    Set<int> completed = const {},
    Set<int>? unlocked,
    Map<int, int>? stars,
    Map<String, int> awards = const {},
    this.music = IntervalMusic.western,
  }) : completed = Set.unmodifiable(
         {
           ...completed,
           ...?stars?.keys.where((n) => stars[n]! > 0),
           ...awards.entries
               .where((entry) => RegExp(r'^[a-f0-9]{32}$').hasMatch(entry.key))
               .map((entry) => entry.value),
         }.where((n) => n >= 1 && n <= music.levelCount),
       ),
       stars = Map.unmodifiable({
         for (final entry
             in (stars ?? {for (final n in completed) n: 1}).entries)
           if (entry.key >= 1 &&
               entry.key <= music.levelCount &&
               entry.value > 0)
             entry.key: entry.value.clamp(0, 5),
       }),
       awards = Map.unmodifiable({
         for (final entry in awards.entries)
           if (RegExp(r'^[a-f0-9]{32}$').hasMatch(entry.key) &&
               entry.value >= 1 &&
               entry.value <= music.levelCount)
             entry.key: entry.value,
       }),
       unlocked = Set.unmodifiable({
         1,
         for (final entry in awards.entries)
           if (RegExp(r'^[a-f0-9]{32}$').hasMatch(entry.key) &&
               entry.value >= 1 &&
               entry.value < music.levelCount)
             entry.value + 1,
         ...?unlocked?.where((n) => n >= 1 && n <= music.levelCount),
       });
  final IntervalMusic music;
  bool _valid(int level) => level >= 1 && level <= music.levelCount;
  final Set<int> completed;
  final Set<int> unlocked;
  static const maxStars = 5;
  final Map<int, int> stars;
  final Map<String, int> awards;
  int starsFor(int level) =>
      ((stars[level] ?? 0) +
              awards.values.where((value) => value == level).length)
          .clamp(0, maxStars);
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
  IntervalProgress complete(int level, {String? runId}) {
    if (!_valid(level)) throw ArgumentError.value(level, 'level');
    if (runId != null && awards.containsKey(runId) && awards[runId] != level)
      throw ArgumentError('Award level mismatch');
    return IntervalProgress(
      music: music,
      stars: stars,
      awards: {...awards, runId ?? newIntervalRunId(): level},
      completed: {...completed, level},
      unlocked: {...unlocked, level, if (level < music.levelCount) level + 1},
    );
  }

  IntervalProgress merge(IntervalProgress other) {
    if (other.music != music) throw ArgumentError('Progress branch mismatch');
    for (final entry in other.awards.entries) {
      if (awards.containsKey(entry.key) && awards[entry.key] != entry.value)
        throw ArgumentError('Award level mismatch');
    }
    return IntervalProgress(
      music: music,
      completed: {...completed, ...other.completed},
      unlocked: {...unlocked, ...other.unlocked},
      stars: {
        for (final key in {...stars.keys, ...other.stars.keys})
          key: max(stars[key] ?? 0, other.stars[key] ?? 0),
      },
      awards: {...awards, ...other.awards},
    );
  }
}

String newIntervalRunId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
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
  IntervalProgressRepository({
    this.userId,
    this.music = IntervalMusic.western,
    this.journal,
  });
  final IntervalResultJournal? journal;
  final IntervalMusic music;
  final int? userId;

  /// Retained untouched: legacy records have no owner information.
  static const key = 'solfege.interval.progress.v1';
  String get scopedKey =>
      'solfege.interval.${music.name}.progress.v3.${userId == null ? 'guest' : 'user.$userId'}';
  String get legacyScopedKey =>
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
    final raw = prefs.getString(scopedKey) ?? prefs.getString(legacyScopedKey);
    if (raw != null) {
      try {
        final record = jsonDecode(raw) as Map<String, dynamic>;
        if (![2, 3].contains(record['schema']))
          return IntervalProgress(music: music);
        final progress = IntervalProgress(
          music: music,
          stars: record['schema'] == 3 ? _starMap(record['stars']) : null,
          awards: record['schema'] == 3 ? _awardMap(record['awards']) : {},
          completed: _numbers(record['completed']),
          unlocked: _numbers(record['unlocked']),
        );
        if (record['schema'] == 2 || !prefs.containsKey(scopedKey))
          await _write(prefs, progress);
        return await _recover(progress);
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
    return _recover(progress);
  });
  static Map<int, int> _starMap(dynamic value) => value is Map
      ? {
          for (final entry in value.entries)
            if (int.tryParse('${entry.key}') != null && entry.value is int)
              int.parse('${entry.key}'): entry.value as int,
        }
      : {};
  static Map<String, int> _awardMap(dynamic value) => value is Map
      ? {
          for (final entry in value.entries)
            if (entry.value is int) '${entry.key}': entry.value as int,
        }
      : {};
  Future<IntervalProgress> _recover(IntervalProgress progress) async {
    if (journal == null) return progress;
    final recovered = progress.merge(
      IntervalProgress(
        music: music,
        stars: const {},
        awards: await journal!.awards(),
      ),
    );
    await _write(await SharedPreferences.getInstance(), recovered);
    return recovered;
  }

  Future<void> _write(
    SharedPreferences prefs,
    IntervalProgress progress,
  ) async {
    if (progress.music != music) {
      throw ArgumentError('Progress branch mismatch');
    }
    final encoded = jsonEncode({
      'schema': 3,
      'stars': {
        for (final entry in progress.stars.entries) '${entry.key}': entry.value,
      },
      'awards': progress.awards,
      'completed': progress.completed.toList()..sort(),
      'unlocked': progress.unlocked.toList()..sort(),
      'legacyMigration': music == IntervalMusic.iranian
          ? 'not-applicable'
          : userId == null
          ? 'exact-matches-unowned'
          : 'unowned-legacy-not-assigned',
    });
    if (prefs.getString(scopedKey) == encoded) return;
    final ok = await prefs.setString(scopedKey, encoded);
    if (!ok) throw StateError('Progress could not be saved');
  }

  @override
  Future<void> save(IntervalProgress progress) => _locked(() async {
    if (progress.music != music)
      throw ArgumentError('Progress branch mismatch');
    final prefs = await SharedPreferences.getInstance();
    var combined = progress;
    try {
      final record =
          jsonDecode(
                prefs.getString(scopedKey) ??
                    prefs.getString(legacyScopedKey) ??
                    '{}',
              )
              as Map;
      if ([2, 3].contains(record['schema']))
        combined = progress.merge(
          IntervalProgress(
            music: music,
            completed: _numbers(record['completed']),
            unlocked: _numbers(record['unlocked']),
            stars: record['schema'] == 3 ? _starMap(record['stars']) : null,
            awards: _awardMap(record['awards']),
          ),
        );
    } on FormatException {
      /* Keep the valid new progress. */
    } on TypeError {
      /* Keep the valid new progress. */
    }
    await _write(prefs, combined);
  });
}
