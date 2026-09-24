import '../Social/course_cache.dart';
import '../Social/social_api.dart';

/// Account-scoped conversation snapshots remain readable without connectivity.
class ChatCache {
  static String key(String token, String path) =>
      'chat-cache-v1:${CourseCache.account(token)}:$path';
  static Future<dynamic> read(String token, String path) =>
      CourseCache.read(key(token, path));
  static Future<void> write(String token, String path, dynamic value) =>
      CourseCache.write(key(token, path), value);
  static Future<void> remove(String token, String path) =>
      CourseCache.remove(key(token, path));
  static bool mayUseOffline(Object error) =>
      error is! SocialException ||
      error.status == 0 ||
      error.status == 429 ||
      error.status >= 500;
}
