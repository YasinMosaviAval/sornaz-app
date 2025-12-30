import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_functions.dart';

class ArticleCommentsListWidget extends StatelessWidget {
  const ArticleCommentsListWidget({
    super.key,
    required this.comAvatar,
    required this.comAuthor,
    required this.comContent,
    required this.comDate,
    required this.isDark,
  });

  final String comAvatar;
  final String comAuthor;
  final String comContent;
  final String comDate;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: comAvatar.isNotEmpty ? NetworkImage(comAvatar) : null,
        child: comAvatar.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(
        comAuthor,
        style: AppTypography.articlesDetailPageArticleCommentsListTitle(context),
      ),
      subtitle: Text(
        comContent,
        style: AppTypography.articlesDetailPageArticleCommentsListSubtitle(context),
      ),
      trailing: Text(
        formatJalaliDate(comDate),
        style: AppTypography.articlesDetailPageArticleCommentsListDate(context),
      ),
    );
  }
}
