import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_spacing.dart';
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
    final title = post['title']?['rendered'] ?? '';
    final excerpt = _stripHtml(post['excerpt']?['rendered'] ?? '');
    final imageUrl = _imageUrl(post);
    final publishDate = post['date'] ?? '';
    final modifiedDate = post['modified'] ?? '';
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
        color: isDark ? AppColors.clicked_dark : AppColors.hovered_light,
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
                          text: 'آپدیت: ${formatJalaliDate(modifiedDate)}',
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

  String _stripHtml(String html) => html.replaceAll(RegExp(r'<[^>]*>'), '');

  String _imageUrl(Map<String, dynamic> post) {
    final embedded = post['_embedded'];
    if (embedded == null) return '';
    final media = embedded['wp:featuredmedia'];
    if (media == null || media.isEmpty) return '';
    return media[0]['source_url'] ?? '';
  }

  String _authorName(Map<String, dynamic> post) {
    final embedded = post['_embedded'];
    if (embedded == null) return '';
    final authors = embedded['author'];
    if (authors == null || authors.isEmpty) return '';
    return authors[0]['name'] ?? '';
  }
}

/// 🔹 Small meta text widget
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

