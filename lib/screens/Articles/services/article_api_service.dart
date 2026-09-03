import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sornaz/helpers/app_constants.dart';

class ArticleApiService {
  static const String _baseUrl = 'https://sornaz.com/api/sornaz/v1';

  static dynamic _responseData(http.Response response) {
    final decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }

  static Future<List<dynamic>> fetchPosts({
    required int page,
    String search = '',
    int? categoryId,
  }) async {
    final query = <String, String>{
      'per_page': '10',
      'page': '$page',
      if (search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category_id': '$categoryId',
    };
    final response = await http.get(
      Uri.parse('$_baseUrl/articles').replace(queryParameters: query),
      headers: {'Accept': AppConstants.APPLICATION_JSON},
    );
    if (response.statusCode == 200) {
      return List<dynamic>.from(_responseData(response) as List? ?? const []);
    }
    if (response.statusCode == 400 || response.statusCode == 404) return [];
    throw Exception('Failed to load articles');
  }

  static Future<List<dynamic>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/article-categories'),
      headers: {'Accept': AppConstants.APPLICATION_JSON},
    );
    if (response.statusCode == 200) {
      return List<dynamic>.from(_responseData(response) as List? ?? const []);
    }
    throw Exception('Failed to load article categories');
  }

  static Future<List<dynamic>> fetchComments(int postId, int page) async {
    final url = Uri.parse('$_baseUrl/articles/$postId/comments').replace(
      queryParameters: {'per_page': '10', 'page': '$page'},
    );
    final response = await http.get(
      url,
      headers: {'Accept': AppConstants.APPLICATION_JSON},
    );
    if (response.statusCode == 200) {
      return List<dynamic>.from(_responseData(response) as List? ?? const []);
    }
    return [];
  }

  static Future<List<dynamic>> fetchRelatedPosts(int postId, int catId) async {
    final url = Uri.parse('$_baseUrl/articles/$postId/related').replace(
      queryParameters: {'category_id': '$catId', 'per_page': '2'},
    );
    final response = await http.get(
      url,
      headers: {'Accept': AppConstants.APPLICATION_JSON},
    );
    if (response.statusCode == 200) {
      return List<dynamic>.from(_responseData(response) as List? ?? const []);
    }
    return [];
  }

  static Future<bool> sendComment(int postId, String content, String authorName) async {
    final url = '$_baseUrl/articles/$postId/comments';
    final body = json.encode({
      AppConstants.POST: postId,
      AppConstants.CONTENT: content,
      AppConstants.AUTHOR_NAME: authorName,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {AppConstants.CONTENT_TYPE: AppConstants.APPLICATION_JSON},
      body: body,
    );
    if (response.statusCode != 201) return false;
    final data = _responseData(response);
    return data is Map<String, dynamic> && data['success'] == true;
  }
}
