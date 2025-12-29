import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/screens/Articles/ui/articles_list.dart';
import 'package:sornaz/screens/Home/app_drawer.dart';
import 'package:sornaz/screens/Home/home.dart';
import '../provider/articles_provider.dart';
import 'package:sornaz/helpers/app_typography.dart';

class ArticlesPage extends StatefulWidget {
  const ArticlesPage({super.key});

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  @override
  void initState() {
    super.initState();
    context.read<ArticlesProvider>().init();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppData>().isDark;
    final provider = context.watch<ArticlesProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surface_dark : AppColors.surface_light,
        elevation: 0,
        leading: HeaderMenuIcon(isDark: isDark),
        title: ApplicationTitle(isDark: isDark),
        actions: [ApplicationLogo(isDark: isDark)],
      ),
      drawer: const AppDrawer(),
      backgroundColor: isDark ? AppColors.background_dark : AppColors.background_light,
      body: _buildBody(provider, isDark),
      bottomNavigationBar: const BottomNavBarWidget(),
    );
  }

  Widget _buildBody(ArticlesProvider provider, bool isDark) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.hasError) {
      return Center(
        child: Text(
          AppStrings.error_in_loading,
          style: AppTypography.articlesErrorInLoading(context),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchInitial,
      child: ArticlesListWidget(
        posts: provider.posts,
        controller: provider.scrollController,
        isLoadingMore: provider.isLoadingMore,
        isDark: isDark,
      ),
    );
  }
}
