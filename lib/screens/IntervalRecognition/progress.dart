import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class IntervalProgress {
  IntervalProgress({Set<int> completed = const {}})
    : completed = Set.unmodifiable(completed);
  final Set<int> completed;
  int get highestUnlocked {
    var level = 1;
    while (level < 20 && completed.contains(level)) {
      level++;
    }
    return level;
  }

  bool isUnlocked(int level) => level >= 1 && level <= highestUnlocked;
  IntervalProgress complete(int level) =>
      IntervalProgress(completed: {...completed, level});
}

abstract class IntervalProgressStore {
  Future<IntervalProgress> load();
  Future<void> save(IntervalProgress progress);
}

class IntervalProgressRepository implements IntervalProgressStore {
  static const key = 'solfege.interval.progress.v1';
  @override
  Future<IntervalProgress> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw == null) return IntervalProgress();
    try {
      final values = jsonDecode(raw) as List;
      return IntervalProgress(
        completed: values
            .whereType<int>()
            .where((n) => n >= 1 && n <= 20)
            .toSet(),
      );
    } on FormatException {
      return IntervalProgress();
    } on TypeError {
      return IntervalProgress();
    }
  }

  @override
  Future<void> save(IntervalProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(
      key,
      jsonEncode(progress.completed.toList()..sort()),
    );
    if (!ok) throw StateError('Progress could not be saved');
  }
}
