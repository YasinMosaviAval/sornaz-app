import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Articles/provider/articles_provider.dart';
import 'package:sornaz/screens/Articles/ui/components/article_item.dart';

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
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.categories.length,
              itemBuilder: (context, i) {
                final cat = provider.categories[i]['name'];
                final isSelected = cat == provider.selectedCategory;

                return GestureDetector(
                  onTap: () => provider.updateCategory(cat),
                  child: Container(
                    margin: EdgeInsets.fromLTRB(
                      i == provider.categories.length - 1 ? AppSpacing.space_16 : AppSpacing.space_0,
                      AppSpacing.space_8,
                      AppSpacing.space_16,
                      AppSpacing.space_8
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space_12, vertical: AppSpacing.space_8),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? isDark ? AppColors.primary_dark : AppColors.primary_light
                        : isDark ? AppColors.surface_dark : AppColors.surface_light,
                      borderRadius: BorderRadius.circular(AppSpacing.space_4),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: isSelected ? AppTypography.body_reverse2(context) : AppTypography.body2(context),
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

        return ArticleItemWidget(post: post, isDark: isDark);
      },
    );
  }
}
