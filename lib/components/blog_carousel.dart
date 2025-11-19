import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/section_title.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_navigation.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/screens/Articles/article_detail_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:sornaz/screens/Articles/articles.dart';

class RealBlogCarousel extends StatelessWidget {
  const RealBlogCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    // final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 24, 0, 0),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: SectionTitle(
              title: AppStrings.last_blog_title,
              viewAll: AppStrings.view_all_link,
              viewAllLink: ArticlesPage(),
            ),
          ),

          FutureBuilder<List<dynamic>>(
            future: fetchRecentPosts(),
            // future: _getPosts(), // تغییر: از لوکال یا آنلاین بگیر
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return SizedBox(
                  height: 180,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal, // افقی مثل کاروسل
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final post = snapshot.data![index];
                        final title =
                            post['title']['rendered'] ?? AppStrings.no_title;
                        // final excerpt =
                        //     (post['excerpt']['rendered'] as String?)?.replaceAll(
                        //       RegExp(r'<[^>]*>'),
                        //       '',
                        //     ) ??
                        //     'بدون خلاصه';
                        final featuredMedia = post['featured_media'];
                        final imageUrl =
                            (featuredMedia is int &&
                                featuredMedia > 0 &&
                                post['_embedded'] != null)
                            ? (post['_embedded']['wp:featuredmedia']?[0]?['source_url']
                                      as String?) ??
                                  ''
                            : '';
                        // final date =
                        //     (post['date'] as String?)?.substring(0, 10) ?? 'نامشخص';

                        final isoDate =
                            post['date'] as String? ?? AppStrings.epmtyText;
                        return RealBlogCard(
                          post: post,
                          imageUrl: imageUrl,
                          title: title,
                          isDark: isDark,
                          // date: date,
                          date: formatJalaliDate(isoDate),
                        );
                      },
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  // child: Text('خطا در بارگذاری مقالات: ${snapshot.error}'),
                  child: Text(
                    AppStrings.error_in_loading,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.text_primary_dark
                          : AppColors.text_primary_light,
                    ),
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),

          // RealBlogCarousel(),
          // FakeBlogCarousel(),
        ],
      ),
    );
  }

  /*
  // تابع برای گرفتن پست‌ها از لوکال یا آنلاین + ذخیره
  Future<List<dynamic>> _getPosts() async {
    var box = Hive.box('blogPosts'); // باز کردن باکس

    // اگر در لوکال وجود داشت، برگردون
    final storedPosts = box.get('recentPosts');
    if (storedPosts != null && storedPosts is List<dynamic>) {
      return storedPosts;
    }

    // اگر نبود، از API بگیر و ذخیره کن
    final response = await http.get(
      Uri.parse('https://sornaz.com/wp-json/wp/v2/posts?per_page=10&_embed'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      await box.put('recentPosts', data); // ذخیره در لوکال
      return data;
    } else {
      throw Exception('Failed to load recent posts');
    }
  }
*/
}

class RealBlogCard extends StatelessWidget {
  const RealBlogCard({
    super.key,
    required this.post,
    required this.imageUrl,
    required this.title,
    required this.date,
    required this.isDark,
  });

  final dynamic post;
  final String imageUrl;
  final dynamic title;
  final String date;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => navigateWithFade(context, ArticleDetailPage(post: post)),
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface_dark : AppColors.surface_light,
          border: Border.all(
            color: isDark ? AppColors.border_dark : AppColors.border_light,
          ),
          borderRadius: BorderRadius.all(Radius.circular(4)),
          boxShadow: [
            BoxShadow(
              color: isDark ? AppColors.shadow_dark : AppColors.shadow_light,
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: realBlogImage,
        ),
      ),
    );
  }

  List<Widget> get realBlogImage {
    return [
      if (imageUrl.isNotEmpty)
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          child: Image.network(
            imageUrl,
            // height: 100,
            height: 85,
            width: double.infinity,
            fit: BoxFit.contain,
            alignment: AlignmentGeometry.topCenter,
          ),
        )
      else
        Container(
          height: 100,
          width: double.infinity,
          color: isDark ? AppColors.surface_dark : AppColors.surface_light,
          child: const Icon(Icons.image, size: 50),
        ),

      RealBlogInformation(title: title, date: date, isDark: isDark),
    ];
  }
}

class RealBlogInformation extends StatelessWidget {
  const RealBlogInformation({
    super.key,
    required this.title,
    required this.date,
    required this.isDark,
  });

  final dynamic title;
  final String date;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 76,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isDark
                          ? AppColors.text_primary_dark
                          : AppColors.text_primary_light,
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: Text(
                      date,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.text_secondary_dark
                            : AppColors.text_secondary_light,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// فانکشن برای گرفتن ۱۰ پست آخر
Future<List<dynamic>> fetchRecentPosts() async {
  final response = await http.get(
    Uri.parse('https://sornaz.com/wp-json/wp/v2/posts?per_page=10&_embed'),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception(AppStrings.faild_to_load_posts);
  }
}

// ---------------------------

class FakeBlogCarousel extends StatelessWidget {
  const FakeBlogCarousel({super.key});

  get listSize => 4;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: listSize,
        itemBuilder: (context, index) {
          return FakeBlogCard(index: index);
        },
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
      ),
    );
  }
}

class FakeBlogCard extends StatelessWidget {
  final int index;

  const FakeBlogCard({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(240, 240, 240, 0.6),
        border: Border.all(color: Color.fromRGBO(31, 31, 31, 0.1)),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      margin: EdgeInsets.only(left: 8, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FakeBlogImage(index: index),
          FakeBlogInformation(index: index),
        ],
      ),
    );
  }
}

class FakeBlogInformation extends StatelessWidget {
  final int index;

  const FakeBlogInformation({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to maintain calorie intake & worry less $index',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            const Text(
              '5 mins read',
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class FakeBlogImage extends StatelessWidget {
  final int index;

  const FakeBlogImage({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: 160,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/blog_$index.png'),
          fit: BoxFit.cover,
        ),
        color: Colors.greenAccent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
    );
  }
}
