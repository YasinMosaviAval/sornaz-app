import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sornaz/helpers/app_logger.dart';

class HiveArticlesCache {
  Box? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox('articles');
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
    loggingSornaz('💡 logging Sornaz ======= Saved ${articles.length} articles to Hive');
    SnackBar(content: Text("${articles.length} مقاله جدید در حافظه ذخیره شد!"));
  }

  Future<void> clearArticles() async {
    await init();
    await _box!.clear();
  }
}