import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';
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
  final bool isLoadingMore, isDark;
  final ArticlesProvider provider;
  @override
  Widget build(BuildContext context) {
    final filters = [
      {'id': null, 'name': AppStrings.all.translate(context)},
      ...provider.categories,
    ];
    return ListView.builder(
      key: const Key('article-list'),
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: posts.length + 3,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.all(16),
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
        if (index == 1) {
          return SingleChildScrollView(
            key: const Key('article-filters'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (var i = 0; i < filters.length; i++) ...[
                  if (i > 0) const SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => provider.updateCategory(
                        filters[i]['id']?.toString() ?? AppStrings.all,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: filters[i]['id'] == provider.selectedCategoryId
                              ? AppColors.article_list_selected_box_decoration_color(
                                  isDark: isDark,
                                )
                              : AppColors.article_list_unselected_box_decoration_color(
                                  isDark: isDark,
                                ),
                        ),
                        child: Text(
                          '${filters[i]['name']}',
                          style: filters[i]['id'] == provider.selectedCategoryId
                              ? AppTypography.articlesListSelectedCategory(
                                  context,
                                )
                              : AppTypography.articlesListUnselectedCategory(
                                  context,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        if (index == 2) {
          return posts.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    provider.locale == 'en'
                        ? 'No articles match this filter.'
                        : 'مقاله‌ای با این فیلتر پیدا نشد.',
                  ),
                )
              : const SizedBox(height: 8);
        }
        return ArticleItemWidget(
          key: ValueKey(posts[index - 3]['id']),
          post: Map<String, dynamic>.from(posts[index - 3]),
          isDark: isDark,
        );
      },
    );
  }
}
