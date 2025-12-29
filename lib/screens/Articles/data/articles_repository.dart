import 'dart:convert';
import 'package:http/http.dart' as http;

class ArticlesRepository {
  Future<List<dynamic>> fetchPosts(int page) async {
    final res = await http.get(
      Uri.parse(
        'https://sornaz.com/wp-json/wp/v2/posts?_embed&per_page=10&page=$page',
      ),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0',
      },
    );

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      if (decoded is List) return decoded;
    }

    if (res.statusCode == 400) return [];

    throw Exception('Failed to load posts');
  }
}
