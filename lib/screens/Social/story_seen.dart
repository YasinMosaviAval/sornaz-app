import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-account local view state shared by every story entry point.
class StorySeen extends ChangeNotifier {
  StorySeen._(this.account);
  final int account;
  static final Map<int, StorySeen> _stores = {};
  static StorySeen forAccount(int id) =>
      _stores.putIfAbsent(id, () => StorySeen._(id)..load());
  @visibleForTesting
  static void resetForTesting() {
    for (final store in _stores.values) {
      store.dispose();
    }
    _stores.clear();
  }

  final Set<String> ids = {};
  Future<void>? _loading;
  String get key => 'seen-stories-v1-$account';
  Future<void> load() => _loading ??= _load();
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    ids.addAll(prefs.getStringList(key) ?? []);
    notifyListeners();
  }

  Future<void> mark(int id) async {
    await load();
    if (!ids.add('$id')) return;
    while (ids.length > 2048) {
      ids.remove(ids.first);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, ids.toList());
  }
}
