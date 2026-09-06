import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_colors.dart';

class ArticleProgressBackground extends StatelessWidget {
  const ArticleProgressBackground({
    super.key,
    required this.progress,
    required this.isDark,
  });
  final ValueNotifier<double> progress;
  final bool isDark;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: progress,
    builder: (context, value, _) => LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          ColoredBox(
            color: AppColors.article_details_page_app_bar_base_color(
              isDark: isDark,
            ),
            child: const SizedBox.expand(),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: box.maxWidth * value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      AppColors.article_details_page_app_bar_progress_color(
                        isDark: isDark,
                      ),
                      AppColors.article_details_page_app_bar_progress2_color(
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
