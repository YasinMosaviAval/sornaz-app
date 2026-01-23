import 'package:hive_flutter/hive_flutter.dart';
import 'package:sornaz/helpers/app_constants.dart';

class HiveArticlesCache {
  Box? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox(AppConstants.ARTICLES);
  }

  Future<List<Map<String, dynamic>>> loadArticles() async {
    await init();
    final data = _box!.values.toList();
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveArticles(List<Map<String, dynamic>> articles) async {
    await init();
    await _box!.clear();
    await _box!.addAll(articles);
  }

  Future<void> clearArticles() async {
    await init();
    await _box!.clear();
  }
}