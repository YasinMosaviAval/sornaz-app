import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Articles/ui/components/article_format.dart';
import 'package:sornaz/screens/Articles/ui/pages/article_detail_page.dart';

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
    final image = articleImage(post),
        published = '${post['date'] ?? ''}',
        modified = '${post['modified'] ?? ''}';
    final authors = post['_embedded']?['author'];
    final author = authors is List && authors.isNotEmpty
        ? '${authors.first['name'] ?? ''}'
        : '';
    final en = Localizations.localeOf(context).languageCode == 'en';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: AppColors.article_item_box_decoration_color(isDark: isDark),
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ArticleDetailPage(post: post)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Column(
                    children: [
                      image.isEmpty
                          ? const SizedBox(
                              height: 60,
                              child: Icon(Icons.image_outlined),
                            )
                          : CachedNetworkImage(
                              imageUrl: image,
                              width: 100,
                              height: 60,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => const SizedBox(
                                height: 60,
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                      const SizedBox(height: 12),
                      Text(
                        articleDate(context, published),
                        textAlign: TextAlign.center,
                        style: AppTypography.articlesReleaseDate(context),
                      ),
                      if (author.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          author,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTypography.articlesReleaseDate(context),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        articlePlain('${post['title']?['rendered'] ?? ''}'),
                        style: AppTypography.articlesTitle(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        articlePlain('${post['excerpt']?['rendered'] ?? ''}'),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.justify,
                        style: AppTypography.articlesBrief(context),
                      ),
                      if (modified.isNotEmpty && modified != published) ...[
                        const SizedBox(height: 8),
                        Text(
                          (en ? 'Updated: ' : 'به‌روزرسانی: ') +
                              articleDate(context, modified),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.articlesReleaseDate(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
