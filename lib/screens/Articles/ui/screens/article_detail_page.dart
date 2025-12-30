import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/app_bar.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Articles/services/article_api_service.dart';
import 'package:sornaz/screens/Articles/ui/components/article_author_widget.dart';
import 'package:sornaz/screens/Articles/ui/components/article_comments_list_widget.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Articles/ui/components/article_content_widget.dart';
import 'package:sornaz/screens/Articles/ui/components/article_date_widget.dart';
import 'package:sornaz/screens/Articles/ui/components/article_image_widget.dart';

class ArticleDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;
  const ArticleDetailPage({super.key, required this.post});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  List<dynamic> comments = [];
  List<dynamic> relatedPosts = [];
  double rating = 0.0;
  TextEditingController commentController = TextEditingController();
  bool isLoadingComments = true;
  bool isLoadingRelated = true;
  int commentPage = 1;
  bool hasMoreComments = true;
  final ScrollController _scrollController = ScrollController();

  double _scrollProgress = 0.0;

  void _onScroll() {
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;

    setState(() {
      _scrollProgress = (current / max).clamp(0.0, 1.0);
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchComments();
    _fetchRelatedPosts();
    _scrollController.addListener(_scrollListener);
    _scrollController.addListener(_onScroll);

    _scrollController.addListener(() {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      setState(() {
        _scrollProgress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      });
    });

  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent - 200 && !_scrollController.position.outOfRange && hasMoreComments) {
      commentPage++;
      _fetchComments(loadMore: true);
    }
  }

  Future<void> _fetchComments({bool loadMore = false}) async {
    final postId = widget.post['id'];
    final newComments = await ArticleApiService.fetchComments(postId, commentPage);
    setState(() {
      if (loadMore) {
        comments.addAll(newComments);
      } else {
        comments = newComments;
      }
      if (newComments.isEmpty) hasMoreComments = false;
      isLoadingComments = false;
    });
  }

  Future<void> _fetchRelatedPosts() async {
    final categories = widget.post['categories'] as List?;
    if (categories == null || categories.isEmpty) {
      setState(() => isLoadingRelated = false);
      return;
    }
    final catId = categories[0];
    final postId = widget.post['id'];
    final related = await ArticleApiService.fetchRelatedPosts(postId, catId);
    setState(() {
      relatedPosts = related;
      isLoadingRelated = false;
    });
  }

  Future<void> _sendComment() async {
    final postId = widget.post['id'];
    final content = commentController.text;
    if (content.isEmpty) return;

    final success = await ArticleApiService.sendComment(
      postId,
      content,
      AppStrings.guest_user.translate(context),
    );
    if (success) {
      commentController.clear();
      _fetchComments();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          AppStrings.error_in_sending_comment.translate(context),
          style: AppTypography.articlesDetailPageErrorInSendingComment(context),
        )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.post['title']['rendered'] ?? AppStrings.without_title.translate(context);
    final content = widget.post['content']['rendered'] ?? AppStrings.without_content.translate(context);
    final imageUrl = widget.post['_embedded']?['wp:featuredmedia']?[0]?['source_url'] ?? '';
    final author = widget.post['_embedded']?['author']?[0]?['name'] ?? AppStrings.unknown.translate(context);
    final isoDate = widget.post['date'] as String? ?? '';

    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;

    return Scaffold(
      appBar: AppBar(
        foregroundColor: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
        titleSpacing: 0,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.headline3(context),
        ),
        elevation: 0,
        flexibleSpace: _AppBarProgressBackground(
          progress: _scrollProgress,
          isDark: isDark,
        ),
      ),
      backgroundColor: isDark ? AppColors.background_dark : AppColors.background_light,
      // SornazAppBar(title: title),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.space_16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty) ArticlesImageWidget(imageUrl: imageUrl),
              const SizedBox(height: AppSpacing.space_16),
              ArticlesAuthorWidget(author: author, isDark: isDark),
              ArticlesReleasedDateWidget(isoDate: isoDate, isDark: isDark),
              const SizedBox(height: AppSpacing.space_16),
              ArticlesContentWidget(content: content),
              const SizedBox(height: AppSpacing.space_32),
              if (isLoadingRelated)
                const Center(child: CircularProgressIndicator())
              else
                ...relatedPosts.map((related) {
                  final relTitle = related['title']['rendered'] ?? '';
                  final relImage = related['_embedded']?['wp:featuredmedia']?[0]?['source_url'] ?? '';
                  final relDate = related['date'] as String? ?? '';
                  return ListTile(
                    leading: relImage.isNotEmpty ? Image.network(relImage, width: AppSpacing.space_100, fit: BoxFit.cover) : const Icon(Icons.image),
                    title: Text(relTitle, style: AppTypography.articlesDetailPageSimilarArticlesItemTitle(context)),
                    subtitle: Text(relDate, style: AppTypography.articlesDetailPageSimilarArticlesItemSubtitle(context)),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleDetailPage(post: related))),
                  );
                }),
              const SizedBox(height: AppSpacing.space_32),
              Text('${AppStrings.take_your_point_to_article.translate(context)}:', style: AppTypography.articlesDetailPageSendStarPoint(context)),
              // rating bar here...
              const SizedBox(height: AppSpacing.space_16),
              Text('${AppStrings.write_your_comments.translate(context)}:', style: AppTypography.articlesDetailPageWriteComment(context)),
              TextField(controller: commentController, decoration: InputDecoration(border: OutlineInputBorder())),
              ElevatedButton(onPressed: _sendComment, child: Text(AppStrings.send_comment.translate(context))),
              const SizedBox(height: AppSpacing.space_32),
              if (isLoadingComments)
                const Center(child: CircularProgressIndicator())
              else
                ...comments.map((comment) {
                  final comContent = comment['content']['rendered'].replaceAll(RegExp(r'<[^>]*>'), '');
                  final comAuthor = comment['author_name'] ?? '';
                  final comAvatar = comment['author_avatar_urls']?['96'] ?? '';
                  final comDate = comment['date'] as String? ?? '';
                  return ArticleCommentsListWidget(comAvatar: comAvatar, comAuthor: comAuthor, comContent: comContent, comDate: comDate, isDark: isDark);
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBarProgressBackground extends StatelessWidget {
  final double progress;
  final bool isDark;

  const _AppBarProgressBackground({
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? AppColors.surface_dark : AppColors.surface_light;

    final progressColor = isDark ? AppColors.primary_dark : AppColors.primary_light;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // بک‌گراند اصلی AppBar
            Container(color: baseColor),

            // لایه پروگرس
            Align(
              alignment: Alignment.centerRight, // RTL
              child: Container(
                width: constraints.maxWidth * progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      progressColor.withAlpha(50),
                      progressColor.withAlpha(50),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
