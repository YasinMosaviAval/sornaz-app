import 'package:sornaz/components/scroll_aware_scaffold.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'notation_settings.dart';
import 'notation_top_bar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sornaz/components/main_tabs.dart';
import 'package:sornaz/components/join_community.dart';
import 'package:sornaz/components/home_top_bar.dart';
import 'package:sornaz/screens/Home/ui/components/app_drawer.dart';
import 'package:flutter/foundation.dart';
import 'browser_notation_host.dart';
import 'package:sornaz/helpers/app_platform.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Authentication/ui/pages/authentication.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'notation_api.dart';
import 'desktop_notation_host.dart';

class MusicSheetsPage extends StatelessWidget {
  const MusicSheetsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    if (kIsWeb)
      return BrowserNotationHost(
        key: ValueKey(session.token),
        token: session.token ?? '',
        userId: session.user?.id ?? 0,
      );
    if (AppPlatform.isWindows) {
      return DesktopNotationHost(
        key: ValueKey(session.token),
        token: session.token ?? "",
        userId: session.user?.id ?? 0,
      );
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

class _NotationHostState extends State<_NotationHost>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  late final NotationApi _api;
  bool _ready = false;
  bool _failed = false;
  String _route = 'list';
  Map<String, dynamic> _toolbar = {};
  bool _guestTab = false;
  double _guestTop = 88;
  ValueChanged<bool>? _setEditorOpen;
  String _configuration = '';
  static const _asset = 'assets/notation/index.html';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _api = NotationApi(widget.token, userId: widget.userId);
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
    _setEditorOpen = MainTabsScope.maybeOf(context)?.setEditorOpen;
    final app = context.watch<AppData>();
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final next = jsonEncode({
      'locale': locale,
      'dark': app.isDark,
      'userId': widget.userId,
      'embedded': true,
      'nativeToolbar': true,
      'accent': '#${app.accent.toARGB32().toRadixString(16).substring(2)}',
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
      if (message.message.length > 10000000) return;
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      requestId = data['id'] as int?;
      final action = data['action'] as String;
      if (action == 'route') {
        final route = data['route'];
        if (mounted && ['list', 'form', 'editor'].contains(route)) {
          setState(() {
            _route = route as String;
            _toolbar = Map<String, dynamic>.from(data['toolbar'] as Map? ?? {});
            _setEditorOpen?.call(_route != 'list');
            _guestTop = (data['guestTop'] as num?)?.toDouble() ?? 88;
            _guestTab = data['guest'] == true;
          });
        }
        return;
      }
      if (action == 'exit') {
        if (mounted) {
          final tabs = MainTabsScope.maybeOf(context);
          if (tabs != null) {
            tabs.select(0);
          } else {
            Navigator.maybePop(context);
          }
        }
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
      if (action == 'pdf') {
        final html = data['html'];
        if (html is! String || html.length > 8000000)
          throw const FormatException('Invalid PDF data.');
        result = await const MethodChannel(
          'sornaz/notation_storage',
        ).invokeMethod<String>('pdf', {'html': html, 'name': data['name']});
      } else if (action == 'export' || action == 'download') {
        final content = data['content'];
        if (content is! String ||
            utf8.encode(content).length > 300000 ||
            jsonDecode(content)['format'] != 'sornaz-notation') {
          throw const FormatException('Invalid score data.');
        }
        const storage = MethodChannel('sornaz/notation_storage');
        final sdk = await storage.invokeMethod<int>('sdk') ?? 29;
        if (sdk < 29 && !await Permission.storage.request().isGranted) {
          throw const SocialException(
            'Storage permission is required to download this sheet.',
          );
        }
        await storage.invokeMethod<String>('save', {
          'content': content,
          'name': data['name'],
        });
        if (action == 'download')
          await _api.markDownloaded(data['sheetId'] as int);
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
          error is PlatformException && error.code == 'NOTATION_STORAGE'
              ? 'Could not save the music sheet.'
              : error is SocialException
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
      unawaited(
        _controller
            .runJavaScript("window.Notation.dispose();")
            .catchError((_) {}),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setEditorOpen?.call(false);
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
        if (!didPop && _ready && _route != 'list') {
          unawaited(_controller.runJavaScript('window.Notation.back();'));
        }
      },
      child: ScrollAwareScaffold(
        appBar: _route != 'list'
            ? NotationTopBar(
                editor: _route == 'editor',
                signedIn: widget.userId > 0,
                data: _toolbar,
                command: (action) => _controller.runJavaScript(
                  'window.Notation.command(${jsonEncode(action)});',
                ),
              )
            : HomeTopBar(
                leadingWidget: const BackButton(),
                extraActions: [
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      size: 24,
                      color: AppColors.sornaz_app_bar_text_color(
                        isDark: Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const NotationSettingsPage(),
                      ),
                    ),
                  ),
                ],
                hint: socialText(
                  context,
                  'جست‌وجوی نت‌ها…',
                  'Search music sheets…',
                ),
                onSearch: _route != 'list'
                    ? null
                    : (q) {
                        if (_ready)
                          _controller.runJavaScript(
                            'window.Notation.search(${jsonEncode(q)});',
                          );
                      },
              ),
        drawer: const AppDrawer(),
        backgroundColor: _route == 'editor' || !dark
            ? Colors.white
            : Colors.black,
        body: SafeArea(
          child: Column(
            children: [
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
                          if (_guestTab)
                            Positioned.fill(
                              top: _guestTop,
                              child: ColoredBox(
                                color: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                child: const JoinCommunity(),
                              ),
                            ),
                          if (!_ready)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
