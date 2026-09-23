import '../../provider/voice_recorder_provider.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import '../../services/recording_bookmarks.dart';

class RecordingBookmarksView extends StatefulWidget {
  const RecordingBookmarksView({
    super.key,
    required this.uri,
    required this.store,
    required this.revision,
    required this.onDelete,
    this.onSelect,
  });
  final String uri;
  final RecordingBookmarks store;
  final int revision;
  final Future<void> Function(int) onDelete;
  final Future<void> Function(int)? onSelect;
  @override
  State<RecordingBookmarksView> createState() => _RecordingBookmarksViewState();
}

class _RecordingBookmarksViewState extends State<RecordingBookmarksView> {
  late Future<List<int>> _items;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _items = widget.store.load(widget.uri);
  }

  @override
  void didUpdateWidget(covariant RecordingBookmarksView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri || oldWidget.revision != widget.revision)
      _reload();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              socialText(
                context,
                'عملیات نشانک انجام نشد.',
                'Could not update bookmark.',
              ),
            ),
          ),
        );
    }
  }

  String _time(int milliseconds) => recordingTime(milliseconds);

  @override
  Widget build(BuildContext context) => FutureBuilder<List<int>>(
    future: _items,
    builder: (context, snapshot) {
      if (snapshot.hasError)
        return Text(
          socialText(
            context,
            'نشانک‌ها بارگذاری نشدند.',
            'Could not load bookmarks.',
          ),
        );
      final items = snapshot.data ?? [];
      if (items.isEmpty) return const SizedBox.shrink();
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 112),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final time in items)
                InputChip(
                  avatar: const Icon(Icons.bookmark, size: 16),
                  label: Text(_time(time), textDirection: TextDirection.ltr),
                  tooltip: socialText(
                    context,
                    'رفتن به نشانک',
                    'Go to bookmark',
                  ),
                  onPressed: widget.onSelect == null
                      ? null
                      : () => _run(() => widget.onSelect!(time)),
                  onDeleted: () => _run(() => widget.onDelete(time)),
                  deleteButtonTooltipMessage: socialText(
                    context,
                    'حذف نشانک',
                    'Delete bookmark',
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
