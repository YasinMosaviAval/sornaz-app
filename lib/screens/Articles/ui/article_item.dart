import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_navigation.dart';
import 'package:sornaz/screens/Articles/article_detail_page.dart';

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
    final excerpt = _stripHtml(
      post['excerpt']?['rendered'] ?? '',
    );
    final imageUrl = _imageUrl(post);
    final date = post['date'] ?? '';

    return Container(
      margin: EdgeInsets.fromLTRB(
        AppSpacing.space_16, 
        AppSpacing.space_16,
        AppSpacing.space_16, 
        AppSpacing.space_0
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.space_4)),
        color: isDark ? AppColors.hovered_dark : AppColors.hovered_light,
      ),

      child: ListTile(
        leading: imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              width: AppSpacing.space_100,
              fit: BoxFit.cover,
            )
          : const Icon(Icons.image),
        title: Text(
          title,
          style: AppTypography.articlesTitle(context),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.sizedBoxH8(),
            Text(
              excerpt,
              maxLines: 2,
              textAlign: TextAlign.justify,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.articlesBrief(context),
            ),
            AppSpacing.sizedBoxH8(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  formatJalaliDate(date),
                  style: AppTypography.articlesReleaseDate(context),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          navigateWithFade(
            context,
            ArticleDetailPage(post: post),
          );
        },
      ),
    );
  }

  String _stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]*>'), '');

  String _imageUrl(Map<String, dynamic> post) {
    final embedded = post['_embedded'];
    if (embedded == null) return '';
    final media = embedded['wp:featuredmedia'];
    if (media == null || media.isEmpty) return '';
    return media[0]['source_url'] ?? '';
  }
}
