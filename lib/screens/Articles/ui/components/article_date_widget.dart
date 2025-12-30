import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_typography.dart';

class ArticlesReleasedDateWidget extends StatelessWidget {
  const ArticlesReleasedDateWidget({super.key, required this.isoDate, required this.isDark});
  final String isoDate;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatJalaliDate(isoDate),
      style: AppTypography.articlesDetailPageArticleCommentsListReleaseDate(context),
    );
  }
}
