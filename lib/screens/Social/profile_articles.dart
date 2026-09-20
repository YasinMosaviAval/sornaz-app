import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import '../Articles/services/article_api_service.dart';
import '../Articles/ui/components/article_item.dart';
import 'social_widgets.dart';

class ProfileArticles extends StatefulWidget {
  const ProfileArticles({super.key, required this.owner});
  final int owner;
  @override
  State<ProfileArticles> createState() => _ProfileArticlesState();
}

class _ProfileArticlesState extends State<ProfileArticles> {
  final api = ArticleApiService();
  final rows = <Map<String, dynamic>>[];
  String locale = '';
  bool loading = false, more = true;
  Object? error;
  int page = 1, generation = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Localizations.localeOf(context).languageCode;
    if (next != locale) {
      locale = next;
      generation++;
      loading = false;
      rows.clear();
      page = 1;
      more = true;
      load();
    }
  }

  @override
  void dispose() {
    api.client.close();
    super.dispose();
  }

  Future<void> load() async {
    if (loading) return;
    final request = generation;
    setState(() => loading = true);
    try {
      final data = await api.fetchPosts(
        locale: locale,
        page: page,
        author: widget.owner,
      );
      if (mounted && request == generation)
        setState(() {
          rows.addAll(data);
          page++;
          more = data.length == 50;
          error = null;
        });
    } catch (e) {
      if (mounted && request == generation) setState(() => error = e);
    } finally {
      if (mounted && request == generation) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final row in rows)
        ArticleItemWidget(post: row, isDark: context.watch<AppData>().isDark),
      if (loading) const LinearProgressIndicator(),
      if (error != null)
        TextButton(
          onPressed: load,
          child: Text(socialText(context, 'تلاش دوباره', 'Retry')),
        ),
      if (!loading && rows.isEmpty && error == null)
        SocialEmpty(
          socialText(
            context,
            'هنوز مقاله‌ای منتشر نشده است.',
            'No published articles yet.',
          ),
        ),
      if (more && !loading && rows.isNotEmpty)
        TextButton(
          onPressed: load,
          child: Text(socialText(context, 'مقاله‌های بیشتر', 'More articles')),
        ),
    ],
  );
}
