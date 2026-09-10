import 'dart:convert';
import 'package:sornaz/helpers/user_facing_error.dart';
import 'package:http/http.dart' as http;

class ArticleApiException implements Exception {
  const ArticleApiException(this._message, this.status);
  final String _message;
  String get message => userFacingError(_message);
  final int status;
  @override
  String toString() => message;
}

class ArticleApiService {
  ArticleApiService({http.Client? client}) : client = client ?? http.Client();
  final http.Client client;
  static const baseUrl = String.fromEnvironment(
    'SORNAZ_API_BASE_URL',
    defaultValue: 'https://sornaz.com/api/sornaz/v1',
  );
  Future<dynamic> request(
    String path, {
    required String locale,
    Map<String, String> query = const {},
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: {...query, 'locale': locale});
    final headers = {
      'Accept': 'application/json',
      'Accept-Language': locale,
      if (token?.isNotEmpty == true) 'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };
    final response =
        await (body == null
                ? client.get(uri, headers: headers)
                : client.post(uri, headers: headers, body: jsonEncode(body)))
            .timeout(const Duration(seconds: 20));
    dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is Map && data.containsKey('data')) data = data['data'];
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data is Map && data['success'] == false) {
      throw ArticleApiException(
        data is Map
            ? '${data['message'] ?? 'Request failed'}'
            : 'Request failed',
        response.statusCode,
      );
    }
    return data;
  }

  Future<Map<String, dynamic>> manifest(String locale) async =>
      Map<String, dynamic>.from(
        await request('/articles/manifest', locale: locale),
      );
  Future<List<Map<String, dynamic>>> fetchPosts({
    required String locale,
    int page = 1,
    List<int>? ids,
  }) async => _list(
    await request(
      '/articles',
      locale: locale,
      query: {
        'per_page': '50',
        'page': '$page',
        if (ids != null) 'ids': ids.join(','),
      },
    ),
  );
  Future<Map<String, dynamic>> fetchPost(int id, String locale) async =>
      Map<String, dynamic>.from(await request('/articles/$id', locale: locale));
  Future<List<Map<String, dynamic>>> fetchComments(
    int id, {
    required String locale,
    required int page,
    String? token,
    List<String> receipts = const [],
  }) async => _list(
    await request(
      '/articles/$id/comments',
      locale: locale,
      token: token,
      query: {
        'page': '$page',
        'per_page': '20',
        if (receipts.isNotEmpty) 'receipts': receipts.join(','),
      },
    ),
  );
  Future<Map<String, dynamic>> sendComment(
    int id, {
    required String locale,
    required String content,
    String? token,
    String author = '',
    String email = '',
    int parent = 0,
  }) async => Map<String, dynamic>.from(
    await request(
      '/articles/$id/comments',
      locale: locale,
      token: token,
      body: {
        'content': content,
        'author_name': author,
        'author_email': email,
        'parent': parent,
      },
    ),
  );
  Future<Map<String, dynamic>> rating(
    String type,
    int id, {
    required String locale,
    String? token,
    int? score,
  }) async => Map<String, dynamic>.from(
    await request(
      '/article-ratings/$type/$id',
      locale: locale,
      token: token,
      body: score == null ? null : {'score': score},
    ),
  );
  List<Map<String, dynamic>> _list(dynamic data) =>
      (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  void dispose() => client.close();
}
