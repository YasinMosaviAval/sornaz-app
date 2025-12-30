import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Articles/ui/articles_list.dart';
import 'package:sornaz/screens/Home/app_drawer.dart';
import 'package:sornaz/screens/Articles/provider/articles_provider.dart';
import 'package:sornaz/screens/Home/home.dart';

class ArticlesPage extends StatelessWidget {
  const ArticlesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final isEnglish = localeProvider.locale.languageCode == AppStrings.localization_en;

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.surface_dark : AppColors.surface_light,
          elevation: 0,
          automaticallyImplyLeading: false,
          // leadingWidth: AppSpacing.space_48,
          titleSpacing: AppSpacing.space_16,
          // actionsPadding: const EdgeInsets.only(right: AppSpacing.space_0),
          leading: HeaderMenuIcon(isDark: isDark),
          title: ApplicationTitle(isDark: isDark),
          actions: [
            ApplicationLogo(isDark: isDark),
            AppSpacing.sizedBoxW24(),
          ],
        ),
        drawer: const AppDrawer(),
        body: Container(
          color: isDark ? AppColors.background_dark : AppColors.background_light,
          child: Consumer<ArticlesProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.posts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
          
              if (provider.hasError && provider.posts.isEmpty) {
                return Center(
                  child: Text(
                    AppStrings.error_in_loading.translate(context),
                    style: AppTypography.articlesErrorInLoading(context),
                  ),
                );
              }
          
              return RefreshIndicator(
                onRefresh: provider.loadInitial,
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
        bottomNavigationBar: const BottomNavBarWidget(),
      ),
    );
  }
}
