import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

typedef Json = Map<String, dynamic>;
int number(dynamic value) => int.tryParse('$value') ?? 0;
Json object(dynamic value) => (value as Map).cast<String, dynamic>();
List<Json> objects(dynamic value) => (value as List).map(object).toList();

class SocialException implements Exception {
  const SocialException(this.message, [this.status = 0]);
  final String message;
  final int status;
  @override
  String toString() => message;
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
  Future<dynamic> get(String path) async => _decode(
    await _client
        .get(uri(path), headers: headers)
        .timeout(const Duration(seconds: 30)),
  );
  Future<dynamic> post(
    String path, [
    Map<String, String> body = const {},
  ]) async => _decode(
    await _client
        .post(uri(path), headers: headers, body: body)
        .timeout(const Duration(seconds: 40)),
  );
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

  void dispose() => _client.close();
}
