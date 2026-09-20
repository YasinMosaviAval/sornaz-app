import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../Social/social_api.dart';

class PanelApi {
  PanelApi(this.token, {http.Client? client, this.isCurrentAccount})
    : client = client ?? http.Client();
  final String token;
  final bool Function()? isCurrentAccount;
  void checkAccount() {
    if (_disposed || isCurrentAccount?.call() == false) {
      throw SocialException(
        'حساب کاربری تغییر کرده است. دوباره پنل را باز کنید.',
        401,
      );
    }
  }

  final http.Client client;
  Uri uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${SocialApi.base}/panel$path').replace(queryParameters: query);
  Map<String, String> get headers => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Accept-Language': SocialApi.locale,
  };
  // Session-only cache: no background revalidation or automatic retry.
  final Map<String, (DateTime, String)> _cache = {};
  final Map<String, Future<Json>> _pending = {};
  final Map<String, DateTime> _refreshes = {};
  Future<void> _queue = Future<void>.value();
  DateTime? _blockedUntil;
  Object? _lastFailure;
  bool _disposed = false;
  int _revision = 0;

  String _key(String path, Map<String, String>? query) {
    final sorted = Map.fromEntries(
      (query ?? {}).entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return '${SocialApi.locale}:${uri(path, sorted)}';
  }

  Future<Json> refresh(String path, [Map<String, String>? query]) {
    final key = _key(path, query);
    final now = DateTime.now();
    if (!_refreshes.containsKey(key) ||
        now.difference(_refreshes[key]!) >= const Duration(seconds: 10)) {
      _refreshes[key] = now;
      _cache.remove(key);
    }
    return get(path, query);
  }

  Future<Json> get(String path, [Map<String, String>? query]) async {
    checkAccount();
    final key = _key(path, query);
    final cached = _cache[key];
    if (cached != null && DateTime.now().isBefore(cached.$1)) {
      return object(jsonDecode(cached.$2));
    }
    final pending = _pending[key];
    if (pending != null) return object(jsonDecode(jsonEncode(await pending)));
    if (_pending.length >= 16) {
      throw const SocialException('Please wait for the current request.');
    }
    final previous = _queue;
    final done = Completer<void>();
    _queue = done.future;
    final revision = _revision;
    final future = () async {
      await previous;
      checkAccount();
      if (_blockedUntil != null && DateTime.now().isBefore(_blockedUntil!)) {
        throw _lastFailure!;
      }
      try {
        final request = http.Request('GET', uri(path, query))
          ..followRedirects = false
          ..headers.addAll(headers);
        final response = await (() async => http.Response.fromStream(
          await client.send(request),
        ))().timeout(const Duration(seconds: 30));
        checkAccount();
        if (response.statusCode == 429 || response.statusCode == 503) {
          final raw = response.headers['retry-after'] ?? '';
          final seconds = int.tryParse(raw);
          DateTime? date;
          try {
            date = HttpDate.parse(raw);
          } catch (_) {}
          _blockedUntil = DateTime.now().add(
            Duration(
              seconds:
                  (seconds ?? date?.difference(DateTime.now()).inSeconds ?? 60)
                      .clamp(30, 3600),
            ),
          );
        }
        final value = decode(response);
        if (revision == _revision) {
          if (_cache.length >= 64) _cache.remove(_cache.keys.first);
          _cache[key] = (
            DateTime.now().add(
              path.isEmpty
                  ? const Duration(minutes: 10)
                  : const Duration(minutes: 2),
            ),
            jsonEncode(value),
          );
        }
        return value;
      } catch (error) {
        _lastFailure = error;
        if (error is SocialException &&
            (error.status == 401 || error.status == 403)) {
          _cache.clear();
        }
        if (_blockedUntil == null || _blockedUntil!.isBefore(DateTime.now())) {
          _blockedUntil = DateTime.now().add(const Duration(seconds: 30));
        }
        rethrow;
      }
    }();
    _pending[key] = future;
    try {
      return object(jsonDecode(jsonEncode(await future)));
    } finally {
      _pending.remove(key);
      done.complete();
    }
  }

  Future<Json> act(
    String section,
    String action, {
    Json values = const {},
    Map<String, String> params = const {},
    Map<String, PlatformFile> files = const {},
  }) async {
    checkAccount();
    final request =
        http.MultipartRequest('POST', uri('/$section/$action', params))
          ..followRedirects = false
          ..headers.addAll(headers)
          ..fields['payload_b64'] = base64Encode(
            utf8.encode(jsonEncode(values)),
          );
    for (final entry in files.entries) {
      final file = entry.value;
      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            entry.key,
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            entry.key,
            file.path!,
            filename: file.name,
          ),
        );
      }
    }
    checkAccount();
    final response = await http.Response.fromStream(
      await client.send(request).timeout(const Duration(minutes: 2)),
    );
    checkAccount();
    final value = decode(response);
    _revision++;
    _cache.clear();
    return value;
  }

  Future<void> download(
    String section,
    String action,
    Map<String, String> params,
    String filename,
  ) async {
    checkAccount();
    final request = http.Request('GET', uri('/$section/$action', params))
      ..followRedirects = false
      ..headers.addAll(headers);
    final response = await http.Response.fromStream(
      await client.send(request).timeout(const Duration(minutes: 2)),
    );
    checkAccount();
    if (response.statusCode != 200) {
      throw SocialException('دریافت فایل انجام نشد.', response.statusCode);
    }
    final safe = filename.replaceAll(RegExp(r'[/\\<>:"|?*]'), '_');
    final path = await FilePicker.platform.saveFile(
      fileName: safe,
      bytes: response.bodyBytes,
    );
    if (path != null &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await File(path).writeAsBytes(response.bodyBytes);
    }
  }

  static Json decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SocialException(
        response.statusCode == 403
            ? 'دسترسی لازم برای این بخش را ندارید.'
            : response.statusCode == 401
            ? 'برای ادامه وارد حساب شوید.'
            : 'انجام عملیات ناموفق بود. دوباره تلاش کنید.',
        response.statusCode,
      );
    }
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw SocialException('پاسخ سرور معتبر نیست. دوباره تلاش کنید.');
    }
    if (data is Map && data.containsKey('status') && data.containsKey('data')) {
      data = data['data'];
    }
    if (data is Map && data['success'] == false) {
      throw SocialException('انجام عملیات ناموفق بود. اطلاعات را بررسی کنید.');
    }
    if (data is Map && data.containsKey('data')) data = data['data'];
    return data is List ? {'items': data} : optionalObject(data);
  }

  /// Drop responses after a mutation sent through another authenticated API.
  void invalidate() {
    _revision++;
    _cache.clear();
  }

  void dispose() {
    _disposed = true;
    _cache.clear();
    client.close();
  }
}

dynamic panelValue(dynamic value, String path) {
  if (path.isEmpty) return value;
  for (final part in path.split('.')) {
    if (value is! Map) return null;
    value = value[part];
  }
  return value;
}

String panelTitle(Json item) =>
    '${item['name'] ?? item['title'] ?? item['label'] ?? item['question'] ?? item['full_name'] ?? item['username'] ?? item['course_title'] ?? item['term_title'] ?? item['classroom_title'] ?? item['value'] ?? item['degree'] ?? item['subject'] ?? item['id'] ?? ''}';
