import 'package:sornaz/helpers/app_constants.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class HiveArticlesCache {
  Future<Box<dynamic>> get _box => Hive.openBox<dynamic>('article_library_v2');
  Future<Map<String, dynamic>> loadSnapshot(String locale) async {
    final box = await _box;
    var raw = box.get(locale);
    if (raw == null &&
        locale == 'fa' &&
        await Hive.boxExists(AppConstants.ARTICLES)) {
      final legacy = await Hive.openBox(AppConstants.ARTICLES);
      final posts = legacy.values
          .whereType<Map>()
          .where((p) => p['id'] != null)
          .map((p) => {...Map<String, dynamic>.from(p), 'locale': 'fa'})
          .toList();
      if (posts.isNotEmpty) {
        raw = {'posts': posts, 'categories': <dynamic>[]};
        await box.put(locale, raw);
      }
    }
    return raw == null
        ? {'posts': <dynamic>[], 'categories': <dynamic>[]}
        : Map<String, dynamic>.from(jsonDecode(jsonEncode(raw)));
  }

  Future<void> saveSnapshot(
    String locale,
    Map<String, dynamic> snapshot,
  ) async {
    // One Hive record replaces the full locale snapshot atomically; never clear a usable cache first.
    await (await _box).put(locale, snapshot);
  }

  Future<List<String>> receipts(int postId) async => List<String>.from(
    (await _box).get('receipts:$postId', defaultValue: <String>[]),
  );
  Future<void> saveReceipt(int postId, String receipt) async {
    final items = await receipts(postId);
    if (!items.contains(receipt)) items.add(receipt);
    await (await _box).put('receipts:$postId', items);
  }
}
