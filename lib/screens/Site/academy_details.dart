import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'site_api.dart';

class AcademyDetailsPage extends StatefulWidget {
  const AcademyDetailsPage({
    super.key,
    required this.id,
    required this.name,
    this.api,
  });
  final String id, name;
  final SiteApi? api;
  @override
  State<AcademyDetailsPage> createState() => _AcademyDetailsPageState();
}

class _AcademyDetailsPageState extends State<AcademyDetailsPage> {
  late final api = widget.api ?? SiteApi();
  Json? academy;
  bool failed = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    if (widget.api == null) api.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => failed = false);
    try {
      final data = await api.get('/academies/${widget.id}');
      if (mounted) setState(() => academy = data);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  Widget photo(String path, {double height = 180}) => Image.network(
    SiteApi.origin.resolve(path).toString(),
    height: height,
    width: double.infinity,
    fit: BoxFit.cover,
    errorBuilder: (_, error, stack) =>
        SizedBox(height: height, child: const Icon(Icons.school_outlined)),
  );
  @override
  Widget build(BuildContext context) {
    final a = academy;
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: failed
          ? SocialEmpty(
              socialText(
                context,
                'اطلاعات آموزشگاه دریافت نشد.',
                'Could not load academy details.',
              ),
              onRetry: load,
            )
          : a == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (a['cover'] != null) photo('${a['cover']}'),
                  const SizedBox(height: 12),
                  Text(
                    '${a['name']}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text('${a['city'] ?? ''}'),
                  if (a['summary'] != null) Text('${a['summary']}'),
                  if (a['bio'] != null) Html(data: '${a['bio']}'),
                  if (a['intro_video'] != null)
                    AcademyVideo(
                      url: SiteApi.origin
                          .resolve('${a['intro_video']}')
                          .toString(),
                    ),
                  for (final row in objects(a['addresses'] ?? []))
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text('${row['address'] ?? ''}'),
                    ),
                  for (final row in objects(a['contacts'] ?? []))
                    ListTile(
                      leading: const Icon(Icons.contact_phone_outlined),
                      title: Text('${row['value'] ?? ''}'),
                      onTap: () async {
                        final value = '${row['value'] ?? ''}';
                        final uri = value.contains('@')
                            ? Uri(scheme: 'mailto', path: value)
                            : RegExp(r'^[+\d\s()-]+$').hasMatch(value)
                            ? Uri(scheme: 'tel', path: value)
                            : Uri.tryParse(value);
                        if (uri != null &&
                            ['https', 'tel', 'mailto'].contains(uri.scheme)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                  if ((a['teachers'] as List? ?? []).isNotEmpty)
                    Text(
                      socialText(context, 'مدرسان', 'Teachers'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  for (final teacher in objects(a['teachers'] ?? []))
                    Card(
                      child: ListTile(
                        title: Text('${teacher['name']}'),
                        leading: teacher['avatar'] == null
                            ? const Icon(Icons.person_outline)
                            : SizedBox(
                                width: 48,
                                child: photo(
                                  '${teacher['avatar']}',
                                  height: 48,
                                ),
                              ),
                      ),
                    ),
                  if ((a['courses'] as List? ?? []).isNotEmpty)
                    Text(
                      socialText(context, 'دوره‌ها', 'Courses'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  for (final course in objects(a['courses'] ?? []))
                    Card(child: ListTile(title: Text('${course['title']}'))),
                  for (final path in a['gallery'] as List? ?? [])
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: photo('$path'),
                    ),
                ],
              ),
            ),
    );
  }
}

class AcademyVideo extends StatefulWidget {
  const AcademyVideo({super.key, required this.url});
  final String url;
  @override
  State<AcademyVideo> createState() => _AcademyVideoState();
}

class _AcademyVideoState extends State<AcademyVideo> {
  late final controller = VideoPlayerController.networkUrl(
    Uri.parse(widget.url),
  );
  bool ready = false, failed = false;
  @override
  void initState() {
    super.initState();
    controller
        .initialize()
        .then((_) {
          if (mounted) setState(() => ready = true);
        })
        .catchError((Object _) {
          if (mounted) setState(() => failed = true);
        });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => failed
      ? Text(socialText(context, 'ویدیو در دسترس نیست.', 'Video unavailable.'))
      : !ready
      ? const LinearProgressIndicator()
      : Column(
          children: [
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
            IconButton(
              onPressed: () async {
                controller.value.isPlaying
                    ? await controller.pause()
                    : await controller.play();
                if (mounted) setState(() {});
              },
              icon: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
          ],
        );
}
