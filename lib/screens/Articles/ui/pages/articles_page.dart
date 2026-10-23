import 'package:sornaz/components/home_top_bar.dart';
import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:sornaz/screens/Articles/ui/components/article_progress.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/main_tab_scaffold.dart';
import 'package:sornaz/components/app_scroll_behavior.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';

import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Articles/ui/components/articles_list.dart';
import 'package:sornaz/screens/Articles/provider/articles_provider.dart';

class ArticlesPage extends StatefulWidget {
  const ArticlesPage({super.key, this.asHome = false});
  final bool asHome;

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  final scrollController = ScrollController();
  final progress = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    scrollController.addListener(updateProgress);
  }

  void updateProgress() {
    if (!scrollController.hasClients) return;
    final max = scrollController.position.maxScrollExtent;
    progress.value = max > 0 ? (scrollController.offset / max).clamp(0, 1) : 0;
  }

  @override
  void dispose() {
    scrollController.dispose();
    progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;

    final localeProvider = Provider.of<LocaleProvider>(context);
    final isEnglish =
        localeProvider.locale.languageCode == AppConstants.LOCALIZATION_EN;

    final bar = HomeTopBar(
      searchOnly: !widget.asHome,
      showLogo:
          !widget.asHome ||
          !(context.watch<AuthSession?>()?.isAuthenticated ?? false),
      hint: AppStrings.home_searchbar_hint.translate(context),
      onSearch: (query) {
        context.read<ArticlesProvider>().updateSearchQuery(query);
        if (scrollController.hasClients) scrollController.jumpTo(0);
        progress.value = 0;
      },
      initialQuery: context.read<ArticlesProvider>().searchQuery,
      flexibleSpace: ArticleProgressBackground(
        progress: progress,
        isDark: isDark,
      ),
    );
    final body = ScrollConfiguration(
      behavior: const AppScrollBehavior(),
      child: Container(
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
                scrollController: scrollController,
                posts: provider.posts,
                isLoadingMore: provider.isLoadingMore,
                isDark: isDark,
                provider: provider,
              ),
            );
          },
        ),
      ),
    );
    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: widget.asHome
          ? MainTabScaffold(index: 0, appBar: bar, body: body)
          : ScrollAwareScaffold(pinTopBar: true, appBar: bar, body: body),
    );
  }
}
