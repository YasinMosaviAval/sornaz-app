import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicPlaylists extends ChangeNotifier {
  MusicPlaylists({this.storagePrefix = 'music'});
  final String storagePrefix;
  static final instance = MusicPlaylists();
  static final recordings = MusicPlaylists(storagePrefix: 'recording');
  final Map<String, List<String>> _lists = {};
  static const favorite = 'favorite';
  Future<void>? _loading;
  Future<void> _writes = Future.value();
  Map<String, List<String>> get lists => {
    for (final e in _lists.entries) e.key: List.unmodifiable(e.value),
  };
  Future<void> load() => _loading ??= _load();
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value =
          jsonDecode(prefs.getString('$storagePrefix.playlists') ?? '{}')
              as Map<String, dynamic>;
      for (final e in value.entries) {
        if (e.value is List)
          _lists[e.key] = (e.value as List)
              .whereType<String>()
              .toSet()
              .toList();
      }
    } catch (_) {}
    _lists[favorite] = (prefs.getStringList('$storagePrefix.favorites') ?? [])
        .toSet()
        .toList();
    notifyListeners();
  }

  Future<void> _save() {
    final custom = jsonEncode({
      for (final e in _lists.entries)
        if (e.key != favorite) e.key: e.value,
    });
    final favorites = List<String>.from(_lists[favorite] ?? []);
    final next = _writes.catchError((Object _) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$storagePrefix.playlists', custom);
      await prefs.setStringList('$storagePrefix.favorites', favorites);
    });
    _writes = next;
    notifyListeners();
    return next;
  }

  Future<String?> create(String name) async {
    await load();
    name = name.trim();
    if (name.isEmpty || name.length > 80) return null;
    if (name.toLowerCase() == 'favorite' || name == 'علاقه‌مندی')
      return favorite;
    for (final key in _lists.keys) {
      if (key.toLowerCase() == name.toLowerCase()) return key;
    }
    _lists[name] = [];
    await _save();
    return name;
  }

  Future<void> add(String key, Iterable<String> paths) async {
    await load();
    if (!_lists.containsKey(key)) return;
    _lists[key] = {..._lists[key]!, ...paths}.toList();
    await _save();
  }

  Future<bool> rename(String key, String name) async {
    await load();
    name = name.trim();
    if (key == favorite ||
        !_lists.containsKey(key) ||
        name.isEmpty ||
        name.length > 80 ||
        name == 'علاقه‌مندی' ||
        _lists.keys.any(
          (k) => k != key && k.toLowerCase() == name.toLowerCase(),
        ))
      return false;
    final entries = _lists.entries.toList();
    _lists.clear();
    for (final entry in entries) {
      _lists[entry.key == key ? name : entry.key] = entry.value;
    }
    await _save();
    return true;
  }

  Future<void> delete(String key) async {
    await load();
    if (key == favorite) return;
    _lists.remove(key);
    await _save();
  }

  Future<void> remove(String key, String path) async {
    await load();
    _lists[key]?.remove(path);
    await _save();
  }

  Future<void> replacePath(String before, String? after) async {
    await load();
    for (final key in _lists.keys.toList()) {
      _lists[key] = _lists[key]!
          .expand(
            (p) => p != before
                ? [p]
                : after == null
                ? <String>[]
                : [after],
          )
          .toSet()
          .toList();
    }
    await _save();
  }
}
