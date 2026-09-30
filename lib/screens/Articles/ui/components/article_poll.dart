import 'package:sornaz/helpers/app_appearance.dart';
import 'package:flutter/material.dart';
import '../../services/article_api_service.dart';

class ArticlePoll extends StatefulWidget {
  const ArticlePoll({
    super.key,
    required this.articleId,
    required this.poll,
    required this.api,
    required this.locale,
    this.token,
  });

  final int articleId;
  final Map<String, dynamic> poll;
  final ArticleApiService api;
  final String locale;
  final String? token;

  @override
  State<ArticlePoll> createState() => _ArticlePollState();
}

class _ArticlePollState extends State<ArticlePoll> {
  late Map<String, dynamic> poll = Map<String, dynamic>.from(widget.poll);
  bool busy = false;

  List<Map<String, dynamic>> get options =>
      (poll['options'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  Future<void> vote(int option) async {
    if (busy || poll['voted'] == true) return;
    setState(() => busy = true);
    try {
      final value = await widget.api.votePoll(
        widget.articleId,
        option,
        locale: widget.locale,
        token: widget.token,
      );
      if (mounted) setState(() => poll = value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = options;
    if (rows.length < 2) return const SizedBox.shrink();
    final total = rows.fold<int>(
      0,
      (sum, row) => sum + (int.tryParse('${row['votes'] ?? 0}') ?? 0),
    );
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: appRadius(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${poll['question'] ?? ''}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++) ...[
            Builder(
              builder: (context) {
                final votes = int.tryParse('${rows[i]['votes'] ?? 0}') ?? 0;
                final percent = total == 0 ? 0.0 : votes / total;
                return InkWell(
                  onTap: busy
                      ? null
                      : () => vote(int.tryParse('${rows[i]['id']}') ?? i),
                  borderRadius: appRadius(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${rows[i]['title'] ?? rows[i]['text'] ?? ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '${(percent * 100).round()}٪',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: percent, minHeight: 4),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          Text('$total رأی', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
