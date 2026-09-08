import 'package:sornaz/components/app_text.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'social_api.dart';
import 'social_widgets.dart';
import 'social_downloads.dart';

class BookmarkButton extends StatefulWidget {
  const BookmarkButton({
    super.key,
    required this.api,
    required this.kind,
    required this.id,
  });
  final SocialApi api;
  final String kind;
  final int id;
  @override
  State<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<BookmarkButton> {
  bool saved = false, busy = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (widget.api.token.isEmpty) return;
    try {
      final data = object(await widget.api.get('/bookmarks'));
      if (mounted)
        setState(
          () => saved = objects(
            data[widget.kind == 'course' ? 'courses' : 'authors'],
          ).any((r) => number(r['id']) == widget.id),
        );
    } catch (_) {
      /* The action still exposes errors and permits retry. */
    }
  }

  Future<void> toggle() async {
    setState(() => busy = true);
    try {
      final d = object(
        await widget.api.post('/bookmarks', {
          'kind': widget.kind,
          'id': '${widget.id}',
          'active': saved ? '0' : '1',
        }),
      );
      if (mounted) setState(() => saved = d['saved'] == true);
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: saved ? 'حذف از ذخیره‌شده‌ها' : 'ذخیره',
    onPressed: busy ? null : toggle,
    icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
  );
}

class DownloadCourseButton extends StatefulWidget {
  const DownloadCourseButton({
    super.key,
    required this.api,
    required this.courseId,
  });
  final SocialApi api;
  final int courseId;
  @override
  State<DownloadCourseButton> createState() => _DownloadCourseButtonState();
}

class _DownloadCourseButtonState extends State<DownloadCourseButton> {
  double? progress;
  http.Client? client;
  @override
  void dispose() {
    client?.close();
    super.dispose();
  }

  Future<void> download() async {
    setState(() => progress = 0);
    final c = http.Client();
    client = c;
    try {
      await LessonDownloads(widget.api).download(widget.courseId, (p) {
        if (mounted) setState(() => progress = p);
      }, c);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText(
              'دانلود کامل شد؛ فایل‌ها در بخش دانلودهای پروفایل هستند.',
            ),
          ),
        );
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      c.close();
      if (mounted) setState(() => progress = null);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      OutlinedButton.icon(
        onPressed: progress == null ? download : null,
        icon: const Icon(Icons.download_outlined),
        label: AppText(
          progress == null
              ? socialText(context, 'دانلود دوره', 'Download course')
              : '${(progress! * 100).round()}%',
        ),
      ),
      if (progress != null) LinearProgressIndicator(value: progress),
    ],
  );
}

class LessonProgressControl extends StatefulWidget {
  const LessonProgressControl({
    super.key,
    required this.api,
    required this.courseId,
    required this.postId,
  });
  final SocialApi api;
  final int courseId, postId;
  @override
  State<LessonProgressControl> createState() => _LessonProgressControlState();
}

class _LessonProgressControlState extends State<LessonProgressControl> {
  bool done = false, busy = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final d = object(await widget.api.get('/dashboard'));
      final rows = objects(
        d['courses'],
      ).where((c) => number(c['id']) == widget.courseId);
      if (mounted)
        setState(() {
          done =
              rows.isNotEmpty &&
              (rows.first['completed_ids'] as List)
                  .map(number)
                  .contains(widget.postId);
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> change() async {
    setState(() => busy = true);
    try {
      await widget.api.post(
        '/courses/${widget.courseId}/lessons/${widget.postId}/progress',
        {'completed': done ? '0' : '1'},
      );
      if (mounted) setState(() => done = !done);
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => error != null
      ? TextButton(
          onPressed: load,
          child: const AppText('تلاش دوباره برای دریافت پیشرفت'),
        )
      : FilledButton.icon(
          onPressed: busy ? null : change,
          icon: Icon(done ? Icons.check_circle : Icons.check_circle_outline),
          label: AppText(
            done
                ? socialText(context, 'تکمیل شد؛ لغو علامت', 'Completed · undo')
                : socialText(
                    context,
                    'این درس را تکمیل کردم',
                    'Mark lesson complete',
                  ),
          ),
        );
}
