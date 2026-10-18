import 'dart:async';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'models.dart';

/// Each answer is an independent durable record, so long practice sessions do
/// not rewrite their entire history on every answer. Metadata is recoverable.
class IntervalResultJournal {
  IntervalResultJournal({required this.music, this.userId});
  final IntervalMusic music;
  final int? userId;
  String get prefix =>
      '${userId == null ? 'guest' : 'user.$userId'}.${music.name}.';
  static Future<void> _queue = Future.value();
  Future<Box<String>> get _box =>
      Hive.openBox<String>('solfege_interval_results_v1');
  Future<T> _locked<T>(Future<T> Function() operation) {
    final task = _queue.then((_) => operation());
    _queue = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }

  Map<String, dynamic> _decode(String value) =>
      Map<String, dynamic>.from(jsonDecode(value) as Map);
  List<String> _keys(Box<String> box) => box.keys
      .whereType<String>()
      .where(
        (key) =>
            key.startsWith(prefix) &&
            RegExp(r'^[a-f0-9]{32}$').hasMatch(key.substring(prefix.length)),
      )
      .toList();

  void _apply(Map<String, dynamic> run, Map<String, dynamic> answer) {
    run['answerCount'] = answer['sequence'];
    run['streak'] =
        answer['expectedQuarterSteps'] == answer['selectedQuarterSteps']
        ? (run['streak'] as int) + 1
        : 0;
    run['passed'] = (run['streak'] as int) >= IntervalLevel.requiredWins;
    if (run['passed'] == true) run['closed'] = true;
  }

  Future<Map<String, dynamic>> _restore(Box<String> box, String key) async {
    final run = _decode(box.get(key)!);
    var changed = false;
    // Repair an answer durably written before its metadata write was interrupted.
    while (box.containsKey('$key.answer.${(run['answerCount'] as int) + 1}')) {
      final answer = _decode(
        box.get('$key.answer.${(run['answerCount'] as int) + 1}')!,
      );
      _apply(run, answer);
      changed = true;
    }
    if (changed) {
      await box.put(key, jsonEncode(run));
      await box.flush();
    }
    return run;
  }

  Future<void> append({
    required String runId,
    required int level,
    required Map<String, dynamic> answer,
  }) => _locked(() async {
    final box = await _box;
    final key = '$prefix$runId';
    if (!box.containsKey(key)) {
      await box.put(
        key,
        jsonEncode({
          'id': runId,
          'music': music.name,
          'level': level,
          'version': 1,
          'mode': 'practice',
          'startedAt': answer['answeredAt'],
          'answerCount': 0,
          'streak': 0,
          'passed': false,
          'syncedSequence': 0,
          'closed': false,
          'syncedClosed': false,
        }),
      );
    }
    final run = await _restore(box, key);
    if (run['level'] != level) throw StateError('Run level mismatch');
    final sequence = answer['sequence'] as int;
    if (sequence <= (run['answerCount'] as int)) {
      if (box.get('$key.answer.$sequence') != jsonEncode(answer))
        throw StateError('Answer conflict');
      return;
    }
    if (sequence != (run['answerCount'] as int) + 1 || run['closed'] == true)
      throw StateError('Invalid answer sequence');
    await box.put('$key.answer.$sequence', jsonEncode(answer));
    _apply(run, answer);
    await box.put(key, jsonEncode(run));
    await box.flush();
  });
  Future<void> close(String runId) => _locked(() async {
    final box = await _box;
    final key = '$prefix$runId';
    if (!box.containsKey(key)) return;
    final run = await _restore(box, key);
    run['closed'] = true;
    await box.put(key, jsonEncode(run));
    await box.flush();
  });
  Future<List<Map<String, dynamic>>> runs({bool pendingOnly = false}) =>
      _locked(() async {
        final box = await _box;
        final result = <Map<String, dynamic>>[];
        for (final key in _keys(box)) {
          final run = await _restore(box, key);
          if (run['answerCount'] == 0) continue;
          final offset = pendingOnly ? run['syncedSequence'] as int : 0;
          if (pendingOnly &&
              offset == run['answerCount'] &&
              (run['closed'] != true || run['syncedClosed'] == true))
            continue;
          result.add({
            ...run,
            'answerOffset': offset,
            'answers': [
              for (var i = offset + 1; i <= (run['answerCount'] as int); i++)
                _decode(box.get('$key.answer.$i')!),
            ],
          });
        }
        return result;
      });
  Future<Map<String, int>> awards() => _locked(() async {
    final box = await _box;
    final awards = <String, int>{};
    for (final key in _keys(box)) {
      final run = await _restore(box, key);
      if (run['passed'] == true) awards['${run['id']}'] = run['level'] as int;
    }
    return awards;
  });
  Future<void> acknowledge(String runId, int sequence, bool closed) =>
      _locked(() async {
        final box = await _box;
        final key = '$prefix$runId';
        final run = await _restore(box, key);
        if (sequence < (run['syncedSequence'] as int) ||
            sequence > (run['answerCount'] as int))
          throw StateError('Invalid acknowledgement');
        run['syncedSequence'] = sequence;
        if (closed) run['syncedClosed'] = true;
        await box.put(key, jsonEncode(run));
        await box.flush();
      });
}
