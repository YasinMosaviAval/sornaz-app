import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Timestamp metadata follows the recording from staging to its public URI.
/// A single queue prevents rapid taps or migration from losing other edits.
class RecordingBookmarks {
  static Future<void> _writes = Future.value();
  static const _key = 'recording.bookmarks.v1';
  Future<Map<String, dynamic>> _read(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    final value = jsonDecode(raw);
    return Map<String, dynamic>.from(value as Map);
  }

  List<int> _times(dynamic value) => value is List
      ? (value
            .whereType<num>()
            .map((n) => n.toInt())
            .where((n) => n >= 0)
            .toSet()
            .toList()
          ..sort())
      : [];
  Future<List<int>> load(String uri) async {
    await _writes;
    final prefs = await SharedPreferences.getInstance();
    return _times((await _read(prefs))[uri]);
  }

  Future<void> _change(void Function(Map<String, dynamic>) update) {
    final next = _writes.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final all = await _read(prefs);
      update(all);
      if (!await prefs.setString(_key, jsonEncode(all))) {
        throw StateError('Could not save recording bookmarks');
      }
    });
    _writes = next.catchError((Object _) {});
    return next;
  }

  Future<void> add(String uri, int milliseconds) => _change((all) {
    final times = _times(all[uri]);
    if (milliseconds >= 0 && !times.contains(milliseconds))
      times.add(milliseconds);
    times.sort();
    all[uri] = times;
  });
  Future<void> remove(String uri, int milliseconds) => _change((all) {
    all[uri] = _times(all[uri])..remove(milliseconds);
  });
  Future<void> delete(String uri) => _change((all) => all.remove(uri));
  Future<void> move(String from, String to) => _change((all) {
    if (from == to || !all.containsKey(from)) return;
    all[to] = {..._times(all[to]), ..._times(all[from])}.toList()..sort();
    all.remove(from);
  });
}
