import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/components/section_title.dart';
import 'package:sornaz/screens/Articles/provider/articles_provider.dart';
import 'package:sornaz/screens/Articles/ui/components/article_item.dart';
import 'package:sornaz/screens/Articles/ui/pages/articles_page.dart';

class BlogCarousel extends StatelessWidget {
  const BlogCarousel({super.key});
  @override
  Widget build(BuildContext context) {
    final library = context.watch<ArticlesProvider>();
    final dark = context.watch<AppData>().isDark;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SectionTitle(
            title: AppStrings.last_blog_title.translate(context),
            viewAll: AppStrings.view_all_link.translate(context),
            viewAllLink: const ArticlesPage(),
          ),
        ),
        for (final post in library.allPosts.take(3))
          ArticleItemWidget(post: post, isDark: dark),
      ],
    );
  }
}

Future<List<dynamic>> fetchRecentPosts(BuildContext context) async =>
    context.read<ArticlesProvider>().allPosts.take(10).toList();
