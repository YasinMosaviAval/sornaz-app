import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'learning_widgets.dart';

/// Private app storage, separated by account. Opening a saved lesson rechecks
/// purchase and the current password grant; no cached access decision is trusted.
class LessonDownloads {
  LessonDownloads(this.api);
  final SocialApi api;
  Future<Directory> directory() async {
    final me = object(await api.get('/me'));
    final root = await getApplicationSupportDirectory();
    return Directory(
      '${root.path}/lessons/${number(me['id'])}',
    ).create(recursive: true);
  }

  Future<List<Json>> list() async {
    final dir = await directory();
    final result = <Json>[];
    await for (final file in dir.list()) {
      if (file is File && file.path.endsWith('.json')) {
        try {
          result.add(object(jsonDecode(await file.readAsString())));
        } on FormatException {
          continue;
        }
      }
    }
    return result;
  }

  Future<void> download(
    int courseId,
    ValueChanged<double> onProgress,
    http.Client client,
  ) async {
    final course = object(await api.get('/courses/$courseId'));
    if (course['access'] != true)
      throw const SocialException('ابتدا دوره را تهیه کنید.');
    final lessons = objects(
      course['curriculum'],
    ).expand((c) => objects(c['lessons'])).toList();
    if (lessons.any((l) => l['locked'] == true))
      throw const SocialException(
        'ابتدا رمز درس‌های قفل‌شده را در صفحه دوره وارد کنید.',
      );
    final ids = lessons.expand((l) => (l['media'] as List).map(number)).toSet();
    final files = objects(
      course['files'],
    ).where((f) => ids.contains(number(f['id']))).toList();
    final bytes = files.fold<int>(0, (sum, f) => sum + number(f['bytes']));
    if (bytes > 1024 * 1024 * 1024)
      throw const SocialException(
        'حجم این دوره برای دانلود یکجا بیشتر از یک گیگابایت است.',
      );
    final dir = await directory();
    int received = 0;
    for (final f in files) {
      final id = number(f['id']);
      final target = File('${dir.path}/$courseId-$id.media');
      if (await target.exists() &&
          await target.length() == number(f['bytes'])) {
        received += number(f['bytes']);
        onProgress(bytes == 0 ? 1 : received / bytes);
        continue;
      }
      final part = File('${target.path}.part');
      try {
        final request = http.Request('GET', Uri.parse(api.courseMedia(id)))
          ..followRedirects = false
          ..headers.addAll(api.headers);
        final response = await client
            .send(request)
            .timeout(const Duration(seconds: 40));
        if (response.statusCode != 200)
          throw const SocialException('دسترسی به فایل تأیید نشد.');
        final sink = part.openWrite();
        int fileBytes = 0;
        try {
          await for (final chunk in response.stream.timeout(
            const Duration(seconds: 45),
          )) {
            fileBytes += chunk.length;
            if (fileBytes > number(f['bytes']))
              throw const SocialException('اندازه فایل معتبر نیست.');
            sink.add(chunk);
            received += chunk.length;
            onProgress(bytes == 0 ? 1 : received / bytes);
          }
        } finally {
          await sink.close();
        }
        if (fileBytes != number(f['bytes']))
          throw const SocialException('دانلود کامل نشد؛ دوباره تلاش کنید.');
        if (await target.exists()) await target.delete();
        await part.rename(target.path);
      } catch (_) {
        if (await part.exists()) await part.delete();
        rethrow;
      }
    }
    final record = {
      'id': courseId,
      'title': course['title'],
      'cover_id': course['cover_id'],
      'price': course['price'],
      'bytes': bytes,
      'media_ids': ids.toList(),
      'downloaded_at': DateTime.now().toIso8601String(),
    };
    await File(
      '${dir.path}/$courseId.json',
    ).writeAsString(jsonEncode(record), flush: true);
    onProgress(1);
  }

  Future<void> remove(Json record) async {
    final dir = await directory();
    final id = number(record['id']);
    await for (final item in dir.list()) {
      final name = item.uri.pathSegments.last;
      if (item is File &&
          (name == '$id.json' ||
              RegExp('^$id-[0-9]+\\.media(\\.part)?\$').hasMatch(name)))
        await item.delete();
    }
  }
}

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key, required this.api});
  final SocialApi api;
  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  List<Json>? rows;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final r = await LessonDownloads(widget.api).list();
      if (mounted)
        setState(() {
          rows = r;
          error = null;
        });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> open(Json row) async {
    try {
      final course = object(await widget.api.get('/courses/${row['id']}'));
      if (course['access'] != true)
        throw const SocialException('دسترسی به دوره تأیید نشد.');
      final dir = await LessonDownloads(widget.api).directory();
      if (!mounted) return;
      await socialPush(
        context,
        SocialScaffold(
          title: '${course['title']}',
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              for (final chapter in objects(course['curriculum'])) ...[
                LearningHeading('${chapter['title']}'),
                for (final lesson in objects(chapter['lessons']))
                  ListTile(
                    leading: Icon(
                      lesson['locked'] == true
                          ? Icons.lock_outline
                          : Icons.play_circle_outline,
                    ),
                    title: Text('${lesson['title']}'),
                    onTap: lesson['locked'] == true
                        ? null
                        : () => socialPush(
                            context,
                            SocialScaffold(
                              title: '${lesson['title']}',
                              body: ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                  Text('${lesson['text'] ?? ''}'),
                                  const SizedBox(height: 16),
                                  for (final mid in lesson['media'] as List)
                                    Builder(
                                      builder: (context) {
                                        final file = File(
                                          '${dir.path}/${number(row['id'])}-${number(mid)}.media',
                                        );
                                        final f = objects(course['files'])
                                            .where(
                                              (f) =>
                                                  number(f['id']) ==
                                                  number(mid),
                                            );
                                        if (!file.existsSync() || f.isEmpty)
                                          return const SocialEmpty(
                                            'این فایل دانلود نشده؛ دوره را دوباره دانلود کنید.',
                                          );
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          child:
                                              '${f.first['mime']}'.startsWith(
                                                'video/',
                                              )
                                              ? SocialVideo(
                                                  api: widget.api,
                                                  path: '',
                                                  localFile: file,
                                                )
                                              : Image.file(
                                                  file,
                                                  errorBuilder: (_, __, ___) =>
                                                      const SocialEmpty(
                                                        'فایل قابل نمایش نیست.',
                                                      ),
                                                ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                  ),
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) socialError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    title: socialText(context, 'دانلودها', 'Downloads'),
    body: error != null
        ? SocialEmpty(error!, onRetry: load)
        : rows == null
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text(
                  socialText(
                    context,
                    'برای دانلود، وارد صفحه دوره خریداری‌شده شوید. هنگام باز کردن فایل، اتصال اینترنت برای تأیید دسترسی لازم است.',
                    'Download from a purchased course. Internet is needed to verify access when opening saved files.',
                  ),
                ),
                if (rows!.isEmpty)
                  const SocialEmpty('هنوز دوره‌ای دانلود نشده است.'),
                for (final row in rows!) ...[
                  LearningCourseTile(
                    api: widget.api,
                    course: row,
                    onTap: () => open(row),
                    trailing: IconButton(
                      tooltip: 'حذف دانلود',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final yes = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('حذف فایل‌های دانلودشده؟'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('انصراف'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('حذف'),
                              ),
                            ],
                          ),
                        );
                        if (yes != true) return;
                        try {
                          await LessonDownloads(widget.api).remove(row);
                          await load();
                        } catch (e) {
                          if (mounted) socialError(context, e);
                        }
                      },
                    ),
                  ),
                  Text(
                    '${(number(row['bytes']) / 1024 / 1024).toStringAsFixed(1)} MB',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Divider(),
                ],
              ],
            ),
          ),
  );
}
