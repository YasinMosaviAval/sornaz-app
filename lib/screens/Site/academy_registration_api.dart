import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:sornaz/helpers/http_client_factory.dart';
import '../Social/social_api.dart';

class AcademyRegistrationException implements Exception {
  const AcademyRegistrationException(
    this.message, {
    this.status = 0,
    this.retryAfter = 0,
    this.errors = const {},
  });
  final String message;
  final int status, retryAfter;
  final Map<String, dynamic> errors;
}

class AcademyRegistrationApi {
  AcademyRegistrationApi({
    this.token = '',
    this.userId = 0,
    http.Client? client,
    FlutterSecureStorage? storage,
  }) : client = client ?? createHttpClient(),
       storage = storage ?? const FlutterSecureStorage();
  final String token;
  final int userId;
  final http.Client client;
  final FlutterSecureStorage storage;
  String? cookie, flowToken;
  bool restored = false;
  String get key =>
      'academy_registration_session:${Uri.parse(SocialApi.base).host}:$userId';
  Future<Map<String, dynamic>> state() => request('');
  Future<Map<String, dynamic>> sendCode(
    Map<String, String> form,
    String step,
  ) => request('/send-code', {...form, 'step': step});
  Future<Map<String, dynamic>> submit(
    Map<String, String> form,
    String step,
    String otp,
  ) => request('/submit', {...form, 'step': step, 'otp': otp});
  Future<Map<String, dynamic>> withoutBranch() =>
      request('/without-branch', {});
  Future<void> forget() async {
    cookie = null;
    flowToken = null;
    try {
      await storage.delete(key: key);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> request(
    String path, [
    Map<String, String>? body,
  ]) async {
    if (!restored) {
      restored = true;
      try {
        cookie = await storage.read(key: key);
      } catch (_) {}
    }
    final headers = <String, String>{
      'Accept': 'application/json',
      'Accept-Language': SocialApi.locale,
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Cookie': ?cookie,
      'X-Academy-Flow': ?flowToken,
    };
    try {
      final uri = Uri.parse('${SocialApi.base}/academy-registration$path');
      final response =
          await (body == null
                  ? client.get(uri, headers: headers)
                  : client.post(uri, headers: headers, body: body))
              .timeout(const Duration(seconds: 25));
      final setCookie = response.headers['set-cookie'];
      if (setCookie != null) {
        final session = RegExp(
          r'(?:^|,\s*)(PHPSESSID=[^;,\s]+)',
        ).firstMatch(setCookie);
        if (session != null) {
          cookie = session.group(1);
          try {
            await storage.write(key: key, value: cookie);
          } catch (_) {}
        }
      }
      final envelope =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final data = Map<String, dynamic>.from(
        envelope['data'] is Map ? envelope['data'] as Map : envelope,
      );
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          data['success'] == false) {
        throw AcademyRegistrationException(
          data['message']?.toString() ?? '',
          status: response.statusCode,
          retryAfter: (data['retry_after'] as num?)?.toInt() ?? 0,
          errors: data['errors'] is Map
              ? Map<String, dynamic>.from(data['errors'] as Map)
              : {},
        );
      }
      if (data['flow_token'] is String) {
        flowToken = data['flow_token'] as String;
      }
      return data;
    } on AcademyRegistrationException {
      rethrow;
    } catch (_) {
      throw const AcademyRegistrationException('');
    }
  }

  void dispose() => client.close();
}
