// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchComments();
    _fetchRelatedPosts();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        isLoadingComments = true;
      });
    }
    final postId = widget.post['id'];
    final url =
        'https://sornaz.com/wp-json/wp/v2/comments?post=$postId&per_page=10&page=$commentPage';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final newComments = json.decode(response.body);
        setState(() {
          if (loadMore) {
            comments.addAll(newComments);
          } else {
            comments = newComments;
          }
          if (newComments.isEmpty) hasMoreComments = false;
          isLoadingComments = false;
        });
      } else {
        setState(() {
          isLoadingComments = false;
          hasMoreComments = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingComments = false;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_scrollController.position.outOfRange &&
        hasMoreComments) {
      commentPage++;
      _fetchComments(loadMore: true);
    }
  }

  Future<void> _sendComment() async {
    final postId = widget.post['id'];
    final content = commentController.text;
    if (content.isEmpty) return;

    final url = 'https://sornaz.com/wp-json/wp/v2/comments';
    final body = json.encode({
      'post': postId,
      'content': content,
      'author_name': AppStrings.guest_user.translate(context),
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 201) {
        commentController.clear();
        _fetchComments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.error_in_sending_comment.translate(context),
              style: AppTypography.articlesDetailPageErrorInSendingComment(
                context,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.error_in_sending_comment.translate(context),
            style: AppTypography.articlesDetailPageErrorInSendingComment(
              context,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _fetchRelatedPosts() async {
    setState(() {
      isLoadingRelated = true;
    });
    final postId = widget.post['id'];
    final categories = widget.post['categories'] as List?;
    if (categories == null || categories.isEmpty) {
      setState(() {
        isLoadingRelated = false;
      });
      return;
    }
    final catId = categories[0];
    final url =
        'https://sornaz.com/wp-json/wp/v2/posts?categories=$catId&per_page=2&exclude=$postId&_embed';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          relatedPosts = json.decode(response.body);
          isLoadingRelated = false;
        });
      } else {
        setState(() {
          isLoadingRelated = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingRelated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.post['title']['rendered'] ??
        AppStrings.without_title.translate(context);
    final content =
        widget.post['content']['rendered'] ??
        AppStrings.without_content.translate(context);
    final imageUrl =
        widget.post['_embedded']?['wp:featuredmedia']?[0]?['source_url'] ??
        AppStrings.epmty_text;
    final author =
        widget.post['_embedded']?['author']?[0]?['name'] ??
        AppStrings.unknown.translate(context);
    final isoDate = widget.post['date'] as String? ?? AppStrings.epmty_text;
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return Scaffold(
      appBar: AppBar(
        title: ArticlesPageTitleWidget(title: title, isDark: isDark),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
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
              else if (relatedPosts.isNotEmpty)
                ...similarArticles(context),
              const SizedBox(height: AppSpacing.space_32),
              sendStarPointForArticles(isDark),
              const SizedBox(height: AppSpacing.space_16),
              sendCommentBox(),
              const SizedBox(height: AppSpacing.space_32),
              if (isLoadingComments)
                const Center(child: CircularProgressIndicator())
              else ...[
                articlesCommentsList(isDark),
              ],
              if (hasMoreComments && !isLoadingComments)
                loadMoreArticleComments(),
            ],
          ),
        ),
      ),
    );
  }

  Padding loadMoreArticleComments() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space_16),
      child: ElevatedButton(
        onPressed: () {
          commentPage++;
          _fetchComments(loadMore: true);
        },
        child: Text(
          AppStrings.load_more_comments.translate(context),
          style: AppTypography.articlesDetailPageLoadMoreComments(context),
        ),
      ),
    );
  }

  Column articlesCommentsList(bool isDark) {
    return Column(
      children: [
        Text(
          '${AppStrings.comments.translate(context)}:',
          style: AppTypography.articlesDetailPageCommentsListTitle(context),
        ),
        const SizedBox(height: AppSpacing.space_8),
        if (comments.isEmpty)
          Text(
            AppStrings.without_comments.translate(context),
            style: AppTypography.articlesDetailPageCommentsListEmptyTitle(
              context,
            ),
          )
        else
          ...comments.map((comment) {
            final comContent = comment['content']['rendered'].replaceAll(
              RegExp(r'<[^>]*>'),
              '',
            );
            final comAuthor =
                comment['author_name'] ?? AppStrings.unknown.translate(context);
            final comAvatar = comment['author_avatar_urls']?['96'] ?? '';
            final comDate = comment['date'] as String? ?? '';

            return ArticleCommentsListWidget(
              comAvatar: comAvatar,
              comAuthor: comAuthor,
              comContent: comContent,
              comDate: comDate,
              isDark: isDark,
            );
          }),
      ],
    );
  }

  Column sendStarPointForArticles(bool isDark) {
    return Column(
      children: [
        Text(
          '${AppStrings.take_your_point_to_article.translate(context)}:',
          style: AppTypography.articlesDetailPageSendStarPoint(context),
        ),
        RatingBar.builder(
          initialRating: rating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space_4,
          ),
          itemBuilder: (context, _) => Icon(
            Icons.star,
            color: isDark ? AppColors.surface_dark : AppColors.surface_light,
          ),
          onRatingUpdate: (r) {
            setState(() {
              rating = r;
            });
          },
        ),
      ],
    );
  }

  Column sendCommentBox() {
    return Column(
      children: [
        Text(
          '${AppStrings.write_your_comments.translate(context)}:',
          style: AppTypography.articlesDetailPageWriteComment(context),
        ),
        TextField(
          controller: commentController,
          decoration: InputDecoration(
            hintText: '${AppStrings.comment.translate(context)}...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.space_8),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space_8),
        ElevatedButton(
          onPressed: _sendComment,
          child: Text(
            AppStrings.send_comment.translate(context),
            style: AppTypography.articlesDetailPageSendCommentButton(context),
          ),
        ),
      ],
    );
  }

  List<Widget> similarArticles(BuildContext context) {
    return [
      Text(
        '${AppStrings.similar_articles.translate(context)}:',
        style: AppTypography.articlesDetailPageSimilarArticlesTitle(context),
      ),
      const SizedBox(height: AppSpacing.space_8),
      ...relatedPosts.map((related) {
        final relTitle =
            related['title']['rendered'] ??
            AppStrings.without_title.translate(context);
        final relImage =
            related['_embedded']?['wp:featuredmedia']?[0]?['source_url'] ?? '';
        final relDate = related['date'] as String? ?? AppStrings.epmty_text;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.space_8),
          child: ListTile(
            leading: relImage.isNotEmpty
                ? Image.network(
                    relImage,
                    width: AppSpacing.space_100,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.image),
            title: Text(
              relTitle,
              style: AppTypography.articlesDetailPageSimilarArticlesItemTitle(
                context,
              ),
            ),
            subtitle: Text(
              formatJalaliDate(relDate),
              style:
                  AppTypography.articlesDetailPageSimilarArticlesItemSubtitle(
                    context,
                  ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArticleDetailPage(post: related),
              ),
            ),
          ),
        );
      }),
    ];
  }
}

class ArticlesPageTitleWidget extends StatelessWidget {
  const ArticlesPageTitleWidget({
    super.key,
    required this.title,
    required this.isDark,
  });

  final dynamic title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      // style: AppTypography.articlesDetailPageArticlesTitle(context),
      style: AppTypography.articlesTitle(context),
    );
  }
}

class ArticleCommentsListWidget extends StatelessWidget {
  const ArticleCommentsListWidget({
    super.key,
    required this.comAvatar,
    required this.comAuthor,
    required this.comContent,
    required this.comDate,
    required this.isDark,
  });

  final dynamic comAvatar;
  final dynamic comAuthor;
  final dynamic comContent;
  final String comDate;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: comAvatar.isNotEmpty ? NetworkImage(comAvatar) : null,
        child: comAvatar.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(
        comAuthor,
        style: AppTypography.articlesDetailPageArticleCommentsListTitle(
          context,
        ),
      ),
      subtitle: Text(
        comContent,
        style: AppTypography.articlesDetailPageArticleCommentsListSubtitle(
          context,
        ),
      ),
      trailing: Text(
        formatJalaliDate(comDate),
        style: AppTypography.articlesDetailPageArticleCommentsListDate(context),
      ),
    );
  }
}

class ArticlesContentWidget extends StatelessWidget {
  const ArticlesContentWidget({super.key, required this.content});

  final dynamic content;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {},
      child: Html(
        data: content,
        style: {'img': Style(height: Height.auto())},
      ),
    );
  }
}

class ArticlesReleasedDateWidget extends StatelessWidget {
  const ArticlesReleasedDateWidget({
    super.key,
    required this.isoDate,
    required this.isDark,
  });

  final String isoDate;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatJalaliDate(isoDate),
      style: AppTypography.articlesDetailPageArticleCommentsListReleaseDate(
        context,
      ),
    );
  }
}

class ArticlesAuthorWidget extends StatelessWidget {
  const ArticlesAuthorWidget({
    super.key,
    required this.author,
    required this.isDark,
  });

  final dynamic author;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${AppStrings.writer.translate(context)}: $author',
      style: AppTypography.articlesDetailPageArticlesAuthorsName(context),
    );
  }
}

class ArticlesImageWidget extends StatelessWidget {
  const ArticlesImageWidget({super.key, required this.imageUrl});

  final dynamic imageUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      height: AppSpacing.space_200,
      width: double.infinity,
    );
  }
}
