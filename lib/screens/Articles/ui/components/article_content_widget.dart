import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';

// class ArticlesContentWidget extends StatelessWidget {
//   const ArticlesContentWidget({super.key, required this.content});
//   final String content;

//   @override
//   Widget build(BuildContext context) {
//     final appData = Provider.of<AppData>(context);
//     final isDark = appData.isDark;

//     return Html(
//       data: content,
//       style: {'img': Style(height: Height.auto())},
//     );
//   }
// }

class ArticlesContentWidget extends StatelessWidget {
  const ArticlesContentWidget({super.key, required this.content});

  final String content;
  // final bool isDark;

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return Html(
      data: content,
      style: {
        'body': Style(
          color: isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light,
          fontSize: FontSize(14),
          fontWeight: FontWeight.w400
        ),
        'a': Style(
          color: isDark ? AppColors.primary_dark : AppColors.primary_light,
          textDecoration: TextDecoration.underline,
        ),
        'p': Style(
          color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
        ),

        'h1': Style(
          color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
          fontSize: FontSize(20),
          fontWeight: FontWeight.w700
        ),
        'h2': Style(
          color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
          fontSize: FontSize(18),
          fontWeight: FontWeight.w700
        ),
        'h3': Style(
          color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
          fontSize: FontSize(16),
          fontWeight: FontWeight.w700
        ),
        'h4': Style(
          color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
          fontSize: FontSize(14),
          fontWeight: FontWeight.w600
        ),
        'h5': Style(
          color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
          fontSize: FontSize(14),
          fontWeight: FontWeight.w600
        ),
        'h6': Style(
          color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
          fontSize: FontSize(14),
          fontWeight: FontWeight.w600
        ),
        
        'strong': Style(
          fontWeight: FontWeight.bold,
          fontSize: FontSize(14),
        ),
        'em': Style(
          fontStyle: FontStyle.italic,
          fontSize: FontSize(14),
        ),
        'img': Style(
          width: Width(300),
          // height: Height(double.minPositive)
        ),
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
