import 'dart:async';
import 'chat_cache.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../Social/social_api.dart';

class PanelApi {
  PanelApi(this.token, {http.Client? client, this.isCurrentAccount})
    : client = client ?? http.Client();
  final String token;
  String? _sessionCookie;
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
    'X-Sornaz-Panel-Forms': '2',
    'X-Sornaz-Panel-Features': '4',
    'Cookie': ?_sessionCookie,
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
  bool branchContext = false;
  final _mutations = StreamController<String>.broadcast();
  Stream<String> get mutations => _mutations.stream;

  String _key(String path, Map<String, String>? query) {
    final sorted = Map.fromEntries(
      (query ?? {}).entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return 'panel-v4:${SocialApi.locale}:${uri(path, sorted)}';
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

  Future<Json?> saved(String path, [Map<String, String>? query]) async {
    checkAccount();
    if (path.startsWith('/database-management/')) return null;
    final value = await ChatCache.read(token, _key(path, query));
    checkAccount();
    if (value is! Map) return null;
    final result = object(value);
    if (path.isEmpty) branchContext = result['branchContext'] == true;
    return result;
  }

  /// Only the visible panel polls. Bypass the session cache for these reads.
  Future<Json> live(String path, [Map<String, String>? query]) {
    _cache.remove(_key(path, query));
    return get(path, query);
  }

  Future<Json> get(String path, [Map<String, String>? query]) async {
    if (path.startsWith('/database-management/')) {
      return sensitiveGet(path, query);
    }
    checkAccount();
    final key = _key(path, query);
    final cached = _cache[key];
    if (cached != null && DateTime.now().isBefore(cached.$1)) {
      final value = object(jsonDecode(cached.$2));
      if (path.isEmpty) branchContext = value['branchContext'] == true;
      return value;
    }
    final revision = _revision;
    final pendingKey = '$revision:$key';
    final pending = _pending[pendingKey];
    if (pending != null) return object(jsonDecode(jsonEncode(await pending)));
    if (_pending.length >= 16) {
      throw const SocialException('Please wait for the current request.');
    }
    final previous = _queue;
    final done = Completer<void>();
    _queue = done.future;
    final future = () async {
      await previous;
      checkAccount();
      try {
        if (_blockedUntil != null && DateTime.now().isBefore(_blockedUntil!))
          throw _lastFailure!;
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
        if (path.isEmpty) branchContext = value['branchContext'] == true;
        if (path.isEmpty || path.startsWith('/chat/'))
          await ChatCache.write(token, key, value);
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
        if (path.isEmpty || path.startsWith('/chat/')) {
          if (ChatCache.mayUseOffline(error)) {
            final saved = await ChatCache.read(token, key);
            checkAccount();
            if (saved is Map) {
              final value = object(saved);
              if (path.isEmpty) branchContext = value['branchContext'] == true;
              return {...value, '_offline': true};
            }
          } else {
            await ChatCache.remove(token, key);
          }
        }
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
    _pending[pendingKey] = future;
    try {
      return object(jsonDecode(jsonEncode(await future)));
    } finally {
      _pending.remove(pendingKey);
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
    final cookie = response.headers['set-cookie'];
    if (cookie != null) {
      final session = RegExp(
        r'(?:^|,\s*)(PHPSESSID=[^;,\s]+)',
      ).firstMatch(cookie);
      if (session != null) _sessionCookie = session.group(1);
    }
    final value = decode(response);
    _revision++;
    _cache.clear();
    _mutations.add(section);
    return value;
  }

  Future<void> download(
    String section,
    String action,
    Map<String, String> params,
    String filename,
  ) async {
    if (section == 'database-management') {
      return downloadDatabase(action, params, filename);
    }
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

  /// Database records never enter the session or persistent offline cache.
  Future<Json> sensitiveGet(String path, [Map<String, String>? query]) async {
    checkAccount();
    final request = http.Request('GET', uri(path, query))
      ..followRedirects = false
      ..headers.addAll({...headers, 'Cache-Control': 'no-store'});
    final response = await http.Response.fromStream(
      await client.send(request).timeout(const Duration(seconds: 30)),
    );
    checkAccount();
    final status = privateErrorStatus(response.body, response.statusCode);
    if ([401, 403].contains(status))
      throw SocialException('دسترسی لازم برای این بخش را ندارید.', status);
    return decode(response);
  }

  /// Stream SQL to a private temporary file rather than buffering a database.
  Future<void> downloadDatabase(
    String action,
    Map<String, String> params,
    String filename,
  ) async {
    checkAccount();
    final request =
        http.Request('GET', uri('/database-management/$action', params))
          ..followRedirects = false
          ..headers.addAll({
            ...headers,
            'Accept': 'application/sql',
            'Cache-Control': 'no-store',
          });
    final response = await client
        .send(request)
        .timeout(const Duration(minutes: 2));
    Directory? folder;
    IOSink? output;
    var handled = false;
    try {
      checkAccount();
      final contentType =
          response.headers['content-type']
              ?.split(';')
              .first
              .trim()
              .toLowerCase() ??
          '';
      if (response.statusCode != 200 ||
          ![
            'application/sql',
            'application/octet-stream',
            'text/plain',
            'text/x-sql',
          ].contains(contentType)) {
        handled = true;
        var status = response.statusCode;
        if (contentType == 'application/json') {
          final bytes = <int>[];
          await for (final chunk in response.stream.timeout(
            const Duration(seconds: 30),
          )) {
            bytes.addAll(chunk.take(65536 - bytes.length));
            if (bytes.length >= 65536) break;
          }
          status = privateErrorStatus(
            utf8.decode(bytes, allowMalformed: true),
            status,
          );
        } else {
          await response.stream.listen((_) {}).cancel();
        }
        throw SocialException('دریافت فایل انجام نشد.', status);
      }
      final exportFolder = await (await getTemporaryDirectory()).createTemp(
        'sornaz-db-',
      );
      folder = exportFolder;
      final safe = filename.replaceAll(RegExp(r'[/\\<>:"|?*]'), '_');
      final file = File(
        '${exportFolder.path}/${safe.endsWith('.sql') ? safe : '$safe.sql'}',
      );
      output = file.openWrite();
      handled = true;
      await for (final chunk in response.stream.timeout(
        const Duration(minutes: 2),
      )) {
        checkAccount();
        output.add(chunk);
        await output.flush();
      }
      await output.flush();
      await output.close();
      output = null;
      checkAccount();
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final target = await FilePicker.platform.saveFile(
          fileName: file.uri.pathSegments.last,
        );
        checkAccount();
        if (target != null) await file.copy(target);
      } else {
        await Share.shareXFiles([
          XFile(file.path, mimeType: 'application/sql'),
        ]);
      }
    } finally {
      try {
        await output?.close();
      } finally {
        try {
          if (!handled) await response.stream.listen((_) {}).cancel();
        } finally {
          if (folder != null && await folder.exists())
            await folder.delete(recursive: true);
        }
      }
    }
  }

  static int privateErrorStatus(String body, int fallback) {
    try {
      final value = jsonDecode(body);
      if (value is Map)
        for (final item in [value, if (value['data'] is Map) value['data']]) {
          final status = int.tryParse('${item['status'] ?? item['code']}');
          if ([401, 403].contains(status)) return status!;
        }
    } catch (_) {}
    return fallback;
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
    unawaited(_mutations.close());
    _cache.clear();
    client.close();
  }
}

dynamic panelValue(dynamic value, String path) {
  if (path.isEmpty) return value;
  for (final part in path.split('.')) {
    if (value is List) {
      final index = int.tryParse(part);
      if (index == null || index < 0 || index >= value.length) return null;
      value = value[index];
    } else if (value is Map) {
      value = value[part];
    } else {
      return null;
    }
  }
  return value;
}

String panelTitle(Json item) =>
    '${item['name'] ?? item['title'] ?? item['label'] ?? item['question'] ?? item['full_name'] ?? item['username'] ?? item['course_title'] ?? item['term_title'] ?? item['classroom_title'] ?? item['value'] ?? item['degree'] ?? item['subject'] ?? item['id'] ?? ''}';
