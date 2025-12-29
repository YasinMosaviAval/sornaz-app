import 'package:flutter/material.dart';
import '../data/articles_repository.dart';

class ArticlesProvider extends ChangeNotifier {
  final ArticlesRepository repository;

  ArticlesProvider(this.repository);

  final ScrollController scrollController = ScrollController();

  List<dynamic> posts = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  bool hasError = false;
  int _page = 1;

  void init() {
    scrollController.addListener(_onScroll);
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    isLoading = true;
    hasError = false;
    posts.clear();
    _page = 1;
    hasMore = true;
    notifyListeners();

    try {
      final data = await repository.fetchPosts(_page);
      posts = data;
      _page++;
    } catch (_) {
      hasError = true;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      final data = await repository.fetchPosts(_page);
      if (data.isEmpty) {
        hasMore = false;
      } else {
        posts.addAll(data);
        _page++;
      }
    } catch (_) {}

    isLoadingMore = false;
    notifyListeners();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      loadMore();
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
