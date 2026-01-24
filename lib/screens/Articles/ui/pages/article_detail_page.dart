import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_constants.dart';
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
    final postId = widget.post[AppConstants.ID];
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
    final categories = widget.post[AppConstants.CATEGORIES] as List?;
    if (categories == null || categories.isEmpty) {
      setState(() => isLoadingRelated = false);
      return;
    }
    final catId = categories[0];
    final postId = widget.post[AppConstants.ID];
    final related = await ArticleApiService.fetchRelatedPosts(postId, catId);
    setState(() {
      relatedPosts = related;
      isLoadingRelated = false;
    });
  }

  Future<void> _sendComment() async {
    final postId = widget.post[AppConstants.ID];
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
    final title = widget.post[AppConstants.TITLE][AppConstants.RENDERED] ?? AppStrings.without_title.translate(context);
    final content = widget.post[AppConstants.CONTENT][AppConstants.RENDERED] ?? AppStrings.without_content.translate(context);
    final imageUrl = widget.post[AppConstants.UNDERLINE_EMBEDDED]?[AppConstants.WP_FEATUREDMEDIA]?[0]?[AppConstants.SOURCE_URL] ?? '';
    final author = widget.post[AppConstants.UNDERLINE_EMBEDDED]?[AppConstants.AUTHOR]?[0]?[AppConstants.NAME] ?? AppStrings.unknown.translate(context);
    final isoDate = widget.post[AppConstants.DATE] as String? ?? '';

    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;

    return Scaffold(
      appBar: AppBar(
        foregroundColor: AppColors.article_details_page_app_bar_foreground_color(isDark: isDark),
        titleSpacing: 0,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.articleDetailsPageAppBar(context),
        ),
        elevation: 0,
        flexibleSpace: _AppBarProgressBackground(
          progress: _scrollProgress,
          isDark: isDark,
        ),
      ),
      backgroundColor: AppColors.article_details_page_background_color(isDark: isDark),
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
                  final relTitle = related[AppConstants.TITLE][AppConstants.RENDERED] ?? '';
                  final relImage = related[AppConstants.UNDERLINE_EMBEDDED]?[AppConstants.WP_FEATUREDMEDIA]?[0]?[AppConstants.SOURCE_URL] ?? '';
                  final relDate = related[AppConstants.DATE] as String? ?? '';
                  return ListTile(
                    leading: relImage.isNotEmpty ? Image.network(relImage, width: AppSpacing.space_100, fit: BoxFit.cover) : const Icon(Icons.image),
                    title: Text(
                      relTitle,
                      style: AppTypography.articlesDetailPageSimilarArticlesItemTitle(context)
                    ),
                    subtitle: Text(
                      relDate,
                      style: AppTypography.articlesDetailPageSimilarArticlesItemSubtitle(context)
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ArticleDetailPage(post: related))
                    ),
                  );
                }),
              const SizedBox(height: AppSpacing.space_32),
              Text(
                '${AppStrings.take_your_point_to_article.translate(context)}:',
                style: AppTypography.articlesDetailPageSendStarPoint(context)
              ),
              // rating bar here...
              const SizedBox(height: AppSpacing.space_16),
              Text(
                '${AppStrings.write_your_comments.translate(context)}:',
                style: AppTypography.articlesDetailPageWriteComment(context)
              ),
              TextField(controller: commentController, decoration: InputDecoration(border: OutlineInputBorder())),
              ElevatedButton(onPressed: _sendComment, child: Text(AppStrings.send_comment.translate(context))),
              const SizedBox(height: AppSpacing.space_32),
              if (isLoadingComments)
                const Center(child: CircularProgressIndicator())
              else
                ...comments.map((comment) {
                  // final comContent = comment[AppConstants.CONTENT][AppConstants.RENDERED].replaceAll(RegExp(r'<[^>]*>'), '');
                  final comContent = comment[AppConstants.CONTENT][AppConstants.RENDERED].replaceAll(RegExp(AppConstants.STRIP_HTML_REGEX), '');
                  final comAuthor = comment[AppConstants.AUTHOR_NAME] ?? '';
                  final comAvatar = comment[AppConstants.AUTHOR_AVATAR_URLS]?[AppConstants.NUMBER_96] ?? '';
                  final comDate = comment[AppConstants.DATE] as String? ?? '';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // بک‌گراند اصلی AppBar
            Container(color: AppColors.article_details_page_app_bar_base_color(isDark: isDark)),

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
                      AppColors.article_details_page_app_bar_progress_color(isDark: isDark),
                      AppColors.article_details_page_app_bar_progress2_color(isDark: isDark),
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
