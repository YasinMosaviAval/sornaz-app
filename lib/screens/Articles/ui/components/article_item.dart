import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_navigation.dart';
import 'package:sornaz/screens/Articles/ui/screens/article_detail_page.dart';

class ArticleItemWidget extends StatelessWidget {
  const ArticleItemWidget({
    super.key,
    required this.post,
    required this.isDark,
  });

  final Map<String, dynamic> post;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final title = post[AppConstants.TITLE]?[AppConstants.RENDERED] ?? '';
    final excerpt = _stripHtml(post[AppConstants.EXCERPT]?[AppConstants.RENDERED] ?? '');
    final imageUrl = _imageUrl(post);
    final publishDate = post[AppConstants.DATE] ?? '';
    final modifiedDate = post[AppConstants.MODIFIED] ?? '';
    final authorName = _authorName(post);

    return Container(
      margin: EdgeInsets.fromLTRB(
        AppSpacing.space_16, 
        AppSpacing.space_16,
        AppSpacing.space_16, 
        AppSpacing.space_0
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.space_4)),
        color: AppColors.article_item_box_decoration_color(isDark: isDark),
      ),
      padding: const EdgeInsets.all(AppSpacing.space_12),

      child: InkWell(
        onTap: () => navigateWithFade(context, ArticleDetailPage(post: post),),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: AppSpacing.space_100,
              // height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: AppSpacing.space_100,
                          height: AppSpacing.space_60,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image),
            
                  AppSpacing.sizedBoxH16(),
            
                  Column(
                    children: [
                      _MetaText(
                        text: formatJalaliDate(publishDate),
                        context: context,
                      ),
            
                      AppSpacing.sizedBoxH8(),
            
                      if (authorName.isNotEmpty)
                        _MetaText(
                          text: authorName,
                          context: context,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            AppSpacing.sizedBoxW12(),

            /// TITLE + EXCERPT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.articlesTitle(context),
                  ),
                  AppSpacing.sizedBoxH8(),
                  Text(
                    excerpt,
                    maxLines: 3,
                    textAlign: TextAlign.justify,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.articlesBrief(context),
                  ),
                  AppSpacing.sizedBoxH8(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (modifiedDate.isNotEmpty && modifiedDate != publishDate)
                        _MetaText(
                          text: '${AppStrings.update.translate(context)}: ${formatJalaliDate(modifiedDate)}',
                          context: context,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]
        )
      )
    );
  }


  
  // ---------------- helpers ----------------

  String _stripHtml(String html) => html.replaceAll(RegExp(AppConstants.STRIP_HTML_REGEX), '');

  String _imageUrl(Map<String, dynamic> post) {
    final embedded = post[AppConstants.UNDERLINE_EMBEDDED];
    if (embedded == null) return '';
    final media = embedded[AppConstants.WP_FEATUREDMEDIA];
    if (media == null || media.isEmpty) return '';
    return media[0][AppConstants.SOURCE_URL] ?? '';
  }

  String _authorName(Map<String, dynamic> post) {
    final embedded = post[AppConstants.UNDERLINE_EMBEDDED];
    if (embedded == null) return '';
    final authors = embedded[AppConstants.AUTHOR];
    if (authors == null || authors.isEmpty) return '';
    return authors[0][AppConstants.NAME] ?? '';
  }
}


class _MetaText extends StatelessWidget {
  const _MetaText({
    required this.text,
    required this.context,
  });

  final String text;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: AppTypography.articlesReleaseDate(context).copyWith(
        fontSize: 10,
      ),
    );
  }
}

