import 'package:flutter/material.dart';
import 'package:sornaz/screens/Articles/services/article_api_service.dart';

class ArticleRating extends StatefulWidget {
  const ArticleRating({
    super.key,
    required this.api,
    required this.type,
    required this.id,
    required this.locale,
    this.token,
    this.initial,
  });
  final ArticleApiService api;
  final String type, locale;
  final int id;
  final String? token;
  final Map<String, dynamic>? initial;
  @override
  State<ArticleRating> createState() => _ArticleRatingState();
}

class _ArticleRatingState extends State<ArticleRating> {
  Map<String, dynamic>? summary;
  bool busy = false;
  bool failed = false;
  int generation = 0;
  bool get en => widget.locale == 'en';
  @override
  void initState() {
    super.initState();
    summary = widget.initial;
    if (summary == null) load();
  }

  @override
  void didUpdateWidget(covariant ArticleRating old) {
    super.didUpdateWidget(old);
    if (old.token != widget.token ||
        old.locale != widget.locale ||
        old.id != widget.id) {
      summary = null;
      load();
    } else if (widget.initial != null) {
      summary = widget.initial;
    }
  }

  Future<void> load([int? score]) async {
    if (score != null && widget.token?.isNotEmpty != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            en ? 'Sign in to rate.' : 'برای امتیازدهی وارد حساب شوید.',
          ),
        ),
      );
      return;
    }
    final current = ++generation;
    if (mounted) {
      setState(() {
        busy = true;
        failed = false;
      });
    }
    try {
      final data = await widget.api.rating(
        widget.type,
        widget.id,
        locale: widget.locale,
        token: widget.token,
        score: score,
      );
      if (mounted && current == generation) setState(() => summary = data);
    } catch (_) {
      if (mounted && current == generation) setState(() => failed = true);
    } finally {
      if (mounted && current == generation) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mine = (summary?['userScore'] as num?)?.toInt() ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var score = 1; score <= 5; score++)
              IconButton(
                tooltip: '$score / 5',
                visualDensity: VisualDensity.compact,
                onPressed: busy ? null : () => load(score),
                icon: Icon(
                  score <= mine ? Icons.star : Icons.star_border,
                  color: Colors.amber.shade700,
                ),
              ),
            if (busy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        if (summary != null)
          Text(
            '${summary!['average']} / 5 · ${summary!['count']} ${en ? 'ratings' : 'رأی'}',
          ),
        if (failed)
          TextButton(
            onPressed: () => load(),
            child: Text(
              en
                  ? 'Could not load rating. Retry'
                  : 'دریافت امتیاز ناموفق بود؛ تلاش مجدد',
            ),
          ),
      ],
    );
  }
}
