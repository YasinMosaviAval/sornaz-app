import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class ArticlesRepository {
  final Box box = Hive.box('articlesBox');

  static const _postsKey = 'posts';
  static const _lastUpdatedKey = 'lastUpdated';


  List<dynamic> loadCachedPosts() {
    return box.get(_postsKey, defaultValue: []);
  }

  DateTime? lastUpdated() {
    final value = box.get(_lastUpdatedKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> savePosts(List<dynamic> posts) async {
    await box.put(_postsKey, posts);
    await box.put(_lastUpdatedKey, DateTime.now().toIso8601String());
  }

  Future<void> clearCache() async {
    await box.delete(_postsKey);
    await box.delete(_lastUpdatedKey);
  }


  Future<List<dynamic>> fetchPosts({
    required int page,
    int perPage = 10,
  }) async {
    final url = 'https://sornaz.com/wp-json/wp/v2/posts?_embed&page=$page&per_page=$perPage';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 400) {
      return [];
    } else {
      throw Exception('Failed to load posts');
    }
  }
}
