import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:archive/archive.dart';
import 'dart:convert';
import 'protected_media.dart';
import 'social_widgets.dart';
import 'social_api.dart';
import 'course_cache.dart';

class ProtectedMediaView extends StatefulWidget {
  const ProtectedMediaView({
    super.key,
    required this.api,
    required this.file,
    required this.mime,
  });
  final SocialApi api;
  final File file;
  final String mime;
  @override
  State<ProtectedMediaView> createState() => _ProtectedMediaViewState();
}

class _ProtectedMediaViewState extends State<ProtectedMediaView> {
  File? clear;
  late final opened = ProtectedMedia(CourseCache.account(widget.api.token))
      .open(widget.file)
      .then((file) {
        if (!mounted) {
          ProtectedMedia.close(file);
          throw StateError('Closed');
        }
        clear = file;
        return file;
      });
  @override
  void dispose() {
    if (clear != null) ProtectedMedia.close(clear!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<File>(
    future: opened,
    builder: (_, snapshot) {
      if (snapshot.hasError)
        return const SocialEmpty('فایل قابل باز شدن نیست؛ دوباره دانلود کنید.');
      if (!snapshot.hasData)
        return const Center(child: CircularProgressIndicator());
      final file = snapshot.data!;
      if (widget.mime.startsWith('video/') || widget.mime.startsWith('audio/'))
        return SocialVideo(api: widget.api, path: '', localFile: file);
      if (widget.mime.startsWith('image/')) return Image.file(file);
      if (widget.mime == 'application/pdf') return _PdfPages(file: file);
      return FutureBuilder<String>(
        future: _document(file),
        builder: (_, text) => Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            text.hasError
                ? 'این سند قابل نمایش نیست.'
                : text.data ?? 'در حال خواندن سند…',
          ),
        ),
      );
    },
  );
  Future<String> _document(File file) async {
    final bytes = await file.readAsBytes();
    if (widget.mime.contains('wordprocessingml')) {
      final archive = ZipDecoder().decodeBytes(bytes);
      final document = archive.findFile('word/document.xml');
      if (document == null) throw const FormatException();
      return utf8
          .decode(document.content)
          .replaceAll('</w:p>', '\n')
          .replaceAll(RegExp('<[^>]+>'), '')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>');
    }
    return utf8.decode(bytes);
  }
}

class _PdfPages extends StatefulWidget {
  const _PdfPages({required this.file});
  final File file;
  @override
  State<_PdfPages> createState() => _PdfPagesState();
}

class _PdfPagesState extends State<_PdfPages> {
  static const channel = MethodChannel('sornaz/private_pdf');
  int page = 0;
  late Future<Map<dynamic, dynamic>?> rendering = render();
  Future<Map<dynamic, dynamic>?> render() => channel.invokeMapMethod('render', {
    'path': widget.file.path,
    'page': page,
  });
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: rendering,
    builder: (_, snapshot) {
      if (snapshot.hasError) return const SocialEmpty('نمایش سند ممکن نشد.');
      if (!snapshot.hasData)
        return const Center(child: CircularProgressIndicator());
      final data = snapshot.data!;
      return Column(
        children: [
          InteractiveViewer(child: Image.memory(data['bytes'] as Uint8List)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: page == 0
                    ? null
                    : () => setState(() {
                        page--;
                        rendering = render();
                      }),
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${page + 1} / ${data['count']}'),
              IconButton(
                onPressed: page + 1 >= (data['count'] as int)
                    ? null
                    : () => setState(() {
                        page++;
                        rendering = render();
                      }),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      );
    },
  );
}
