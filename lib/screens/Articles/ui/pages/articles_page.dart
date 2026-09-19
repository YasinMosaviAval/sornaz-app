import 'package:sornaz/components/home_top_bar.dart';
import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:sornaz/screens/Articles/ui/components/article_progress.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Articles/ui/components/articles_list.dart';
import 'package:sornaz/screens/Articles/provider/articles_provider.dart';

class ArticlesPage extends StatelessWidget {
  const ArticlesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;

    final localeProvider = Provider.of<LocaleProvider>(context);
    final isEnglish =
        localeProvider.locale.languageCode == AppConstants.LOCALIZATION_EN;

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: ScrollAwareScaffold(
        pinTopBar: true,
        appBar: HomeTopBar(
          searchOnly: true,
          searchTextInset: 16,
          hint: AppStrings.home_searchbar_hint.translate(context),
          onSearch: context.read<ArticlesProvider>().updateSearchQuery,
          flexibleSpace: ArticleProgressBackground(
            progress: context.read<ArticlesProvider>().progress,
            isDark: isDark,
          ),
        ),
        body: Container(
          color: AppColors.articles_page_body_background_color(isDark: isDark),
          child: Consumer<ArticlesProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.allPosts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.hasError && provider.allPosts.isEmpty) {
                return Center(
                  child: Text(
                    AppStrings.error_in_loading.translate(context),
                    style: AppTypography.articlesErrorInLoading(context),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: provider.refreshArticles,
                child: ArticlesListWidget(
                  scrollController: provider.scrollController,
                  posts: provider.posts,
                  isLoadingMore: provider.isLoadingMore,
                  isDark: isDark,
                  provider: provider,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
