import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Authentication/ui/pages/authentication.dart';
import 'package:sornaz/screens/Home/ui/pages/music_tools.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'notation_api.dart';
import 'desktop_notation_host.dart';

class MusicSheetsPage extends StatelessWidget {
  const MusicSheetsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    if (Platform.isWindows) {
      return DesktopNotationHost(key: ValueKey(session.token), token: session.token ?? "", userId: session.user?.id ?? 0);
    }
    // A fresh host on account changes keeps private data out of the next account.
    return _NotationHost(
      key: ValueKey(session.token),
      token: session.token ?? '',
      userId: session.user?.id ?? 0,
    );
  }
}

class _NotationHost extends StatefulWidget {
  const _NotationHost({super.key, required this.token, required this.userId});
  final String token;
  final int userId;
  @override
  State<_NotationHost> createState() => _NotationHostState();
}

class _NotationHostState extends State<_NotationHost> with WidgetsBindingObserver {
  late final WebViewController _controller;
  late final NotationApi _api;
  bool _ready = false;
  bool _failed = false;
  String _route = 'list';
  String _configuration = '';
  static const _asset = 'assets/notation/index.html';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _api = NotationApi(widget.token);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('SornazNotation', onMessageReceived: _message)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            return uri?.scheme == 'file' &&
                    uri!.path.endsWith('/flutter_assets/$_asset')
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _ready = true;
              _failed = false;
            });
            unawaited(_configure());
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() => _failed = true);
            }
          },
        ),
      )
      ..loadFlutterAsset(_asset);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.watch<AppData>();
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final next = jsonEncode({
      'locale': locale,
      'dark': app.isDark,
      'userId': widget.userId,
      'embedded': true,
      'fontScale': ((16 + app.fontSize) / 16).clamp(.8, 1.5),
    });
    if (next != _configuration) {
      _configuration = next;
      if (_ready) unawaited(_configure());
    }
  }

  Future<void> _configure() async {
    if (!mounted || !_ready) return;
    await _controller.runJavaScript(
      'window.Notation.configure($_configuration);',
    );
  }

  Future<void> _message(JavaScriptMessage message) async {
    int? requestId;
    try {
      if (message.message.length > 400000) return;
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      requestId = data['id'] as int?;
      final action = data['action'] as String;
      if (action == 'route') {
        final route = data['route'];
        if (mounted && ['list', 'form', 'editor'].contains(route)) {
          setState(() => _route = route as String);
        }
        return;
      }
      if (action == 'exit') {
        if (mounted) Navigator.maybePop(context);
        return;
      }
      if (action == 'login') {
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
          );
        }
        return;
      }
      dynamic result;
      if (action == 'export') {
        final content = data['content'];
        if (content is! String ||
            utf8.encode(content).length > 300000 ||
            jsonDecode(content)['format'] != 'sornaz-notation') {
          throw const FormatException('Invalid score data.');
        }
        final directory = Directory(
          '${(await getTemporaryDirectory()).path}/notation-exports',
        );
        await directory.create(recursive: true);
        final file = File('${directory.path}/sornaz-notation.json');
        await file.writeAsString(content, flush: true);
        await const MethodChannel(
          'sornaz/app_share',
        ).invokeMethod<void>('shareNotation', {'path': file.path});
        result = true;
      } else {
        result = await _api.request(action, data);
      }
      if (mounted && requestId != null) await _reply(requestId, result, null);
    } catch (error) {
      if (mounted && requestId != null) {
        await _reply(
          requestId,
          null,
          error is SocialException
              ? error.message
              : 'Connection failed. Your changes are still here.',
        );
      }
    }
  }

  Future<void> _reply(
    int id,
    dynamic data,
    String? error,
  ) => _controller.runJavaScript(
    'window.Notation.receive($id,${jsonEncode(data)},${jsonEncode(error)});',
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_ready && state != AppLifecycleState.resumed) {
      unawaited(_controller.runJavaScript("window.Notation.dispose();").catchError((_) {}));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _api.close();
    if (_ready) {
      unawaited(
        _controller
            .runJavaScript('window.Notation.dispose();')
            .catchError((_) {}),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppData>().isDark;
    return PopScope(
      canPop: _route == 'list',
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _ready) {
          unawaited(_controller.runJavaScript('window.Notation.back();'));
        }
      },
      child: Scaffold(
        backgroundColor: _route == 'editor' || !dark
            ? Colors.white
            : Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              if (_route == 'list')
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const MusicToolsPage(),
                      ),
                    ),
                    icon: const Icon(Icons.tune),
                    label: Text(
                      socialText(context, 'ابزار موسیقی', 'Music tools'),
                    ),
                  ),
                ),
              Expanded(
                child: _failed
                    ? Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() => _failed = false);
                            _controller.loadFlutterAsset(_asset);
                          },
                          child: Text(
                            socialText(context, 'تلاش دوباره', 'Retry'),
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          WebViewWidget(controller: _controller),
                          if (!_ready)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _route == 'list'
            ? const BottomNavBarWidget(selectedIndex: 1)
            : null,
      ),
    );
  }
}
