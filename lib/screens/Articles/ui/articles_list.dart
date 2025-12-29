import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_navigation.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Articles/article_detail_page.dart';
import 'package:sornaz/screens/Articles/provider/articles_provider.dart';

class ArticlesListWidget extends StatelessWidget {
  const ArticlesListWidget({
    super.key,
    required this.scrollController,
    required this.posts,
    required this.isLoadingMore,
    required this.isDark,
    required this.provider,
  });

  final ScrollController scrollController;
  final List<dynamic> posts;
  final bool isLoadingMore;
  final bool isDark;
  final ArticlesProvider provider;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: posts.length + 3 + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 0 → Search
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.space_16),
            child: TextField(
              onChanged: provider.updateSearchQuery,
              decoration: InputDecoration(
                hintText: AppStrings.home_searchbar_hint.translate(context),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        }

        // 1 → Categories
        if (index == 1) {
          if (provider.categories.isEmpty) {
            return const SizedBox.shrink();
          }

          return SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.categories.length,
              itemBuilder: (context, i) {
                final cat = provider.categories[i]['name'];
                final isSelected = cat == provider.selectedCategory;

                return GestureDetector(
                  onTap: () => provider.updateCategory(cat),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric( horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.surface_dark : AppColors.surface_light,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        // 2 → Spacer
        if (index == 2) {
          return const SizedBox(height: 8);
        }

        // offset for articles
        final articleIndex = index - 3;

        // loading more
        if (articleIndex == posts.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final post = posts[articleIndex];

        final title = post['title']?['rendered'] ?? AppStrings.without_title.translate(context);

        final excerpt = (post['excerpt']?['rendered'] as String?) ?.replaceAll(RegExp(r'<[^>]*>'), '') ?? AppStrings.without_briefs.translate(context);

        final featuredMedia = post['featured_media'] ?? 0;
        final imageUrl = (featuredMedia is int && featuredMedia > 0 && post['_embedded'] != null)
                ? (post['_embedded']['wp:featuredmedia']?[0] ?['source_url'] as String?) ?? ''
                : '';

        final isoDate = post['date'] as String? ?? '';

        return Container(
          decoration: BoxDecoration(
            color: articleIndex.isEven ? AppColors.background_light : AppColors.surface_light,
            border: Border.all(
              width: 1,
              color: isDark ? AppColors.border_dark : AppColors.border_light,
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
                : const Icon(Icons.image,
                    size: AppSpacing.space_48),
            title: ArticlesPageTitleWidget(title: title, isDark: isDark),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.sizedBoxH4(),
                ArticlesBriefWidget(excerpt: excerpt, isDark: isDark),
                AppSpacing.sizedBoxH8(),
                ArticlesReleaseDateWidget(isoDate: isoDate, isDark: isDark),
              ],
            ),
            onTap: () {
              navigateWithFade(
                context,
                ArticleDetailPage(post: post),
              );
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
