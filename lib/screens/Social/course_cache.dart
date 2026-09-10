import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourseCache {
  static final revisions = ValueNotifier<int>(0);
  static final Map<String, DateTime> checked = {};
  static String account(String token) {
    try {
      return '${jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(token.split('.').first))))['sub']}';
    } catch (_) {
      return token.isEmpty ? 'guest' : base64Url.encode(utf8.encode(token));
    }
  }

  static String key(String token, String locale, String path) =>
      'course-cache-v1:${account(token)}:$locale:$path';
  static Future<dynamic> read(String key) async {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(value);
    checked[key] = DateTime.now();
    if (prefs.getString(key) == raw) return;
    await prefs.setString(key, raw);
    revisions.value++;
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(key)) return;
    await prefs.remove(key);
    checked.remove(key);
    revisions.value++;
  }
}
