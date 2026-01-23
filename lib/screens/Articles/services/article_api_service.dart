import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sornaz/helpers/app_constants.dart';

class ArticleApiService {
  static Future<List<dynamic>> fetchComments(int postId, int page) async {
    final url =
        'https://sornaz.com/wp-json/wp/v2/comments?post=$postId&per_page=10&page=$page';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) return json.decode(response.body);
    return [];
  }

  static Future<List<dynamic>> fetchRelatedPosts(int postId, int catId) async {
    final url =
        'https://sornaz.com/wp-json/wp/v2/posts?categories=$catId&per_page=2&exclude=$postId&_embed';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) return json.decode(response.body);
    return [];
  }

  static Future<bool> sendComment(int postId, String content, String authorName) async {
    final url = 'https://sornaz.com/wp-json/wp/v2/comments';
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
    return response.statusCode == 201;
  }
}
