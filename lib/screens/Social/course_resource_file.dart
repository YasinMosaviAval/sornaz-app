import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'social_api.dart';
import 'social_widgets.dart';

class CourseResourceFile extends StatefulWidget {
  const CourseResourceFile({
    super.key,
    required this.api,
    required this.courseId,
    required this.resource,
  });
  final SocialApi api;
  final int courseId;
  final Json resource;
  @override
  State<CourseResourceFile> createState() => _CourseResourceFileState();
}

class _CourseResourceFileState extends State<CourseResourceFile> {
  File? file;
  bool busy = false;
  http.Client? client;
  @override
  void initState() {
    super.initState();
    find();
  }

  @override
  void dispose() {
    client?.close();
    super.dispose();
  }

  Future<File> location() async {
    final me = object(await widget.api.get('/me'));
    final root = await getTemporaryDirectory();
    final dir = Directory('${root.path}/course-resources/${number(me['id'])}');
    await dir.create(recursive: true);
    return File(
      '${dir.path}/${widget.courseId}-${number(widget.resource['media_id'])}.bin',
    );
  }

  Future<void> find() async {
    try {
      final target = await location();
      if (await target.exists() && mounted) setState(() => file = target);
    } catch (_) {}
  }

  Future<void> download() async {
    setState(() => busy = true);
    final c = http.Client();
    client = c;
    File? target;
    try {
      target = await location();
      final request = http.Request(
        'GET',
        Uri.parse(widget.api.courseMedia(widget.resource['media_id'])),
      )..headers.addAll(widget.api.headers);
      final response = await c
          .send(request)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200 ||
          (response.contentLength ?? 0) > 100 * 1024 * 1024)
        throw const SocialException('File access denied or file too large.');
      final sink = target.openWrite();
      int bytes = 0;
      try {
        await for (final part in response.stream.timeout(
          const Duration(seconds: 30),
        )) {
          bytes += part.length;
          if (bytes > 100 * 1024 * 1024)
            throw const SocialException('File too large.');
          sink.add(part);
        }
      } finally {
        await sink.close();
      }
      if (response.contentLength != null && bytes != response.contentLength)
        throw const SocialException('Incomplete download.');
      if (mounted) setState(() => file = target);
    } catch (e) {
      if (target != null && await target.exists()) await target.delete();
      if (mounted) socialError(context, e);
    } finally {
      c.close();
      client = null;
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> open() async {
    if (file == null) return;
    try {
      final detail = object(
        await widget.api.get('/courses/${widget.courseId}'),
      );
      if (detail['access'] != true ||
          !objects(detail['resources'] ?? []).any(
            (r) => number(r['media_id']) == number(widget.resource['media_id']),
          ))
        throw const SocialException('Resource access is no longer available.');
      await const MethodChannel(
        'sornaz/app_share',
      ).invokeMethod<void>('openCourseResource', {
        'path': file!.path,
        'mime': '${widget.resource['mime'] ?? 'application/pdf'}',
      });
    } catch (e) {
      if (mounted) socialError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.file_present_outlined),
            title: Text('${widget.resource['title']}'),
            subtitle: Text('${widget.resource['mime'] ?? ''}'),
            trailing: IconButton(
              onPressed: file == null ? null : open,
              icon: const Icon(Icons.open_in_new),
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: busy ? null : download,
                child: Text(
                  socialText(
                    context,
                    busy ? 'در حال دریافت…' : 'دانلود',
                    'Download',
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: file == null || busy
                    ? null
                    : () async {
                        await file!.delete();
                        if (mounted) setState(() => file = null);
                      },
                child: Text(socialText(context, 'حذف', 'Remove')),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
