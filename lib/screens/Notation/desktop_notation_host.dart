import 'package:sornaz/components/home_top_bar.dart';
import 'package:sornaz/screens/Home/ui/components/app_drawer.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/screens/Authentication/ui/pages/authentication.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'notation_api.dart';
import 'omr_review_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/development_access.dart';
import 'notation_settings.dart';
import 'package:sornaz/helpers/desktop_media_channel.dart';

/// Windows uses the same bundled editor in the system browser. Only the local
/// native bridge holds the account token; no credentials appear in the page.
class DesktopNotationHost extends StatefulWidget {
  const DesktopNotationHost({
    super.key,
    required this.token,
    required this.userId,
  });
  final String token;
  final int userId;
  @override
  State<DesktopNotationHost> createState() => _DesktopNotationHostState();
}

class _DesktopNotationHostState extends State<DesktopNotationHost> {
  HttpServer? _server;
  late final NotationApi _api = NotationApi(
    widget.token,
    userId: widget.userId,
  );
  final String _secret = List.generate(
    32,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  bool _opening = false;
  String _locale = 'fa';
  bool _dark = false;
  Map<String, Object?>? _pendingScore;
  Map<String, Object?> _appearance = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.watch<AppData>();
    _locale = context.watch<LocaleProvider>().locale.languageCode;
    _dark = app.isDark;
    _appearance = {
      'locale': _locale,
      'dark': _dark,
      'accent': '#${app.accent.toARGB32().toRadixString(16).substring(2)}',
      'fontScale': ((16 + app.fontSize) / 16).clamp(.8, 1.5),
      'fontFamily': app.fontFamily,
      'fontWeight': (400 + app.fontWeight * 100).round().clamp(100, 900),
      'cornerRadius': app.cornerRadius,
    };
  }

  Future<void> _recognize() async {
    if (_opening || !DevelopmentAccess.read(context)) return;
    try {
      final source = await showModalBottomSheet<String>(
        context: context,
        builder: (sheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(socialText(sheet, 'گرفتن عکس', 'Take photo')),
                onTap: () => Navigator.pop(sheet, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  socialText(sheet, 'انتخاب از گالری', 'Choose from gallery'),
                ),
                onTap: () => Navigator.pop(sheet, 'file'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || source == null || !DevelopmentAccess.read(context))
        return;
      Uint8List bytes;
      if (source == 'camera') {
        final captured =
            await DesktopMedia.invoke('sornaz/story_media', 'camera', {})
                as Map;
        final file = await DesktopMedia.privateFile('${captured['path']}');
        try {
          if (await file.length() > 12000000)
            throw const FormatException('Image is too large.');
          bytes = await file.readAsBytes();
        } finally {
          await file.delete();
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (result == null) return;
        final file = result.files.single;
        if (file.size > 12000000)
          throw const FormatException('Image is too large.');
        bytes = file.bytes ?? await File(file.path!).readAsBytes();
      }
      if (!mounted || !DevelopmentAccess.read(context)) return;
      final score = await Navigator.push<Map<String, Object?>>(
        context,
        MaterialPageRoute(builder: (_) => OmrReviewPage(imageBytes: bytes)),
      );
      if (!mounted || score == null || !DevelopmentAccess.read(context)) return;
      _pendingScore = score;
      await _open();
    } catch (error) {
      if (mounted) socialError(context, error);
    }
  }

  Future<void> _open() async {
    setState(() => _opening = true);
    _locale = context.read<LocaleProvider>().locale.languageCode;
    _dark = context.read<AppData>().isDark;
    try {
      if (_server == null) {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        if (!mounted) {
          await server.close(force: true);
          return;
        }
        _server = server;
        server.listen((request) => unawaited(_handle(request)));
      }
      final url = Uri.parse('http://127.0.0.1:${_server!.port}/$_secret/');
      if (!await launchUrl(url, mode: LaunchMode.externalApplication))
        throw const FormatException('Browser unavailable');
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              socialText(
                context,
                'باز کردن نت‌نویسی ممکن نشد. دوباره تلاش کنید.',
                'Could not open notation. Please try again.',
              ),
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    response.headers.set('Cache-Control', 'no-store');
    response.headers.set('X-Content-Type-Options', 'nosniff');
    response.headers.set('X-Frame-Options', 'DENY');
    try {
      final expectedHost = '127.0.0.1:${_server?.port}';
      final origin = request.headers.value('origin');
      if (request.headers.value('host') != expectedHost ||
          (origin != null && origin != 'http://$expectedHost') ||
          !request.uri.path.startsWith('/$_secret/')) {
        response.statusCode = HttpStatus.forbidden;
        return;
      }
      final path = request.uri.path.substring(_secret.length + 2);
      if (request.method == 'POST' && path == 'desktop-login') {
        if (!mounted || request.headers.value('X-CSRF-Token') != _secret) {
          response.statusCode = HttpStatus.forbidden;
          return;
        }
        await const MethodChannel(
          'sornaz/video_controls',
        ).invokeMethod<void>('activate');
        if (mounted)
          unawaited(
            Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const SignInScreen()),
            ),
          );
        response.headers.contentType = ContentType.json;
        response.write('{"success":true}');
        return;
      }
      if (request.method == 'POST' && path == 'desktop-export') {
        if (request.headers.value('X-CSRF-Token') != _secret) {
          response.statusCode = HttpStatus.forbidden;
          return;
        }
        final bytes = <int>[];
        await for (final chunk in request) {
          if (bytes.length + chunk.length > 2000000) {
            response.statusCode = 413;
            return;
          }
          bytes.addAll(chunk);
        }
        final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        final content = data['content'];
        if (content is! String || utf8.encode(content).length > 1000000) {
          response.statusCode = 422;
          return;
        }
        if ('${data['name']}'.endsWith('.json') &&
            jsonDecode(content)['format'] != 'sornaz-notation') {
          response.statusCode = 422;
          return;
        }
        await DesktopMedia.invoke('sornaz/notation_storage', 'save', data);
        response.headers.contentType = ContentType.json;
        response.write('{"success":true}');
        return;
      }
      if (request.method == 'GET' && path == 'desktop-state') {
        final prefs = await SharedPreferences.getInstance();
        final score = mounted && DevelopmentAccess.read(context)
            ? _pendingScore
            : null;
        _pendingScore = null;
        response.headers.contentType = ContentType.json;
        response.write(
          jsonEncode({
            'config': {
              ..._appearance,
              'durationMode': prefs.getInt('notation.durationMode') ?? 1,
              'pianoLabelMode': prefs.getInt('notation.pianoLabelMode') ?? 1,
            },
            'score': score,
          }),
        );
        return;
      }
      if (request.method == 'GET' && path.isEmpty) {
        var html = await rootBundle.loadString('assets/notation/index.html');
        final boot = jsonEncode({
          'locale': _locale,
          'dark': _dark,
          'userId': widget.userId,
          'embedded': false,
          'api': '/$_secret/api',
          'csrf': _secret,
          ..._appearance,
        });
        html = html.replaceFirst(
          '<head>',
          '<head><base href="/$_secret/assets/">',
        );
        html = html.replaceFirst('</body>', '''<script>
let sornazDesktopPolling=false,sornazDesktopConfig='';
const sornazAnchorClick=HTMLAnchorElement.prototype.click;
HTMLAnchorElement.prototype.click=function(){
 if(!this.download||!this.href.startsWith('blob:'))return sornazAnchorClick.call(this);
 const href=this.href,name=this.download;
 (async()=>{
  const content=await(await fetch(href)).text();
  const result=await fetch('/$_secret/desktop-export',{method:'POST',
   headers:{'Content-Type':'application/json','X-CSRF-Token':'$_secret'},
   body:JSON.stringify({name,content})});
  if(!result.ok)throw Error('Could not save the score. Check the selected folder.');
 })().catch(error=>window.alert(error.message));
};
setInterval(async()=>{
 if(sornazDesktopPolling||!window.Notation)return;
 sornazDesktopPolling=true;
 try {
  const response=await fetch('/$_secret/desktop-state',{cache:'no-store'});
  if(!response.ok)return;
  const state=await response.json(),config=JSON.stringify(state.config);
  if(config!==sornazDesktopConfig){window.Notation.configure(state.config);sornazDesktopConfig=config;}
  if(state.score)await window.Notation.importContent(JSON.stringify(state.score),'omr.json');
 }catch(error){console.error(error);}finally{sornazDesktopPolling=false;}
},1000);
</script></body>''');
        html = html.replaceFirst(
          '<script src="notation.js"></script>',
          '<script>window.NOTATION_BOOT=$boot;</script><script src="notation.js"></script>',
        );
        response.headers.contentType = ContentType.html;
        response.write(html);
        return;
      }
      const assets = {
        'index.html': 'text/html',
        'notation.js': 'text/javascript',
        'ui_symbols.js': 'text/javascript',
        'ui_glyphs.js': 'text/javascript',
        'ui_controls.js': 'text/javascript',
        'ui_controls.css': 'text/css',
        'score_renderer.js': 'text/javascript',
        'importer.js': 'text/javascript',
        'model.js': 'text/javascript',
        'notation.css': 'text/css',
        'vendor/vexflow.js': 'text/javascript',
        'vendor/VEXFLOW-LICENSE': 'text/plain',
      };
      if (request.method == 'GET' &&
          path.startsWith('assets/') &&
          assets.containsKey(path.substring(7))) {
        final name = path.substring(7);
        response.headers.set('Content-Type', '${assets[name]}; charset=utf-8');
        final data = await rootBundle.load('assets/notation/$name');
        if (name == 'notation.js') {
          response.write(
            utf8
                .decode(
                  data.buffer.asUint8List(
                    data.offsetInBytes,
                    data.lengthInBytes,
                  ),
                )
                .replaceFirst(
                  "else location.href='/login';",
                  "else fetch('/$_secret/desktop-login',{method:'POST',headers:{'X-CSRF-Token':'$_secret'}});",
                ),
          );
          return;
        }
        response.add(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        return;
      }
      final route = RegExp(
        r'^api(?:/(-?\d+)(?:/(delete|bookmark|upload))?)?$',
      ).firstMatch(path);
      if (route == null || !['GET', 'POST'].contains(request.method)) {
        response.statusCode = HttpStatus.notFound;
        return;
      }
      final id = int.tryParse(route.group(1) ?? '0') ?? 0;
      Map<String, dynamic> message;
      String action;
      if (request.method == 'GET') {
        if (route.group(2) != null) {
          response.statusCode = 405;
          return;
        }
        action = id == 0 ? 'list' : 'get';
        message = id == 0
            ? {
                'mode': request.uri.queryParameters['mode'] ?? 'all',
                'page':
                    int.tryParse(request.uri.queryParameters['page'] ?? '1') ??
                    1,
              }
            : {'sheetId': id};
      } else {
        if (request.headers.value('X-CSRF-Token') != _secret) {
          response.statusCode = 403;
          return;
        }
        final bytes = <int>[];
        await for (final chunk in request) {
          if (bytes.length + chunk.length > 300000) {
            response.statusCode = 413;
            return;
          }
          bytes.addAll(chunk);
        }
        action = route.group(2) ?? 'save';
        message = {'sheetId': id, 'payload': jsonDecode(utf8.decode(bytes))};
      }
      final data = await _api.request(action, message);
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode({'success': true, 'data': data}));
    } catch (_) {
      response.statusCode = HttpStatus.badGateway;
      response.headers.contentType = ContentType.json;
      response.write(
        jsonEncode({
          'success': false,
          'message': 'Connection failed. Your changes are still here.',
        }),
      );
    } finally {
      await response.close();
    }
  }

  @override
  void dispose() {
    _api.close();
    unawaited(_server?.close(force: true));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SocialScaffold(
    appBar: const HomeTopBar(leadingWidget: BackButton()),
    drawer: const AppDrawer(),
    title: socialText(context, 'نت‌نویسی', 'Notation'),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.piano, size: 64),
              const SizedBox(height: 24),
              Text(
                socialText(
                  context,
                  'نت‌نویسی در مرورگر سیستم باز می‌شود. برای ادامهٔ کار، برنامه را باز نگه دارید.',
                  'Notation opens in your system browser. Keep the app open while editing.',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _opening ? null : _open,
                icon: const Icon(Icons.open_in_browser),
                label: Text(
                  socialText(context, 'باز کردن نت‌نویسی', 'Open notation'),
                ),
              ),
              const SizedBox(height: 12),
              if (DevelopmentAccess.watch(context))
                FilledButton.icon(
                  onPressed: _opening ? null : _recognize,
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: Text(
                    socialText(
                      context,
                      'تشخیص نت از تصویر',
                      'Recognize notes from image',
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotationSettingsPage(),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined),
                label: Text(
                  socialText(context, 'تنظیمات نت‌نویسی', 'Notation settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
