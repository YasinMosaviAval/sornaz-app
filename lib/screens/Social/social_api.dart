import 'dart:async';
import 'dart:convert';
import 'course_cache.dart';
import 'package:sornaz/helpers/user_facing_error.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

typedef Json = Map<String, dynamic>;
int number(dynamic value) => int.tryParse('$value') ?? 0;
Json object(dynamic value) => (value as Map).cast<String, dynamic>();
List<Json> objects(dynamic value) => (value as List).map(object).toList();

class SocialException implements Exception {
  const SocialException(this._message, [this.status = 0]);
  final String _message;
  String get message => userFacingError(_message);
  final int status;
  @override
  String toString() => userFacingError(message);
}

class SocialApi {
  SocialApi(this.token, {http.Client? client})
    : _client = client ?? http.Client();
  static String locale = 'fa';
  final String token;
  final http.Client _client;
  static const base = String.fromEnvironment(
    'Sornaz_API_BASE_URL',
    defaultValue: 'https://sornaz.com/api/sornaz/v1',
  );
  Map<String, String> get headers => {
    if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Accept-Language': locale,
  };
  Uri uri(String path) =>
      Uri.parse('${base.replaceFirst(RegExp(r'/$'), '')}/social$path');
  String media(String path) {
    if (path.startsWith('/course-market/media/')) {
      return uri('/course-media/${path.split('/').last}').toString();
    }
    final value = Uri.parse(base).resolve(path);
    if (value.origin != Uri.parse(base).origin) {
      throw const SocialException('آدرس رسانه معتبر نیست.');
    }
    return value.toString();
  }

  String courseMedia(dynamic id) =>
      uri('/course-media/${number(id)}').toString();
  final Map<String, Future<dynamic>> _pending = {};
  bool _prefetching = false, _disposed = false;
  Future<void> _prefetch(dynamic value) async {
    if (_prefetching || _disposed) return;
    final rows = value is List
        ? value
        : value is Map
        ? value['courses']
        : null;
    if (rows is! List) return;
    _prefetching = true;
    try {
      for (final row in rows.whereType<Map>()) {
        if (_disposed) return;
        if (number(row['id']) <= 0) continue;
        final path = '/courses/${number(row['id'])}';
        final cached = await CourseCache.read(
          CourseCache.key(token, locale, path),
        );
        if (cached is Map && cached['updated_at'] == row['updated_at'])
          continue;
        try {
          await get(path, refresh: true);
        } catch (_) {
          return;
        }
      }
    } finally {
      _prefetching = false;
    }
  }

  Future<dynamic> get(String path, {bool refresh = false}) async {
    final cacheable =
        path == '/home' ||
        path == '/me' ||
        path.startsWith('/courses') ||
        path.startsWith('/catalog') ||
        path.startsWith('/lessons') ||
        path.startsWith('/people');
    final key = CourseCache.key(token, locale, path);
    final cached = cacheable ? await CourseCache.read(key) : null;
    Future<dynamic> fetch() => _pending.putIfAbsent(key, () async {
      try {
        final value = _decode(
          await _client
              .get(uri(path), headers: headers)
              .timeout(const Duration(seconds: 12)),
        );
        if (cacheable) await CourseCache.write(key, value);
        if (path == '/home' || path.startsWith('/courses?'))
          unawaited(_prefetch(value));
        return value;
      } on SocialException catch (e) {
        if (e.status == 401 || e.status == 403 || e.status == 404)
          await CourseCache.remove(key);
        rethrow;
      } catch (_) {
        throw const SocialException(
          'ارتباط با سرویس برقرار نشد. اتصال اینترنت را بررسی کنید.',
        );
      } finally {
        _pending.remove(key);
      }
    });
    if (cached != null && !refresh) {
      if (DateTime.now()
              .difference(CourseCache.checked[key] ?? DateTime(2000))
              .inSeconds >=
          15) {
        unawaited(fetch().catchError((Object _) => cached));
      }
      return cached;
    }
    return fetch();
  }

  Future<dynamic> post(
    String path, [
    Map<String, String> body = const {},
  ]) async {
    try {
      final result = _decode(
        await _client
            .post(uri(path), headers: headers, body: body)
            .timeout(const Duration(seconds: 40)),
      );
      CourseCache.checked.clear();
      CourseCache.revisions.value++;
      return result;
    } on SocialException {
      rethrow;
    } catch (_) {
      throw const SocialException(
        'عملیات انجام نشد. اتصال اینترنت را بررسی کنید.',
      );
    }
  }

  dynamic _decode(http.Response response) {
    Json result;
    try {
      result = object(jsonDecode(utf8.decode(response.bodyBytes)));
      // The PHP response factory wraps API payloads in {status, data}.
      if (result['status'] != null && result['data'] is Map)
        result = object(result['data']);
    } catch (_) {
      throw SocialException(
        'سرویس پاسخ معتبر نداد. دوباره تلاش کنید.',
        response.statusCode,
      );
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        result['success'] != true) {
      throw SocialException(
        result['message']?.toString() ?? 'عملیات انجام نشد.',
        response.statusCode,
      );
    }
    return result['data'];
  }

  Future<Json> upload(PlatformFile file, {int? courseId}) async {
    final max = courseId == null ? 100 : 250;
    if (file.size <= 0 || file.size > max * 1024 * 1024) {
      throw SocialException('حداکثر حجم فایل $max مگابایت است.');
    }
    final request = http.MultipartRequest(
      'POST',
      uri(courseId == null ? '/media' : '/courses/$courseId/media'),
    );
    request.headers.addAll(headers);
    if (file.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
      );
    } else if (file.path != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ),
      );
    } else {
      throw const SocialException('فایل انتخاب‌شده در دسترس نیست.');
    }
    final response = await _client
        .send(request)
        .timeout(const Duration(minutes: 10));
    return object(_decode(await http.Response.fromStream(response)));
  }

  void dispose() {
    _disposed = true;
    _client.close();
  }
}
