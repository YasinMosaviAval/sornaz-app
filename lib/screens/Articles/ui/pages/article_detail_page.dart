import 'package:sornaz/components/app_top_bar_direction.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sornaz/components/drawer_theme.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Articles/provider/articles_provider.dart';
import 'package:sornaz/screens/Articles/services/article_api_service.dart';
import 'package:sornaz/screens/Articles/ui/components/article_content_widget.dart';
import 'package:sornaz/screens/Articles/ui/components/article_format.dart';
import 'package:sornaz/screens/Articles/ui/components/article_item.dart';
import 'package:sornaz/screens/Articles/ui/components/article_progress.dart';
import 'package:sornaz/screens/Articles/ui/components/article_rating.dart';

class ArticleDetailPage extends StatefulWidget {
  const ArticleDetailPage({super.key, required this.post});
  final Map<String, dynamic> post;
  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  final _scroll = ScrollController();
  final _progress = ValueNotifier<double>(0);
  final _content = TextEditingController(),
      _author = TextEditingController(),
      _email = TextEditingController();
  final _formKey = GlobalKey();
  Map<String, dynamic>? _post, _reply;
  List<Map<String, dynamic>> _comments = [];
  String _locale = 'fa', _identity = '';
  String? _token, _error, _commentError;
  bool _loading = true,
      _loadingComments = false,
      _sending = false,
      _more = true,
      _openingLink = false;
  int _page = 1, _generation = 0;
  int get id => (widget.post['id'] as num).toInt();
  bool get en => _locale == 'en';
  ArticlesProvider get library => context.read<ArticlesProvider>();
  String tr(String fa, String english) => en ? english : fa;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    _progress.value = max > 0 ? (_scroll.offset / max).clamp(0, 1) : 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'fa';
    final token = context.watch<AuthSession?>()?.token;
    final identity = '$locale:$token';
    if (identity != _identity) {
      _identity = identity;
      _locale = locale;
      _token = token;
      _generation++;
      _comments = [];
      _reply = null;
      _page = 1;
      _more = true;
      _loadingComments = false;
      _sending = false;
      _error = null;
      _commentError = null;
      _loading = true;
      _post = widget.post['locale'] == locale ? widget.post : null;
      _load(_generation);
    }
  }

  Future<void> _load(int generation) async {
    try {
      final post = await library.resolve(id);
      if (!mounted || generation != _generation) return;
      setState(() {
        _post = post;
        _loading = false;
      });
      await _loadComments(reset: true);
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _error = tr(
            'مقاله در این زبان در دسترس نیست؛ اتصال اینترنت را بررسی کنید.',
            'This article is unavailable in this language. Check your connection.',
          );
        });
      }
    }
  }

  Future<void> _loadComments({bool reset = false}) async {
    if (_loadingComments || !reset && !_more) return;
    final generation = _generation,
        language = _locale,
        token = _token,
        requestedPage = reset ? 1 : _page;
    setState(() => _loadingComments = true);
    try {
      final receipts = token == null
          ? await library.cache.receipts(id)
          : <String>[];
      final rows = await library.api.fetchComments(
        id,
        locale: language,
        page: requestedPage,
        token: token,
        receipts: receipts,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        if (reset) _comments = [];
        final ids = _comments.map((c) => c['id']).toSet();
        _comments.addAll(rows.where((c) => !ids.contains(c['id'])));
        _page = requestedPage + 1;
        _more = rows.length == 20;
        _commentError = null;
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
          () => _commentError = tr(
            'دریافت نظرات ممکن نشد.',
            'Could not load comments.',
          ),
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loadingComments = false);
      }
    }
  }

  String _commentHtml(String text) {
    final out = StringBuffer();
    var end = 0;
    for (final match in RegExp(r'https?://[^\s<>]+').allMatches(text)) {
      out.write(const HtmlEscape().convert(text.substring(end, match.start)));
      final link = const HtmlEscape().convert(match.group(0)!);
      out.write('<a href="$link">$link</a>');
      end = match.end;
    }
    out.write(const HtmlEscape().convert(text.substring(end)));
    return out.toString().replaceAll(String.fromCharCode(10), '<br>');
  }

  Future<void> _send() async {
    if (_sending || _content.text.trim().isEmpty) return;
    final generation = _generation,
        token = _token,
        language = _locale,
        text = _content.text.trim();
    final author = _author.text.trim(),
        email = _email.text.trim(),
        parent = (_reply?['id'] as num?)?.toInt() ?? 0;
    if (text.length > 3000) {
      _message(
        tr(
          'حداکثر طول نظر ۳۰۰۰ نویسه است.',
          'Comments may contain up to 3,000 characters.',
        ),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final result = await library.api.sendComment(
        id,
        locale: language,
        token: token,
        content: _commentHtml(text),
        author: author,
        email: email,
        parent: parent,
      );
      if (result['receipt'] is String) {
        await library.cache.saveReceipt(id, result['receipt']);
      }
      if (!mounted || generation != _generation) return;
      final user = context.read<AuthSession?>()?.user;
      setState(() {
        _comments.add({
          'id': result['id'],
          'parent': parent,
          'depth': parent > 0 ? 1 : 0,
          'status': 'pending',
          'author_name':
              user?.username ??
              (author.isNotEmpty ? author : tr('کاربر مهمان', 'Guest User')),
          'date': DateTime.now().toIso8601String(),
          'content': {'rendered': _commentHtml(text)},
        });
        _reply = null;
      });
      _content.clear();
      _message(
        tr(
          'نظر شما ثبت شد و در انتظار تأیید است.',
          'Your comment is awaiting approval.',
        ),
      );
      await _loadComments(reset: true);
    } catch (e) {
      if (mounted && generation == _generation) {
        _message(
          e is ArticleApiException
              ? e.message
              : tr(
                  'ارسال نظر ممکن نشد؛ دوباره تلاش کنید.',
                  'Could not submit comment. Try again.',
                ),
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _sending = false);
      }
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _link(String raw) async {
    if (_openingLink || raw.startsWith('#')) return;
    final uri = Uri.parse('https://sornaz.com/').resolve(raw);
    final internal =
        uri.host == 'sornaz.com' ||
        uri.host == 'www.sornaz.com' ||
        uri.host == Uri.parse(ArticleApiService.baseUrl).host;
    if (internal) {
      int? target = int.tryParse(
        uri.queryParameters['id'] ??
            uri.queryParameters['p'] ??
            uri.queryParameters['post_id'] ??
            '',
      );
      final parts = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      Map<String, dynamic>? match;
      for (final p in library.allPosts) {
        if ((target != null && p['id'] == target) ||
            (parts.isNotEmpty && p['slug'] == parts.last)) {
          match = p;
          break;
        }
      }
      final articlePath =
          uri.path.contains('article') || target != null || match != null;
      if (articlePath) {
        _openingLink = true;
        try {
          if (match == null && target != null) {
            match = await library.resolve(target);
          }
          if (match == null) {
            await library.synchronize();
            for (final p in library.allPosts) {
              if (parts.isNotEmpty && p['slug'] == parts.last) {
                match = p;
                break;
              }
            }
          }
          if (!mounted) return;
          if (match == null) {
            _message(
              tr(
                'این مقاله در زبان انتخاب‌شده در دسترس نیست.',
                'This article is unavailable in the selected language.',
              ),
            );
            return;
          }
          final next = match;
          final title = articlePlain('${next['title']?['rendered'] ?? ''}');
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text(tr('مطالعه مقاله $title', 'Read article $title')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: Text(tr('انصراف', 'Cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: Text(tr('مطالعه مقاله', 'Read article')),
                ),
              ],
            ),
          );
          if (confirmed == true && mounted) {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ArticleDetailPage(post: next)),
            );
          }
        } catch (_) {
          if (mounted) {
            _message(tr('باز کردن مقاله ممکن نشد.', 'Could not open article.'));
          }
        } finally {
          _openingLink = false;
        }
        return;
      }
    }
    if (!['https', 'http', 'mailto'].contains(uri.scheme)) return;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted) {
        _message(tr('باز کردن لینک ممکن نشد.', 'Could not open link.'));
      }
    } catch (_) {
      if (mounted) {
        _message(tr('باز کردن لینک ممکن نشد.', 'Could not open link.'));
      }
    }
  }

  Future<void> _insertLink() async {
    final url = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('افزودن لینک', 'Insert link')),
        content: TextField(
          controller: url,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(tr('انصراف', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, url.text.trim()),
            child: Text(tr('افزودن', 'Insert')),
          ),
        ],
      ),
    );
    // Controller disposal follows the dialog transition.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    url.dispose();
    if (value == null || !mounted) return;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      _message(tr('لینک معتبر وارد کنید.', 'Enter a valid link.'));
      return;
    }
    final selection = _content.selection;
    final at = selection.isValid ? selection.end : _content.text.length;
    _content.text = _content.text.replaceRange(at, at, ' $value ');
    _content.selection = TextSelection.collapsed(offset: at + value.length + 2);
  }

  Widget _meta(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16),
      const SizedBox(width: 6),
      Flexible(child: Text(label)),
    ],
  );
  Widget _comment(Map<String, dynamic> comment, bool dark) {
    final pending = comment['status'] == 'pending';
    final depth = ((comment['depth'] as num?)?.toInt() ?? 0).clamp(0, 3);
    return Container(
      key: ValueKey('comment-${comment['id']}'),
      margin: EdgeInsetsDirectional.only(start: depth * 12.0, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pending
            ? (dark ? const Color(0xff403617) : const Color(0xfffff8df))
            : (dark ? const Color(0xff202020) : Colors.white),
        border: Border.all(
          color: pending
              ? Colors.amber.shade300
              : (dark ? Colors.white12 : const Color(0xffeeeeee)),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                '${comment['author_name']}',
                style: AppTypography.headline5(context),
              ),
              Text(articleDate(context, '${comment['date'] ?? ''}')),
              if (pending)
                Text(
                  tr('تأیید نشده', 'Unapproved'),
                  style: TextStyle(
                    color: dark ? Colors.amber.shade200 : Colors.brown,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ArticlesContentWidget(
            content: '${comment['content']?['rendered'] ?? ''}',
            onLinkTap: _link,
          ),
          if (!pending) ...[
            ArticleRating(
              key: ValueKey('comment-rating-${comment['id']}'),
              api: library.api,
              type: 'comment',
              id: (comment['id'] as num).toInt(),
              locale: _locale,
              token: _token,
              initial: comment['rating'] is Map
                  ? Map<String, dynamic>.from(comment['rating'])
                  : null,
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _reply = comment);
                  final c = _formKey.currentContext;
                  if (c != null) {
                    Scrollable.ensureVisible(
                      c,
                      duration: const Duration(milliseconds: 250),
                    );
                  }
                },
                icon: const Icon(Icons.reply, size: 18),
                label: Text(tr('پاسخ', 'Reply')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppData>().isDark;
    final data = context.watch<ArticlesProvider>();
    final post = data.locale == _locale ? data.article(id) ?? _post : _post;
    final title = articlePlain('${post?['title']?['rendered'] ?? ''}');
    final cats = post?['categories'] as List? ?? [];
    final related = data.allPosts
        .where(
          (p) =>
              p['id'] != id &&
              (p['categories'] as List? ?? []).any(cats.contains),
        )
        .take(2)
        .toList();
    final author = post?['_embedded']?['author'];
    final name = author is List && author.isNotEmpty
        ? '${author.first['name'] ?? ''}'
        : '';
    return DrawerThemeScope(
      child: Directionality(
        textDirection: en ? TextDirection.ltr : TextDirection.rtl,
        child: Scaffold(
          appBar: AppTopBarDirection(
            child: AppBar(
              title: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.articleDetailsPageAppBar(context),
              ),
              flexibleSpace: ArticleProgressBackground(
                progress: _progress,
                isDark: dark,
              ),
            ),
          ),
          body: _loading && post == null
              ? const Center(child: CircularProgressIndicator())
              : post == null
              ? Center(
                  child: TextButton(
                    onPressed: () => _load(_generation),
                    child: Text(_error ?? tr('تلاش مجدد', 'Retry')),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await library.synchronize();
                    await _loadComments(reset: true);
                  },
                  child: CustomScrollView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList.list(
                          children: [
                            Text(
                              title,
                              style: AppTypography.headline1(context),
                            ),
                            const SizedBox(height: 16),
                            if (articleImage(post).isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: articleImage(post),
                                  fit: BoxFit.contain,
                                  errorWidget: (_, _, _) =>
                                      const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 18,
                              runSpacing: 10,
                              children: [
                                if (name.isNotEmpty)
                                  _meta(Icons.person_outline, name),
                                _meta(
                                  Icons.calendar_today_outlined,
                                  tr('تاریخ انتشار: ', 'Published: ') +
                                      articleDate(
                                        context,
                                        '${post['date'] ?? ''}',
                                      ),
                                ),
                                if ('${post['modified'] ?? ''}'.isNotEmpty)
                                  _meta(
                                    Icons.update,
                                    tr('به‌روزرسانی: ', 'Updated: ') +
                                        articleDate(
                                          context,
                                          '${post['modified']}',
                                        ),
                                  ),
                                _meta(
                                  Icons.visibility_outlined,
                                  '${post['views'] ?? 0} ${tr('بازدید', 'views')}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final category
                                    in post['category_names'] as List? ?? [])
                                  Chip(label: Text('$category')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            RepaintBoundary(
                              child: ArticlesContentWidget(
                                content:
                                    '${post['content']?['rendered'] ?? ''}',
                                onLinkTap: _link,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: dark
                                    ? const Color(0xff302a17)
                                    : const Color(0xfffffbeb),
                                border: Border.all(
                                  color: Colors.amber.shade100,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr(
                                      'امتیاز به این مقاله',
                                      'Rate this article',
                                    ),
                                    style: AppTypography.headline4(context),
                                  ),
                                  ArticleRating(
                                    key: ValueKey('post-rating-$id'),
                                    api: library.api,
                                    type: 'post',
                                    id: id,
                                    locale: _locale,
                                    token: _token,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              tr('نظرات کاربران', 'User comments'),
                              style: AppTypography.headline3(context),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList.builder(
                          itemCount: _comments.length,
                          itemBuilder: (_, i) => _comment(_comments[i], dark),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList.list(
                          children: [
                            if (_loadingComments)
                              const Center(child: CircularProgressIndicator()),
                            if (_commentError != null)
                              TextButton(
                                onPressed: () => _loadComments(reset: true),
                                child: Text(
                                  '${_commentError!} ${tr('تلاش مجدد', 'Retry')}',
                                ),
                              ),
                            if (!_loadingComments &&
                                _comments.isEmpty &&
                                _commentError == null)
                              Text(
                                tr(
                                  'هنوز نظری برای این مقاله ثبت نشده است.',
                                  'No comments have been posted for this article yet.',
                                ),
                              ),
                            if (_more && !_loadingComments)
                              TextButton(
                                onPressed: () => _loadComments(),
                                child: Text(
                                  tr('نمایش نظرات بیشتر', 'Load more comments'),
                                ),
                              ),
                            const SizedBox(height: 24),
                            Container(
                              key: _formKey,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: dark
                                    ? const Color(0xff202020)
                                    : const Color(0xfff9fafb),
                                border: Border.all(
                                  color: dark
                                      ? Colors.white12
                                      : const Color(0xffeeeeee),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _reply == null
                                        ? tr(
                                            'ارسال نظر جدید',
                                            'Submit a new comment',
                                          )
                                        : '${tr('پاسخ به ', 'Reply to ')}${_reply!['author_name']}',
                                    style: AppTypography.headline4(context),
                                  ),
                                  if (_reply != null)
                                    TextButton(
                                      onPressed: () =>
                                          setState(() => _reply = null),
                                      child: Text(
                                        tr('لغو پاسخ', 'Cancel reply'),
                                      ),
                                    ),
                                  if (_token == null) ...[
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _author,
                                      decoration: InputDecoration(
                                        labelText: tr(
                                          'نام و نام خانوادگی',
                                          'Full name',
                                        ),
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _email,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        labelText: tr('ایمیل', 'Email'),
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: TextButton.icon(
                                      onPressed: _insertLink,
                                      icon: const Icon(Icons.link),
                                      label: Text(
                                        tr('افزودن لینک', 'Insert link'),
                                      ),
                                    ),
                                  ),
                                  TextField(
                                    key: const Key('article-comment-input'),
                                    controller: _content,
                                    minLines: 5,
                                    maxLines: 12,
                                    maxLength: 3000,
                                    decoration: InputDecoration(
                                      labelText: tr('نظر شما', 'Your comment'),
                                      alignLabelWithHint: true,
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: FilledButton(
                                      onPressed: _sending ? null : _send,
                                      child: Text(
                                        _sending
                                            ? tr('در حال ارسال…', 'Submitting…')
                                            : tr('ارسال نظر', 'Submit comment'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (related.isNotEmpty) ...[
                              const SizedBox(height: 32),
                              Text(
                                tr('مقاله‌های مرتبط', 'Related articles'),
                                style: AppTypography.headline3(context),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SliverList.builder(
                        itemCount: related.length,
                        itemBuilder: (_, i) =>
                            ArticleItemWidget(post: related[i], isDark: dark),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _generation++;
    _scroll.dispose();
    _progress.dispose();
    _content.dispose();
    _author.dispose();
    _email.dispose();
    super.dispose();
  }
}
