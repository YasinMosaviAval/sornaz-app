import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_drawer.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_functions.dart';
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
  String selectedCategory = 'همه';
  String searchQuery = '';
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
    _scrollController.addListener(_scrollListener); // گوش دادن به اسکرول
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
      posts = []; // ریست لیست
      currentPage = 1; // ریست صفحه
      hasMore = true;
    });

    try {
      // واکشی دسته‌ها (فقط یک بار)
      categories = await fetchCategories();
      // لود صفحه اول مقالات
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
      _loadMorePosts(); // وقتی به انتها نزدیک شد، لود کن
    }
  }

  // وقتی فیلتر تغییر کرد، لیست رو ریست و دوباره لود کن
  // void _applyFilters() => _fetchInitialData();

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Articles',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        /*
        appBar: AppBar(
          title: const Text("مقالات"),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // سرچ بار
                  Expanded(
                    flex: 2, // فضای بیشتر برای سرچ
                    child: TextField(
                      onChanged: (value) {
                        searchQuery = value;
                        _applyFilters(); // فیلتر محلی
                      },
                      decoration: InputDecoration(
                        hintText: 'جستجوی مقاله...',
                        suffixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), // فاصله بین سرچ و dropdown
                  // Dropdown دسته‌بندی‌ها
                  Expanded(
                    flex: 1,
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      items:
                          [
                            'همه',
                            ...(categories.map(
                              (cat) => cat['name']?.toString() ?? 'نامشخص',
                            )),
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          selectedCategory = newValue;
                          _applyFilters(); // فیلتر محلی
                        }
                      },
                      underline: const SizedBox(), // حذف خط زیر
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        */
        /*
        appBar: AppBar(
          title: const Text("مقالات"),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Dropdown دسته‌بندی‌ها
                  Expanded(
                    flex: 1,
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      items:
                          [
                            'همه',
                            ...(categories.map(
                              (cat) => cat['name']?.toString() ?? 'نامشخص',
                            )),
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(fontSize: 10),
                              ),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          selectedCategory = newValue;
                          _applyFilters(); // فیلتر محلی
                        }
                      },
                      underline: const SizedBox(), // حذف خط زیر
                    ),
                  ),
                  // سرچ بار
                  Expanded(
                    flex: 2, // فضای بیشتر برای سرچ
                    child: TextField(
                      // onChanged: (value) {
                      //   searchQuery = value;
                      //   _applyFilters(); // فیلتر محلی
                      // },
                      onChanged: (value) {
                        // لغو تایمر قبلی
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        // ایجاد تایمر جدید با تاخیر 1000 میلی‌ثانیه
                        _debounce = Timer(
                          const Duration(milliseconds: 1000),
                          () {
                            setState(() {
                              searchQuery = value;
                            });
                            _applyFilters(); // فیلتر جدید بعد از توقف تایپ
                          },
                        );
                      },
                      decoration: InputDecoration(
                        hintText: 'جستجوی مقاله...',
                        suffixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), // فاصله بین سرچ و dropdown
                ],
              ),
            ),
          ),
        ),
        */
        appBar: AppBar(
          backgroundColor: isDark
              ? AppColors.background_dark
              : AppColors.background_light,
          elevation: 0,
          automaticallyImplyLeading: false,
          leadingWidth: 48,
          titleSpacing: 16,
          actionsPadding: const EdgeInsets.only(right: 24),

          leading: HeaderMenuIcon(isDark: isDark),
          title: ApplicationTitle(isDark: isDark),
          actions: [ApplicationLogo(isDark: isDark)],
        ),
        drawer: const AppDrawer(),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : hasError
              ? const Center(child: Text('خطا در بارگذاری داده‌ها'))
              : RefreshIndicator(
                  onRefresh: _fetchInitialData, // pull to refresh
                  child: ListView.builder(
                    controller: _scrollController, // برای lazy loading
                    itemCount:
                        posts.length +
                        (isLoadingMore ? 1 : 0), // +1 برای لودینگ فوتر
                    itemBuilder: (context, index) {
                      if (index == posts.length) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        ); // لودینگ فوتر
                      }

                      final post = posts[index];
                      final title = post['title']?['rendered'] ?? 'بدون عنوان';
                      final excerpt =
                          (post['excerpt']?['rendered'] as String?)?.replaceAll(
                            RegExp(r'<[^>]*>'),
                            '',
                          ) ??
                          'بدون خلاصه';
                      final featuredMedia = post['featured_media'] ?? 0;
                      final imageUrl =
                          (featuredMedia is int &&
                              featuredMedia > 0 &&
                              post['_embedded'] != null)
                          ? (post['_embedded']['wp:featuredmedia']?[0]?['source_url']
                                    as String?) ??
                                ''
                          : '';
                      // final date =
                      //     (post['date'] as String?)?.substring(0, 10) ??
                      //     'نامشخص';
                      final isoDate = post['date'] as String? ?? '';

                      return Container(
                        decoration: BoxDecoration(
                          color: index % 2 == 0
                              ? AppColors.background_light
                              : AppColors.surface_light,
                          border: Border.all(
                            width: 1,
                            color: const Color.fromRGBO(31, 31, 31, 0.1),
                            style: BorderStyle.solid,
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                        child: ListTile(
                          leading: imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: 100,
                                  fit: BoxFit.contain,
                                  // placeholder: (context, url) =>
                                  //     const CircularProgressIndicator(),
                                  // errorWidget: (context, url, error) =>
                                  //     const Icon(Icons.error, size: 50),
                                )
                              : const Icon(Icons.image, size: 50),
                          title: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                excerpt.length > 100
                                    ? '${excerpt.substring(0, 100)}...'
                                    : excerpt,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              SizedBox(
                                width: MediaQuery.sizeOf(context).width,
                                child: Text(
                                  // 'تاریخ: $date',
                                  formatJalaliDate(
                                    isoDate,
                                  ), // اینجا تاریخ شمسی میاد
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ArticleDetailPage(post: post),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
        bottomNavigationBar: const BottomNavBarWidget(),
      ),
    );
  }
}

// فانکشن برای واکشی پست‌ها (با صفحه‌بندی)
// Future<List<dynamic>> fetchPosts(
//   String category,
//   String search,
//   int page,
// ) async {
//   String url =
//       'https://sornaz.com/wp-json/wp/v2/posts?per_page=10&page=$page&_embed'; // ۱۰ تا در هر صفحه

//   final response = await http.get(Uri.parse(url));
//   if (response.statusCode == 200) {
//     return json.decode(response.body);
//   } else if (response.statusCode == 400) {
//     // صفحه تمام شد
//     return []; // لیست خالی برگردون
//   } else {
//     throw Exception('Failed to load posts');
//   }
// }

Future<List<dynamic>> fetchPosts(
  String category,
  String search,
  int page,
) async {
  // آدرس پایه
  String url =
      'https://sornaz.com/wp-json/wp/v2/posts?per_page=10&page=$page&_embed';

  // اگر کاربر دنبال چیزی گشت
  if (search.isNotEmpty) {
    url += '&search=${Uri.encodeComponent(search)}';
  }

  // اگر دسته خاصی انتخاب شده
  if (category != 'همه') {
    // پیدا کردن آیدی دسته با نام
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

  // حالا درخواست نهایی رو بفرست
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else if (response.statusCode == 400) {
    return []; // صفحه تموم شده
  } else {
    throw Exception('Failed to load posts');
  }
}

// فانکشن برای واکشی دسته‌ها
Future<List<dynamic>> fetchCategories() async {
  final response = await http.get(
    Uri.parse('https://sornaz.com/wp-json/wp/v2/categories?per_page=99'),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load categories');
  }
}
