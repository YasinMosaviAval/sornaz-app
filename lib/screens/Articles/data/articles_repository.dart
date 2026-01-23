import 'package:hive/hive.dart';
import 'package:sornaz/helpers/app_constants.dart';
// import 'dart:convert';
// import 'package:flutter/widgets.dart';
// import 'package:http/http.dart' as http;
// import 'package:sornaz/helpers/app_strings.dart';
// import 'package:sornaz/helpers/app_translations.dart';

class ArticlesRepository {
  final Box box = Hive.box(AppConstants.ARTICLES_BOX);

  static const _postsKey = AppConstants.POSTS;
  static const _lastUpdatedKey = AppConstants.LAST_UPDATED;


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


// COMMENT THIS FUNCTION IN NO INTERNET DAYS
// COMMENT THIS FUNCTION IN NO INTERNET DAYS
// COMMENT THIS FUNCTION IN NO INTERNET DAYS
// COMMENT THIS FUNCTION IN NO INTERNET DAYS

  // Future<List<dynamic>> fetchPosts({
  //   required int page,
  //   int perPage = 10,
  //   required BuildContext context
  // }) async {
  //   final url = 'https://sornaz.com/wp-json/wp/v2/posts?_embed&page=$page&per_page=$perPage';

  //   final response = await http.get(Uri.parse(url));

  //   if (response.statusCode == 200) {
  //     return json.decode(response.body);
  //   } else if (response.statusCode == 400) {
  //     return [];
  //   } else {
  //     if(context.mounted) {
  //       throw Exception(AppStrings.failed_to_load_posts.translate(context));
  //     }
  //     // throw Exception('Failed to load posts');
  //   }
  // }

// COMMENT THIS FUNCTION IN NO INTERNET DAYS
// COMMENT THIS FUNCTION IN NO INTERNET DAYS
// COMMENT THIS FUNCTION IN NO INTERNET DAYS
// COMMENT THIS FUNCTION IN NO INTERNET DAYS

}
