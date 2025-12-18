import 'package:cached_network_image/cached_network_image.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/screens/Home/app_drawer.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_navigation.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Articles/article_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:sornaz/screens/Home/home.dart';

class ArticlesPage extends StatefulWidget {
  const ArticlesPage({super.key});

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  List<dynamic> posts = [];
  List<dynamic> categories = [];
  String get selectedCategory => AppStrings.all.translate(context as BuildContext);
  String searchQuery = AppStrings.epmty_text;
  bool isLoading = true;
  bool hasError = false;
  bool isLoadingMore = false;
  int currentPage = 1;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      isLoading = true;
      hasError = false;
      posts = [];
      currentPage = 1;
      hasMore = true;
    });

    try {
      categories = await fetchCategories();
      await _loadMorePosts();
    } catch (e) {
      setState(() {
        hasError = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (isLoadingMore || !hasMore) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final newPosts = await fetchPosts(
        selectedCategory,
        searchQuery,
        currentPage,
      );
      if (newPosts.isEmpty) {
        hasMore = false;
      } else {
        setState(() {
          posts.addAll(newPosts);
          currentPage++;
        });
      }
    } catch (e) {
      // هندل ارور (اختیاری: snackbar نشون بده)
    } finally {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_scrollController.position.outOfRange) {
      _loadMorePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.articles_title.translate(context),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.surface_dark : AppColors.surface_light,
          elevation: 0,
          automaticallyImplyLeading: false,
          leadingWidth: AppSpacing.space_48,
          titleSpacing: AppSpacing.space_16,
          actionsPadding: const EdgeInsets.only(right: AppSpacing.space_24),
          leading: HeaderMenuIcon(isDark: isDark),
          title: ApplicationTitle(isDark: isDark),
          actions: [ApplicationLogo(isDark: isDark)],
        ),
        drawer: const AppDrawer(),
        body: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.background_dark : AppColors.background_light,
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
            ? Center(
                child: Text(
                  AppStrings.error_in_loading.translate(context),
                  style: AppTypography.articlesErrorInLoading(context),
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchInitialData,
                child: ArticlesListWidget(
                  scrollController: _scrollController,
                  posts: posts,
                  isLoadingMore: isLoadingMore,
                  isDark: isDark,
                ),
              ),
          )
        ),
        bottomNavigationBar: const BottomNavBarWidget(),
      ),
    );
  }
}

class ArticlesListWidget extends StatelessWidget {
  const ArticlesListWidget({
    super.key,
    required ScrollController scrollController,
    required this.posts,
    required this.isLoadingMore,
    required this.isDark,
  }) : _scrollController = scrollController;

  final ScrollController _scrollController;
  final List<dynamic> posts;
  final bool isLoadingMore;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: posts.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == posts.length) return const Center(child: CircularProgressIndicator());

        final post = posts[index];
        final title = post['title']?['rendered'] ?? AppStrings.without_title.translate(context);
        final excerpt = (post['excerpt']?['rendered'] as String?)?.replaceAll( RegExp(r'<[^>]*>'), '', ) ?? AppStrings.without_briefs.translate(context);
        final featuredMedia = post['featured_media'] ?? 0;
        final imageUrl = (featuredMedia is int && featuredMedia > 0 && post['_embedded'] != null)
            ? (post['_embedded']['wp:featuredmedia']?[0]?['source_url'] as String?) ?? ''
            : '';
        final isoDate = post['date'] as String? ?? '';

        return Container(
          decoration: BoxDecoration(
            color: index % 2 == 0 ? AppColors.background_light : AppColors.surface_light,
            border: Border.all(
              width: 1,
              color: isDark ? AppColors.border_dark : AppColors.border_light,
              style: BorderStyle.solid,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space_4),
          child: ListTile(
            leading: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: AppSpacing.space_100,
                    fit: BoxFit.contain,
                  )
                : const Icon(Icons.image, size: AppSpacing.space_48),
            title: ArticlesTitleWidget(title: title, isDark: isDark),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.sizedBoxH4(),
                ArticlesBriefWidget(excerpt: excerpt, isDark: isDark),
                AppSpacing.sizedBoxH2(),
                ArticlesReleaseDateWidget(isoDate: isoDate, isDark: isDark),
              ],
            ),
            onTap: () {
              navigateWithFade(context, ArticleDetailPage(post: post));
            },
          ),
        );
      },
    );
  }
}

class ArticlesReleaseDateWidget extends StatelessWidget {
  const ArticlesReleaseDateWidget({
    super.key,
    required this.isoDate,
    required this.isDark,
  });

  final String isoDate;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      child: Text(
        formatJalaliDate(isoDate),
        style: AppTypography.articlesReleaseDate(context),
        textAlign: TextAlign.end,
      ),
    );
  }
}

class ArticlesBriefWidget extends StatelessWidget {
  const ArticlesBriefWidget({
    super.key,
    required this.excerpt,
    required this.isDark,
  });

  final String excerpt;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      excerpt.length > AppSpacing.space_100
          ? '${excerpt.substring(0, 100)}...'
          : excerpt,
      style: AppTypography.articlesBrief(context),
    );
  }
}

class ArticlesTitleWidget extends StatelessWidget {
  const ArticlesTitleWidget({
    super.key,
    required this.title,
    required this.isDark,
  });

  final dynamic title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTypography.articlesTitle(context));
  }
}

Future<List<dynamic>> fetchPosts(
  String category,
  String search,
  int page,
) async {
  String url =
      'https://sornaz.com/wp-json/wp/v2/posts?per_page=10&page=$page&_embed';

  if (search.isNotEmpty) {
    url += '&search=${Uri.encodeComponent(search)}';
  }

  if (category != AppStrings.all.translate(context as BuildContext)) {
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
    throw Exception(AppStrings.failed_to_load_posts.translate(context as BuildContext));
  }
}

Future<List<dynamic>> fetchCategories() async {
  final response = await http.get(
    Uri.parse('https://sornaz.com/wp-json/wp/v2/categories?per_page=99'),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception(AppStrings.failed_to_load_categories.translate(context as BuildContext));
  }
}
