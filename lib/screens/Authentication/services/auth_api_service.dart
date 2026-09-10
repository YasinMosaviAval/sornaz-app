import 'package:sornaz/helpers/http_client_factory.dart';
import 'dart:convert';
import 'package:sornaz/helpers/user_facing_error.dart';
import 'package:http/http.dart' as http;
import 'package:sornaz/screens/Authentication/models/auth_user.dart';

class AuthResult {
  const AuthResult({required this.token, required this.user});
  final String token;
  final AuthUser user;
}

class AuthApiException implements Exception {
  const AuthApiException(this._message);
  final String _message;
  String get message => userFacingError(_message);
  @override
  String toString() => message;
}

class AuthApiService {
  AuthApiService({http.Client? client}) : _client = client ?? createHttpClient();
  static const _baseUrl = String.fromEnvironment(
    'Sornaz_API_BASE_URL',
    defaultValue: 'https://sornaz.com/api/sornaz/v1',
  );
  final http.Client _client;
  String? _cookie;

  Future<AuthResult> login({
    required String identifier,
    required String password,
    required bool remember,
  }) async {
    return _authResult(
      await _post('/auth/login', {
        'identifier': identifier,
        'password': password,
        'remember': remember ? '1' : '0',
      }),
    );
  }

  Future<void> sendRegistrationOtp(Map<String, String> form) async =>
      _post('/auth/register/send-otp', form);
  Future<AuthResult> register(Map<String, String> form, String otp) async =>
      _authResult(await _post('/auth/register', {...form, 'otp': otp}));

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, String> body,
  ) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
            'Cookie': ?_cookie,
          },
          body: body,
        )
        .timeout(const Duration(seconds: 25));
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) _cookie = setCookie.split(';').first;
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final envelope =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final data =
          (envelope['data'] as Map?)?.cast<String, dynamic>() ?? envelope;
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          data['success'] == false) {
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          throw AuthApiException(errors.values.first.toString());
        }
        throw AuthApiException(
          data['message']?.toString() ?? 'خطا در ارتباط با سرور',
        );
      }
      return data;
    } on AuthApiException {
      rethrow;
    } catch (_) {
      final contentType = response.headers['content-type'] ?? '';
      throw AuthApiException(
        'سرویس ورود روی سرور فعال نیست یا پاسخ JSON برنگرداند '
        '(HTTP ${response.statusCode}${contentType.isEmpty ? '' : '، $contentType'}).',
      );
    }
  }

  AuthResult _authResult(Map<String, dynamic> data) => AuthResult(
    token: data['token'].toString(),
    user: AuthUser.fromJson((data['user'] as Map).cast<String, dynamic>()),
  );
}
