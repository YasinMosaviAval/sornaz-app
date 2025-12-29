import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/screens/Articles/cache/hive_articles_cache.dart';

class ArticlesProvider extends ChangeNotifier {
  List<Map<String, dynamic>> posts = [];
  List<dynamic> categories = [];
  String selectedCategory = AppStrings.all;
  String searchQuery = '';
  bool isLoading = false;
  bool hasError = false;
  bool isLoadingMore = false;
  int currentPage = 1;
  bool hasMore = true;

  final HiveArticlesCache _cache = HiveArticlesCache();
  Timer? _debounce;

  ScrollController scrollController = ScrollController();

  ArticlesProvider() {
    scrollController.addListener(_scrollListener);
    loadInitial();
  }

  @override
  void dispose() {
    scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> loadInitial() async {
    isLoading = true;
    hasError = false;
    notifyListeners();

    try {
      final cachedPosts = await _cache.loadArticles();
      if (cachedPosts.isNotEmpty) {
        posts = cachedPosts;
        notifyListeners();
      }

      categories = await fetchCategories();

      if (cachedPosts.isEmpty) {
        currentPage = 1;
        hasMore = true;
        await _loadMorePosts();
      }

    } catch (e) {
      hasError = true;
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  Future<void> _loadMorePosts() async {
    if (isLoadingMore || !hasMore) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      final newPosts = await fetchPosts(
        selectedCategory,
        searchQuery,
        currentPage,
      );

      if (newPosts.isEmpty) {
        hasMore = false;
      } else {
        final newPostsMap = newPosts
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        posts.addAll(newPostsMap);
        currentPage++;
        await _cache.saveArticles(posts);
      }
    } catch (e) {
      hasError = true;
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  void _scrollListener() {
    if (scrollController.offset >=
            scrollController.position.maxScrollExtent - 200 &&
        !scrollController.position.outOfRange) {
      _loadMorePosts();
    }
  }


  void updateSearchQuery(String query) {
    searchQuery = query;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await refreshArticles();
    });
  }


  Future<void> refreshArticles() async {
    isLoading = true;
    hasError = false;
    currentPage = 1;
    hasMore = true;
    posts = [];
    notifyListeners();

    try {
      await _loadMorePosts();
    } catch (e) {
      hasError = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  Future<void> updateCategory(String category) async {
    selectedCategory = category;
    await refreshArticles();
  }


  Future<List<dynamic>> fetchPosts(
      String category, String search, int page) async {
    String url =
        'https://sornaz.com/wp-json/wp/v2/posts?per_page=10&page=$page&_embed';

    if (search.isNotEmpty) {
      url += '&search=${Uri.encodeComponent(search)}';
    }

    if (category != AppStrings.all) {
      final catResponse = await http.get(
        Uri.parse('https://sornaz.com/wp-json/wp/v2/categories?per_page=99'),
      );
      if (catResponse.statusCode == 200) {
        final cats = json.decode(catResponse.body);
        final matchedCat = cats.firstWhere(
          (c) => c['name'] == category,
          orElse: () => null,
        );
        if (matchedCat != null) {
          url += '&categories=${matchedCat['id']}';
        }
      }
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 400) {
      return [];
    } else {
      throw Exception(AppStrings.failed_to_load_posts);
    }
  }

  Future<List<dynamic>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('https://sornaz.com/wp-json/wp/v2/categories?per_page=99'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(AppStrings.failed_to_load_categories);
    }
  }
}