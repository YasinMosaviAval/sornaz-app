// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/section_title.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_navigation.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Articles/ui/pages/article_detail_page.dart';
import 'package:sornaz/screens/Articles/ui/pages/articles_page.dart';
import 'package:sornaz/screens/Articles/services/article_api_service.dart';



class BlogCarousel extends StatelessWidget {
  const BlogCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    // final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(color: AppColors.blog_carousel_decoration_color(isDark: isDark)),
      foregroundDecoration: BoxDecoration(color: AppColors.blog_carousel_foreground_decoration_color(isDark: isDark)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.space_0,
          AppSpacing.space_24,
          AppSpacing.space_0,
          AppSpacing.space_0,
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.space_24,
                AppSpacing.space_0,
                AppSpacing.space_24,
                AppSpacing.space_16,
              ),
              child: SectionTitle(
                title: AppStrings.last_blog_title.translate(context),
                viewAll: AppStrings.view_all_link.translate(context),
                viewAllLink: ArticlesPage(),
              ),
            ),
            FutureBuilder<List<dynamic>>(
              future: fetchRecentPosts(context),
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
                          final title = post[AppConstants.TITLE][AppConstants.RENDERED] ?? AppStrings.no_title.translate(context);
                          // final excerpt =
                          //     (post['excerpt']['rendered'] as String?)?.replaceAll(
                          //       RegExp(r'<[^>]*>'),
                          //       '',
                          //     ) ??
                          //     'بدون خلاصه';
                          final featuredMedia = post[AppConstants.FEATURED_MEDIA];
                          final imageUrl = (featuredMedia is int && featuredMedia > 0 && post[AppConstants.UNDERLINE_EMBEDDED] != null)
                              ? (post[AppConstants.UNDERLINE_EMBEDDED][AppConstants.WP_FEATUREDMEDIA]?[0]?[AppConstants.SOURCE_URL] as String?) ?? ''
                              : '';
                          // final date = (post['date'] as String?)?.substring(0, 10) ?? 'نامشخص';

                          final isoDate = post[AppConstants.DATE] as String? ?? AppConstants.EMPTY_TEXT;
                          return BlogCard(
                            post: post,
                            imageUrl: imageUrl,
                            title: title,
                            isDark: isDark,
                            // date: date,
                            date: formatJalaliDate(isoDate),
                          );
                        },
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.space_16,
                          AppSpacing.space_0,
                          AppSpacing.space_16,
                          AppSpacing.space_0,
                        ),
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      AppStrings.error_in_loading.translate(context),
                      style: AppTypography.blogCarouselErrorInLoading(context),
                    ),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),

            // BlogCarousel(),
          ],
        ),
      ),
    );
  }
}

class BlogCard extends StatelessWidget {
  const BlogCard({
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
        width: AppSpacing.space_150,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space_8),
        decoration: BoxDecoration(
          color: AppColors.blog_card_decoration_color(isDark),
          border: Border.all(color: AppColors.blog_card_border_color(isDark)),
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.space_4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.blog_card_box_shadow_color(isDark),
              blurRadius: AppSpacing.space_4,
              spreadRadius: AppSpacing.space_1,
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
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.space_4),
          ),
          child: Image.network(
            imageUrl,
            // height: 100,
            height: AppSpacing.space_85,
            width: double.infinity,
            fit: BoxFit.contain,
            alignment: AlignmentGeometry.topCenter,
          ),
        )
      else
        Container(
          height: AppSpacing.space_100,
          width: double.infinity,
          color: AppColors.blog_card_empty_image_color(isDark),
          child: const Icon(Icons.image, size: AppSpacing.space_50),
        ),

      BlogInformation(title: title, date: date, isDark: isDark),
    ];
  }
}

class BlogInformation extends StatelessWidget {
  const BlogInformation({
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
      width: AppSpacing.space_160,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space_8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: AppSpacing.space_76,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.blogCarouselTitle(context),
                  ),
                  SizedBox(
                    width: AppSpacing.space_170,
                    child: Text(
                      date,
                      style: AppTypography.blogCarouselDate(context),
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
Future<List<dynamic>> fetchRecentPosts(BuildContext context) async {
  try {
    return await ArticleApiService.fetchPosts(page: 1);
  } catch (_) {
    throw Exception(AppStrings.failed_to_load_posts.translate(context));
  }
}
