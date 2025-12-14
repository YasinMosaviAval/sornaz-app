import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScanCacheService {
  static const _key = 'audio_scan_cache';

  static Future<Map<String, int>> loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};

    final Map<String, dynamic> decoded = jsonDecode(raw);
    return decoded.map((k, v) => MapEntry(k, v as int));
  }

  static Future<void> saveCache(Map<String, int> cache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(cache));
  }
}
