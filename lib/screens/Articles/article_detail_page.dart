// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:sornaz/helpers/app_functions.dart';

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

  // واکشی کامنت‌ها با pagination
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

  // لود بیشتر کامنت‌ها با اسکرول
  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_scrollController.position.outOfRange &&
        hasMoreComments) {
      commentPage++;
      _fetchComments(loadMore: true);
    }
  }

  // ارسال کامنت (فرض بدون auth - اگر نیاز به auth داشت، JWT اضافه کن)
  Future<void> _sendComment() async {
    final postId = widget.post['id'];
    final content = commentController.text;
    if (content.isEmpty) return;

    final url = 'https://sornaz.com/wp-json/wp/v2/comments';
    final body = json.encode({
      'post': postId,
      'content': content,
      'author_name': 'کاربر مهمان', // اگر auth داشت، نام واقعی
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 201) {
        commentController.clear();
        _fetchComments(); // رفرش کامنت‌ها
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('خطا در ارسال کامنت')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('خطا در ارسال کامنت')));
    }
  }

  // واکشی مقالات پیشنهادی (دو تا از دسته مشابه)
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
    final catId = categories[0]; // اولین دسته
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
    final title = widget.post['title']['rendered'] ?? 'بدون عنوان';
    final content = widget.post['content']['rendered'] ?? 'بدون محتوا';
    final imageUrl =
        widget.post['_embedded']?['wp:featuredmedia']?[0]?['source_url'] ?? '';
    final author = widget.post['_embedded']?['author']?[0]?['name'] ?? 'ناشناس';
    final isoDate = widget.post['date'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          controller: _scrollController, // اضافه برای اسکرول روان
          physics: const BouncingScrollPhysics(), // اسکرول نرم و bounce
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  height: 200,
                  width: double.infinity,
                ),
              const SizedBox(height: 16),
              Text(
                'نویسنده: $author',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                formatJalaliDate(isoDate),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onLongPress: () {
                  // long press: تولتیپ باز کن (برای لینک‌ها نیاز به detect هست، اما برای ساده، فرض همه لینک‌ها)
                  // برای دقیق، از onLinkLongPress در Html استفاده کن (در نسخه جدید flutter_html 3.0+ اضافه شده)
                },
                child: Html(
                  data: content,
                  style: {
                    'img': Style(
                      // maxWidth: MaxWidth(MediaQuery.of(context).size.width, 100.0),
                      height: Height.auto(),
                      // css: "object-fit: contain;", // کوچک کردن اگر بزرگتر بود
                    ),
                  },
                  onLinkTap: (url, _, __) {
                    // if (url != null) _navigateToArticle(url, context); // tap معمولی
                  },
                ),
              ),
              const SizedBox(height: 32),
              // مقالات پیشنهادی با کارت
              if (isLoadingRelated)
                const Center(child: CircularProgressIndicator())
              else if (relatedPosts.isNotEmpty) ...[
                const Text(
                  'مقالات پیشنهادی:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...relatedPosts.map((related) {
                  final relTitle = related['title']['rendered'] ?? 'بدون عنوان';
                  final relImage =
                      related['_embedded']?['wp:featuredmedia']?[0]?['source_url'] ??
                      '';
                  final relDate = related['date'] as String? ?? '';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: relImage.isNotEmpty
                          ? Image.network(
                              relImage,
                              width: 100,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image),
                      title: Text(relTitle),
                      subtitle: Text(formatJalaliDate(relDate)),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArticleDetailPage(post: related),
                        ),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 32),
              // نظرسنجی ۵ ستاره
              const Text(
                'امتیاز شما به مقاله:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              RatingBar.builder(
                initialRating: rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (r) {
                  setState(() {
                    rating = r;
                  });
                  // می‌تونی به API ارسال کنی (اختیاری)
                },
              ),
              const SizedBox(height: 16),
              // باکس کامنت‌گذاری
              const Text(
                'نظر خود را بنویسید:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'کامنت...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _sendComment,
                child: const Text('ارسال کامنت'),
              ),
              const SizedBox(height: 32),
              // لیست کامنت‌ها با پروفایل و زمان
              if (isLoadingComments)
                const Center(child: CircularProgressIndicator())
              else ...[
                const Text(
                  'کامنت‌ها:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (comments.isEmpty)
                  const Text('بدون کامنت')
                else
                  ...comments.map((comment) {
                    final comContent = comment['content']['rendered']
                        .replaceAll(RegExp(r'<[^>]*>'), '');
                    final comAuthor = comment['author_name'] ?? 'ناشناس';
                    final comAvatar =
                        comment['author_avatar_urls']?['96'] ??
                        ''; // عکس پروفایل 96px
                    final comDate = comment['date'] as String? ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: comAvatar.isNotEmpty
                            ? NetworkImage(comAvatar)
                            : null,
                        child: comAvatar.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(comAuthor),
                      subtitle: Text(comContent),
                      trailing: Text(
                        formatJalaliDate(comDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }),
              ],
              if (hasMoreComments && !isLoadingComments)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      commentPage++;
                      _fetchComments(loadMore: true);
                    },
                    child: const Text('لود بیشتر کامنت‌ها'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
