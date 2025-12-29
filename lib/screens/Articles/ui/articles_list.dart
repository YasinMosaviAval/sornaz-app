import 'package:flutter/material.dart';
import 'package:sornaz/screens/Articles/ui/article_item.dart';

class ArticlesListWidget extends StatelessWidget {
  const ArticlesListWidget({
    super.key,
    required this.posts,
    required this.controller,
    required this.isLoadingMore,
    required this.isDark,
  });

  final List<dynamic> posts;
  final ScrollController controller;
  final bool isLoadingMore;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemCount: posts.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == posts.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return ArticleItemWidget(
          post: posts[index],
          isDark: isDark,
        );
      },
    );
  }
}
