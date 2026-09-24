import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../Social/course_cache.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import '../Social/story_page.dart';
import '../Social/user_panel.dart';
import 'panel_api.dart';
import 'panel_voice.dart';

class ChatFiles {
  static final pending = <String, Future<File>>{};
  static Future<File> open(PanelApi api, String id) async {
    api.checkAccount();
    if (!RegExp(r'^\d+$').hasMatch(id))
      throw const FormatException('Invalid message');
    final key = '${CourseCache.account(api.token)}:$id';
    return pending.putIfAbsent(
      key,
      () => _load(api, id).whenComplete(() {
        pending.remove(key);
      }),
    );
  }

  static Future<File> _load(PanelApi api, String id) async {
    return _fetch(api, id, api.uri('/chat/file', {'id': id}));
  }

  static Future<File> reference(PanelApi api, Json reference) async {
    api.checkAccount();
    final uri = Uri.parse(SocialApi.base).resolve('${reference['media']}');
    if (uri.origin != Uri.parse(SocialApi.base).origin ||
        !RegExp(r'/social/media/\d+$').hasMatch(uri.path)) {
      throw const FormatException('Invalid media');
    }
    final id = 'reference-${uri.path.split('/').last}';
    final key = '${CourseCache.account(api.token)}:$id';
    return pending.putIfAbsent(
      key,
      () => _fetch(api, id, uri).whenComplete(() {
        pending.remove(key);
      }),
    );
  }

  static Future<File> _fetch(PanelApi api, String id, Uri uri) async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory(
      '${root.path}/chat/${Uri.encodeComponent(CourseCache.account(api.token))}',
    );
    await dir.create(recursive: true);
    final file = File('${dir.path}/$id.media');
    if (await file.exists() && await file.length() > 0) {
      api.checkAccount();
      return file;
    }
    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..headers.addAll(api.headers);
    final response = await api.client
        .send(request)
        .timeout(const Duration(seconds: 30));
    api.checkAccount();
    if (response.statusCode != 200)
      throw SocialException('رسانه در دسترس نیست.', response.statusCode);
    final part = File('${file.path}.part');
    try {
      final output = part.openWrite();
      try {
        await output.addStream(
          response.stream.timeout(const Duration(seconds: 60)),
        );
      } finally {
        await output.close();
      }
      api.checkAccount();
      if (await part.length() == 0)
        throw const FormatException('Empty attachment');
      await part.rename(file.path);
    } catch (_) {
      if (await part.exists()) await part.delete();
      rethrow;
    }
    return file;
  }
}

bool chatAudio(Json file) =>
    '${file['mime']}'.startsWith('audio/') ||
    RegExp(
      r'\.(m4a|mp3|wav|ogg|opus|aac)$',
      caseSensitive: false,
    ).hasMatch('${file['name']}') ||
    RegExp(
      r'^voice-.*\.webm$',
      caseSensitive: false,
    ).hasMatch('${file['name']}');

class ChatMedia extends StatefulWidget {
  const ChatMedia({
    super.key,
    required this.api,
    required this.message,
    required this.onDownload,
  });
  final PanelApi api;
  final Json message;
  final VoidCallback onDownload;
  @override
  State<ChatMedia> createState() => _ChatMediaState();
}

class _ChatMediaState extends State<ChatMedia> {
  late final social = SocialApi(widget.api.token);
  Future<File>? local;
  Future<Uint8List?>? thumbnail;
  Timer? expiry;
  Future<Uint8List?> frame(Future<File> source) async {
    try {
      final file = await source;
      return await const MethodChannel(
        'sornaz/story_media',
      ).invokeMethod<Uint8List>('thumbnail', {
        'uri': Uri.file(file.path).toString(),
        'video': true,
        'timeMs': 0,
        'size': 320,
      });
    } catch (_) {
      return null;
    }
  }

  void loadMedia() {
    final file = optionalObject(widget.message['file']);
    if (reference.isNotEmpty && !unavailable && reference['media'] != null) {
      local = ChatFiles.reference(widget.api, reference);
      if ('${reference['mime']}'.startsWith('video/'))
        thumbnail = frame(local!);
    } else if (file.isNotEmpty && !chatAudio(file)) {
      local = ChatFiles.open(widget.api, '${widget.message['id']}');
      if ('${file['mime']}'.startsWith('video/')) thumbnail = frame(local!);
    }
  }

  Json get reference => optionalObject(widget.message['reference']);
  bool get unavailable {
    final r = reference;
    final at = DateTime.tryParse('${r['expiresAt']}');
    return r['available'] == false ||
        (r['kind'] == 'story' &&
            r['owner'] != true &&
            at != null &&
            !DateTime.now().isBefore(at));
  }

  @override
  void initState() {
    super.initState();
    loadMedia();
    if (reference['kind'] == 'story')
      expiry = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && unavailable) {
          setState(() {});
          expiry?.cancel();
        }
      });
  }

  @override
  void dispose() {
    expiry?.cancel();
    social.dispose();
    super.dispose();
  }

  Future<void> openReference() async {
    if (unavailable) return;
    try {
      final post = object(
        await social.get('/posts/${reference['id']}', refresh: true),
      );
      File? cached;
      try {
        cached = await local;
      } catch (_) {}
      if (!mounted || unavailable) return;
      await socialPush(
        context,
        ChatReferenceAccess(
          expiresAt: reference['kind'] == 'story' && reference['owner'] != true
              ? DateTime.tryParse('${reference['expiresAt']}')
              : null,
          child: reference['kind'] == 'story'
              ? StoryPage(
                  api: social,
                  stories: [post],
                  localMedia: {if (cached != null) number(post['id']): cached},
                )
              : Scaffold(
                  appBar: AppBar(),
                  body: ListView(
                    children: [
                      PostCard(api: social, post: post, localMedia: cached),
                    ],
                  ),
                ),
        ),
      );
    } catch (e) {
      if (mounted) socialError(context, e);
    }
  }

  Widget preview(Widget image, VoidCallback onTap, {bool video = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: SizedBox(
          width: 136,
          height: 176,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: GestureDetector(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image,
                  if (video)
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
  @override
  Widget build(BuildContext context) {
    if (reference.isNotEmpty) {
      if (unavailable)
        return Text(
          socialText(
            context,
            'این محتوا دیگر در دسترس نیست',
            'This content is no longer available',
          ),
          style: const TextStyle(fontSize: 11),
        );
      return preview(
        reference['media'] == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '${reference['body'] ?? ''}',
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
            : FutureBuilder<File>(
                future: local,
                builder: (_, snapshot) {
                  if (!snapshot.hasData)
                    return const ColoredBox(color: Colors.black26);
                  if ('${reference['mime']}'.startsWith('video/'))
                    return FutureBuilder<Uint8List?>(
                      future: thumbnail,
                      builder: (_, frame) => frame.data == null
                          ? const ColoredBox(color: Colors.black26)
                          : Image.memory(frame.data!, fit: BoxFit.cover),
                    );
                  return Image.file(snapshot.data!, fit: BoxFit.cover);
                },
              ),
        openReference,
        video: '${reference['mime']}'.startsWith('video/'),
      );
    }
    final file = optionalObject(widget.message['file']);
    if (file.isEmpty) return const SizedBox.shrink();
    if (chatAudio(file))
      return PanelVoicePlayback(
        mine: widget.message['mine'] == true,
        key: ValueKey(widget.message['id']),
        api: widget.api,
        messageId: '${widget.message['id']}',
      );
    final video = '${file['mime']}'.startsWith('video/');
    if (!video && !'${file['mime']}'.startsWith('image/'))
      return TextButton.icon(
        onPressed: widget.onDownload,
        icon: const Icon(Icons.attach_file),
        label: Text('${file['name']}'),
      );
    return FutureBuilder<File>(
      future: local,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return TextButton(
            onPressed: () => setState(() {
              loadMedia();
            }),
            child: Text(socialText(context, 'تلاش دوباره', 'Retry')),
          );
        if (!snapshot.hasData)
          return const SizedBox(
            width: 136,
            height: 176,
            child: Center(child: CircularProgressIndicator()),
          );
        final target = snapshot.data!;
        final image = video
            ? FutureBuilder<Uint8List?>(
                future: thumbnail,
                builder: (_, frame) => frame.data == null
                    ? const ColoredBox(color: Colors.black26)
                    : Image.memory(frame.data!, fit: BoxFit.cover),
              )
            : Image.file(target, fit: BoxFit.cover);
        return preview(
          image,
          () => socialPush(
            context,
            Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(),
              body: Center(
                child: video
                    ? SocialVideo(
                        api: social,
                        path: '',
                        localFile: target,
                        postControls: true,
                      )
                    : InteractiveViewer(child: Image.file(target)),
              ),
            ),
          ),
          video: video,
        );
      },
    );
  }
}

/// Expiring access also ends an already-open story and disposes its player.
class ChatReferenceAccess extends StatefulWidget {
  const ChatReferenceAccess({super.key, required this.child, this.expiresAt});
  final Widget child;
  final DateTime? expiresAt;
  @override
  State<ChatReferenceAccess> createState() => _ChatReferenceAccessState();
}

class _ChatReferenceAccessState extends State<ChatReferenceAccess> {
  Timer? timer;
  bool expired = false;
  @override
  void initState() {
    super.initState();
    final remaining = widget.expiresAt?.difference(DateTime.now());
    if (remaining != null) {
      expired = remaining <= Duration.zero;
      if (!expired)
        timer = Timer(remaining, () {
          if (mounted) setState(() => expired = true);
        });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => expired
      ? Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Text(
              socialText(
                context,
                'این محتوا دیگر در دسترس نیست',
                'This content is no longer available',
              ),
            ),
          ),
        )
      : widget.child;
}
