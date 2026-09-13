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
    if (isCurrentAccount?.call() == false) {
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
  Future<Json> get(String path, [Map<String, String>? query]) async {
    checkAccount();
    final request = http.Request('GET', uri(path, query))
      ..followRedirects = false
      ..headers.addAll(headers);
    final response = await http.Response.fromStream(
      await client.send(request).timeout(const Duration(seconds: 30)),
    );
    checkAccount();
    return decode(response);
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
    return decode(response);
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

  void dispose() => client.close();
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
