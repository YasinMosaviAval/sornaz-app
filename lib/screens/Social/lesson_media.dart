import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'social_api.dart';
import 'social_widgets.dart';
import 'social_downloads.dart';
import 'protected_media_view.dart';

class LessonMedia extends StatefulWidget {
  const LessonMedia({
    super.key,
    required this.api,
    required this.courseId,
    required this.id,
    required this.mime,
    required this.title,
  });
  final SocialApi api;
  final int? courseId;
  final int id;
  final String mime, title;
  @override
  State<LessonMedia> createState() => _LessonMediaState();
}

class _LessonMediaState extends State<LessonMedia> {
  late final local = find();
  Future<File?> find() async {
    if (kIsWeb || widget.courseId == null) return null;
    try {
      final dir = await LessonDownloads(widget.api).directory();
      final file = File('${dir.path}/${widget.courseId}-${widget.id}.sornaz');
      return await file.exists() ? file : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<File?>(
    future: local,
    builder: (_, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const Center(child: CircularProgressIndicator());
      if (snapshot.data != null)
        return ProtectedMediaView(
          api: widget.api,
          file: snapshot.data!,
          mime: widget.mime,
        );
      if (widget.mime.startsWith('video/') || widget.mime.startsWith('audio/'))
        return SocialVideo(
          api: widget.api,
          path: widget.api.courseMedia(widget.id),
          title: widget.title,
        );
      return SocialImage(
        api: widget.api,
        path: widget.api.courseMedia(widget.id),
        width: double.infinity,
        fit: BoxFit.contain,
      );
    },
  );
}
