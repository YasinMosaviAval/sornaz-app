import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';

class ArticlesAuthorWidget extends StatelessWidget {
  const ArticlesAuthorWidget({super.key, required this.author, required this.isDark});
  final String author;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${AppStrings.writer.translate(context)}: $author',
      style: AppTypography.articlesDetailPageArticlesAuthorsName(context),
    );
  }
}
