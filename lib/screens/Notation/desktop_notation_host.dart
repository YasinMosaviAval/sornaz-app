import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/screens/Authentication/ui/pages/authentication.dart';
import 'package:sornaz/screens/Home/ui/pages/music_tools.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'notation_api.dart';

/// Windows uses the same bundled editor in the system browser. Only the local
/// native bridge holds the account token; no credentials appear in the page.
class DesktopNotationHost extends StatefulWidget {
  const DesktopNotationHost({super.key, required this.token, required this.userId});
  final String token;
  final int userId;
  @override
  State<DesktopNotationHost> createState() => _DesktopNotationHostState();
}

class _DesktopNotationHostState extends State<DesktopNotationHost> {
  HttpServer? _server;
  late final NotationApi _api = NotationApi(widget.token);
  final String _secret = List.generate(32, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  bool _opening = false;
  String _locale = 'fa';
  bool _dark = false;

  Future<void> _open() async {
    if (widget.token.isEmpty) {
      await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SignInScreen()));
      return;
    }
    setState(() => _opening = true);
    _locale = context.read<LocaleProvider>().locale.languageCode;
    _dark = context.read<AppData>().isDark;
    try {
      if (_server == null) {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        if (!mounted) { await server.close(force: true); return; }
        _server = server;
        server.listen((request) => unawaited(_handle(request)));
      }
      final url = Uri.parse('http://127.0.0.1:${_server!.port}/$_secret/');
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw const FormatException('Browser unavailable');
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(socialText(context, 'باز کردن نت‌نویسی ممکن نشد. دوباره تلاش کنید.', 'Could not open notation. Please try again.'))));
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
      if (request.method == 'GET' && path.isEmpty) {
        var html = await rootBundle.loadString('assets/notation/index.html');
        final boot = jsonEncode({'locale': _locale, 'dark': _dark, 'userId': widget.userId, 'embedded': false, 'api': '/$_secret/api', 'csrf': _secret});
        html = html.replaceFirst('<head>', '<head><base href="/$_secret/assets/">');
        html = html.replaceFirst('<script src="notation.js"></script>', '<script>window.NOTATION_BOOT=$boot;</script><script src="notation.js"></script>');
        response.headers.contentType = ContentType.html;
        response.write(html);
        return;
      }
      const assets = {'index.html': 'text/html', 'notation.js': 'text/javascript', 'model.js': 'text/javascript', 'notation.css': 'text/css', 'vendor/vexflow.js': 'text/javascript', 'vendor/VEXFLOW-LICENSE': 'text/plain'};
      if (request.method == 'GET' && path.startsWith('assets/') && assets.containsKey(path.substring(7))) {
        final name = path.substring(7);
        response.headers.set('Content-Type', '${assets[name]}; charset=utf-8');
        final data = await rootBundle.load('assets/notation/$name');
        response.add(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
        return;
      }
      final route = RegExp(r'^api(?:/(\d+)(?:/(delete|bookmark))?)?$').firstMatch(path);
      if (route == null || !['GET', 'POST'].contains(request.method)) {
        response.statusCode = HttpStatus.notFound;
        return;
      }
      final id = int.tryParse(route.group(1) ?? '0') ?? 0;
      Map<String, dynamic> message;
      String action;
      if (request.method == 'GET') {
        if (route.group(2) != null) { response.statusCode = 405; return; }
        action = id == 0 ? 'list' : 'get';
        message = id == 0 ? {'mode': request.uri.queryParameters['mode'] ?? 'all', 'page': int.tryParse(request.uri.queryParameters['page'] ?? '1') ?? 1} : {'sheetId': id};
      } else {
        if (request.headers.value('X-CSRF-Token') != _secret) { response.statusCode = 403; return; }
        final bytes = <int>[];
        await for (final chunk in request) {
          if (bytes.length + chunk.length > 300000) { response.statusCode = 413; return; }
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
      response.write(jsonEncode({'success': false, 'message': 'Connection failed. Your changes are still here.'}));
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
    title: socialText(context, 'نت‌های موسیقی', 'Music Sheets'),
    bottom: const BottomNavBarWidget(selectedIndex: 1),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Padding(
      padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.piano, size: 64), const SizedBox(height: 24),
        Text(socialText(context, 'نت‌نویسی در مرورگر سیستم باز می‌شود. برای ادامهٔ کار، برنامه را باز نگه دارید.', 'Notation opens in your system browser. Keep the app open while editing.'), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: _opening ? null : _open, icon: const Icon(Icons.open_in_browser), label: Text(socialText(context, 'باز کردن نت‌نویسی', 'Open notation'))),
        const SizedBox(height: 12),
        TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MusicToolsPage())), child: Text(socialText(context, 'ابزار موسیقی', 'Music tools'))),
      ]),
    ))),
  );
}
