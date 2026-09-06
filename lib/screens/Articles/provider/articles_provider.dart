import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/screens/Articles/cache/hive_articles_cache.dart';
import 'package:sornaz/screens/Articles/services/article_api_service.dart';

class ArticlesProvider extends ChangeNotifier with WidgetsBindingObserver {
  ArticlesProvider({
    ArticleApiService? api,
    HiveArticlesCache? cache,
    String locale = 'fa',
    bool autoStart = true,
  }) : api = api ?? ArticleApiService(),
       cache = cache ?? HiveArticlesCache(),
       _locale = locale {
    WidgetsBinding.instance.addObserver(this);
    scrollController.addListener(_scroll);
    if (autoStart) {
      scheduleMicrotask(loadInitial);
      _timer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => synchronize(),
      );
    }
  }
  final ArticleApiService api;
  final HiveArticlesCache cache;
  String _locale;
  String get locale => _locale;
  List<Map<String, dynamic>> allPosts = [], categories = [];
  int? selectedCategoryId;
  String get selectedCategory =>
      selectedCategoryId == null ? AppStrings.all : '$selectedCategoryId';
  String searchQuery = '';
  bool isLoading = false, hasError = false, isLoadingMore = false;
  bool get hasMore => false;
  bool _disposed = false;
  int _generation = 0;
  Future<void>? _sync;
  Timer? _timer;
  final scrollController = ScrollController();
  final progress = ValueNotifier<double>(0);
  List<Map<String, dynamic>> get posts => allPosts
      .where(
        (p) =>
            (selectedCategoryId == null ||
                (p['categories'] as List? ?? []).contains(
                  selectedCategoryId,
                )) &&
            ('${p['title']?['rendered'] ?? ''} ${p['excerpt']?['rendered'] ?? ''}')
                .toLowerCase()
                .contains(searchQuery.toLowerCase()),
      )
      .toList();
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _scroll() {
    if (!scrollController.hasClients) return;
    final max = scrollController.position.maxScrollExtent;
    progress.value = max > 0 ? (scrollController.offset / max).clamp(0, 1) : 0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) synchronize();
  }

  void setLocale(String value) {
    value = value == 'en' ? 'en' : 'fa';
    if (value == _locale) return;
    _locale = value;
    _generation++;
    _sync = null;
    allPosts = [];
    categories = [];
    selectedCategoryId = null;
    searchQuery = '';
    isLoading = true;
    hasError = false;
    scheduleMicrotask(loadInitial);
  }

  Future<void> loadInitial() async {
    final generation = _generation, language = _locale;
    isLoading = allPosts.isEmpty;
    _notify();
    try {
      final snapshot = await cache.loadSnapshot(language);
      if (_disposed || generation != _generation) return;
      _apply(snapshot);
    } catch (_) {
      hasError = true;
    }
    if (_disposed || generation != _generation) return;
    isLoading = allPosts.isEmpty;
    _notify();
    await synchronize();
  }

  void _apply(Map<String, dynamic> snapshot) {
    allPosts = (snapshot['posts'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    categories = (snapshot['categories'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (selectedCategoryId != null &&
        !categories.any((c) => c['id'] == selectedCategoryId)) {
      selectedCategoryId = null;
    }
  }

  Future<void> synchronize() {
    if (_disposed) return Future.value();
    if (_sync != null) return _sync!;
    final generation = _generation;
    return _sync = _synchronize(_locale, generation).whenComplete(() {
      if (!_disposed && generation == _generation) _sync = null;
    });
  }

  Future<void> _synchronize(String language, int generation) async {
    try {
      final snapshot = await cache.loadSnapshot(language);
      final manifest = await api.manifest(language);
      final entries = (manifest['items'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final byId = {
        for (final p in (snapshot['posts'] as List? ?? []))
          (p['id'] as num).toInt(): Map<String, dynamic>.from(p),
      };
      final changed = entries
          .where(
            (e) =>
                byId[e['id']]?['revision'] != e['revision'] ||
                byId[e['id']]?['modified'] != e['modified'],
          )
          .map((e) => (e['id'] as num).toInt())
          .toList();
      for (var offset = 0; offset < changed.length; offset += 50) {
        final ids = changed.skip(offset).take(50).toList();
        final downloaded = await api.fetchPosts(locale: language, ids: ids);
        if (!ids.every((id) => downloaded.any((p) => p['id'] == id))) {
          throw const FormatException('Incomplete article snapshot');
        }
        for (final post in downloaded) {
          if (post['locale'] != language) {
            throw const FormatException('Article locale mismatch');
          }
          byId[(post['id'] as num).toInt()] = post;
        }
      }
      final next = {
        'posts': entries.map((e) => byId[e['id']]!).toList(),
        'categories': manifest['categories'],
        'synced_at': DateTime.now().toUtc().toIso8601String(),
      };
      await cache.saveSnapshot(language, next);
      // UI always reads committed storage, including after a network refresh.
      final committed = await cache.loadSnapshot(language);
      if (_disposed || generation != _generation) return;
      _apply(committed);
      hasError = false;
    } catch (_) {
      if (!_disposed && generation == _generation) hasError = true;
    } finally {
      if (!_disposed && generation == _generation) {
        isLoading = false;
        _notify();
      }
    }
  }

  void updateSearchQuery(String query) {
    searchQuery = query;
    _notify();
  }

  Future<void> updateCategory(String category) async {
    selectedCategoryId = category == AppStrings.all
        ? null
        : int.tryParse(category);
    _notify();
    if (scrollController.hasClients) scrollController.jumpTo(0);
  }

  Future<void> refreshArticles() => synchronize();
  Map<String, dynamic>? article(int id) {
    for (final p in allPosts) {
      if (p['id'] == id) return p;
    }
    return null;
  }

  Future<Map<String, dynamic>> resolve(int id) async {
    final cached = article(id);
    if (cached != null) return cached;
    await synchronize();
    final post = article(id);
    if (post == null) {
      throw const ArticleApiException(
        'Article is unavailable in this language.',
        404,
      );
    }
    return post;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    scrollController.dispose();
    progress.dispose();
    api.dispose();
    super.dispose();
  }
}
