import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'social_api.dart';
import 'social_widgets.dart';

class CourseMetadataEditor extends StatefulWidget {
  const CourseMetadataEditor({super.key, required this.api, required this.id});
  final SocialApi api;
  final int id;
  @override
  State<CourseMetadataEditor> createState() => _CourseMetadataEditorState();
}

class _CourseMetadataEditorState extends State<CourseMetadataEditor> {
  final fields = <String, TextEditingController>{};
  Json metadata = {};
  bool loading = true, busy = false;
  String? error;
  static const labels = <String, (String, String)>{
    'title_en': ('عنوان انگلیسی', 'English title'),
    'description_en': ('توضیحات انگلیسی', 'English description'),
    'category': ('دسته‌بندی فارسی', 'Persian category'),
    'category_en': ('دسته‌بندی انگلیسی', 'English category'),
    'duration_seconds': (
      'مدت کل ویدیوها (ثانیه)',
      'Total video duration (seconds)',
    ),
    'original_price': ('قیمت قبل از تخفیف (تومان)', 'Original price (IRT)'),
    'language': ('زبان آموزش', 'Teaching language'),
    'level': ('سطح دوره', 'Course level'),
    'summary': ('خلاصه و پیش‌نیازها', 'Summary and prerequisites'),
    'summary_en': ('خلاصه انگلیسی', 'English summary'),
    'preview_id': ('شناسه ویدیوی معرفی عمومی', 'Public preview video ID'),
  };
  @override
  void initState() {
    super.initState();
    for (final k in labels.keys) fields[k] = TextEditingController();
    load();
  }

  @override
  void dispose() {
    for (final c in fields.values) c.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final c = object(await widget.api.get('/courses/${widget.id}'));
      metadata = (c['details'] as Map?)?.cast<String, dynamic>() ?? {};
      metadata['resources'] = c['resources'] ?? [];
      for (final k in labels.keys) fields[k]!.text = '${metadata[k] ?? ''}';
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted)
        setState(() {
          error = '$e';
          loading = false;
        });
    }
  }

  Future<void> resource() async {
    final name = TextEditingController(), url = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(socialText(c, 'افزودن منبع', 'Add resource')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(
                labelText: socialText(c, 'عنوان', 'Title'),
              ),
            ),
            TextField(
              controller: url,
              decoration: const InputDecoration(labelText: 'HTTPS URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(socialText(c, 'انصراف', 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isNotEmpty &&
                  Uri.tryParse(url.text)?.scheme == 'https')
                Navigator.pop(c, true);
            },
            child: Text(socialText(c, 'افزودن', 'Add')),
          ),
        ],
      ),
    );
    if (saved == true && mounted)
      setState(
        () => metadata['resources'] = [
          ...?metadata['resources'] as List?,
          {
            'title': name.text.trim(),
            'url': url.text.trim(),
            'type': 'Article',
          },
        ],
      );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    url.dispose();
  }

  Future<void> uploadResource() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
    );
    if (result == null) return;
    try {
      final media = await widget.api.upload(
        result.files.single,
        courseId: widget.id,
      );
      if (mounted)
        setState(
          () => metadata['resources'] = [
            ...?metadata['resources'] as List?,
            {
              'title': result.files.single.name,
              'media_id': media['id'],
              'mime': media['mime'],
              'type': 'File',
            },
          ],
        );
    } catch (e) {
      if (mounted) socialError(context, e);
    }
  }

  Future<void> uploadPreview() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result == null) return;
    try {
      final media = await widget.api.upload(
        result.files.single,
        courseId: widget.id,
      );
      if (mounted)
        setState(() => fields['preview_id']!.text = '${media['id']}');
    } catch (e) {
      if (mounted) socialError(context, e);
    }
  }

  Future<void> save() async {
    setState(() => busy = true);
    try {
      await widget.api.post('/courses/${widget.id}/metadata', {
        'payload': jsonEncode({
          ...metadata,
          for (final e in fields.entries) e.key: e.value.text.trim(),
        }),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: socialText(context, 'جزئیات تکمیلی دوره', 'Course details'),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? SocialEmpty(error!, onRetry: load)
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              OutlinedButton.icon(
                onPressed: uploadPreview,
                icon: const Icon(Icons.video_library_outlined),
                label: Text(
                  socialText(
                    context,
                    'آپلود ویدیوی معرفی',
                    'Upload preview video',
                  ),
                ),
              ),
              for (final e in labels.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: fields[e.key],
                    maxLines:
                        e.key.contains('description') ||
                            e.key.contains('summary')
                        ? 4
                        : 1,
                    decoration: InputDecoration(
                      labelText: socialText(context, e.value.$1, e.value.$2),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              Text(
                socialText(
                  context,
                  'ویدیوی معرفی باید جدا از فایل‌های خصوصی درس‌ها آپلود شود.',
                  'Upload the preview separately from private lesson files.',
                ),
              ),
              for (final r in (metadata['resources'] as List? ?? []))
                ListTile(
                  title: Text('${r['title']}'),
                  subtitle: Text('${r['url']}'),
                  trailing: IconButton(
                    onPressed: () => setState(
                      () => (metadata['resources'] as List).remove(r),
                    ),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: resource,
                icon: const Icon(Icons.add_link),
                label: Text(socialText(context, 'افزودن منبع', 'Add resource')),
              ),
              OutlinedButton.icon(
                onPressed: uploadResource,
                icon: const Icon(Icons.upload_file),
                label: Text(
                  socialText(
                    context,
                    'آپلود فایل آموزشی',
                    'Upload learning file',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy ? null : save,
                child: Text(
                  socialText(context, 'ذخیره تغییرات', 'Save changes'),
                ),
              ),
            ],
          ),
  );
}
