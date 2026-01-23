import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_typography.dart';

class ArticlesContentWidget extends StatelessWidget {
  const ArticlesContentWidget({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return Html(
      data: content,
      style: {
        AppConstants.HTML_A: AppTypography.articleContentHtmlA(context: context, isDark: isDark),
        AppConstants.HTML_P: AppTypography.articleContentHtmlP(context: context, isDark: isDark),
        AppConstants.HTML_H1: AppTypography.articleContentHtmlH1(context: context, isDark: isDark),
        AppConstants.HTML_H2: AppTypography.articleContentHtmlH2(context: context, isDark: isDark),
        AppConstants.HTML_H3: AppTypography.articleContentHtmlH3(context: context, isDark: isDark),
        AppConstants.HTML_H4: AppTypography.articleContentHtmlH4(context: context, isDark: isDark),
        AppConstants.HTML_H5: AppTypography.articleContentHtmlH5(context: context, isDark: isDark),
        AppConstants.HTML_H6: AppTypography.articleContentHtmlH6(context: context, isDark: isDark),
        AppConstants.HTML_EM: AppTypography.articleContentHtmlEm(context: context, isDark: isDark),
        AppConstants.HTML_IMG: AppTypography.articleContentHtmlImg(context: context, isDark: isDark),
        AppConstants.HTML_BODY: AppTypography.articleContentHtmlBody(context: context, isDark: isDark),
        AppConstants.HTML_STRONG: AppTypography.articleContentHtmlStrong(context: context, isDark: isDark),
      },
      // onLinkTap: (url, context, attributes, element) {
      //   if (url != null) {
      //     // لینک رو باز کن
      //     launchUrl(Uri.parse(url));
      //   }
      // },
    );
  }
}
