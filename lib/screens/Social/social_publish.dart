import 'package:flutter/foundation.dart';
import 'story_composer.dart';
import 'media_picker.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/components/app_text.dart';
import 'package:flutter/material.dart';

import 'social_api.dart';
import 'social_widgets.dart';

class PublishPage extends StatefulWidget {
  const PublishPage({super.key, required this.api, required this.kind});
  final SocialApi api;
  final String kind;
  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  final body = TextEditingController();
  Json? media;
  bool busy = false;
  String? filename;
  @override
  void dispose() {
    body.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    final file = await pickGalleryMedia(context);
    if (file == null || !mounted) return;
    setState(() => busy = true);
    try {
      final data = await widget.api.upload(file);
      if (mounted)
        setState(() {
          media = data;
          filename = file.name;
        });
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      await releasePickedMedia(file);
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> publish() async {
    if (widget.kind == 'story' && media == null) {
      socialError(
        context,
        const SocialException('برای استوری تصویر یا ویدیو انتخاب کنید.'),
      );
      return;
    }
    if (body.text.trim().isEmpty && media == null) return;
    setState(() => busy = true);
    try {
      await widget.api.post('/posts', {
        'kind': widget.kind,
        'body': body.text.trim(),
        if (media != null) 'media_id': '${media!['id']}',
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) socialError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.kind == 'story' &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android
      ? StoryComposer(api: widget.api)
      : PopScope(
          canPop: !busy,
          child: SocialScaffold(
            title: widget.kind == 'story' ? 'استوری جدید' : 'پست جدید',
            body: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                AppText(
                  widget.kind == 'story'
                      ? 'لحظه‌های موسیقایی شما، برای ۲۴ ساعت'
                      : 'اجرای تازه، تمرین امروز یا تجربه‌ات را منتشر کن.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: busy ? null : pick,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: AppText(filename ?? 'انتخاب تصویر یا ویدیو'),
                ),
                const AppText(
                  'تصویر تا ۱۰ مگابایت · ویدیو تا ۱۰۰ مگابایت',
                  style: TextStyle(fontSize: 12),
                ),
                if (media != null) ...[
                  const SizedBox(height: 16),
                  if ('${media!['mime']}'.startsWith('image/'))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SocialImage(
                        api: widget.api,
                        path: media!['url'],
                        height: 260,
                        width: double.infinity,
                      ),
                    )
                  else
                    SocialVideo(
                      postControls: true,
                      key: ValueKey(media!['id']),
                      api: widget.api,
                      path: media!['url'],
                    ),
                ],
                const SizedBox(height: 20),
                TextField(
                  controller: body,
                  enabled: !busy,
                  maxLength: 10000,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'متن و توضیحات'.translate(context),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                if (busy) ...[
                  const LinearProgressIndicator(),
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: AppText('در حال ارسال؛ صفحه را باز نگه دارید.'),
                  ),
                ],
                FilledButton(
                  onPressed: busy ? null : publish,
                  child: const AppText('انتشار'),
                ),
              ],
            ),
          ),
        );
}
