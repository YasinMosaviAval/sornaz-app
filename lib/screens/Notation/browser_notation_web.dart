import 'notation_top_bar.dart';
import 'package:sornaz/components/main_tabs.dart';
import 'package:sornaz/components/join_community.dart';
import 'package:sornaz/components/home_top_bar.dart';
import 'package:sornaz/screens/Home/ui/components/app_drawer.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/browser_bridge.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/screens/Authentication/ui/pages/authentication.dart';
import 'notation_api.dart';

class BrowserNotationHost extends StatefulWidget {
  const BrowserNotationHost({
    super.key,
    required this.token,
    required this.userId,
  });
  final String token;
  final int userId;
  @override
  State<BrowserNotationHost> createState() => _BrowserNotationHostState();
}

class _BrowserNotationHostState extends State<BrowserNotationHost> {
  html.IFrameElement? frame;
  bool guestTab = false;
  double guestTop = 88;
  ValueChanged<bool>? setEditorOpen;
  late final NotationApi api = NotationApi(widget.token, userId: widget.userId);
  StreamSubscription<html.MessageEvent>? subscription;
  final channel = DateTime.now().microsecondsSinceEpoch.toString();
  String route = 'list';
  Map<String, dynamic> toolbar = {};
  @override
  void initState() {
    super.initState();
    subscription = html.window.onMessage.listen(message);
  }

  Map<String, dynamic> get configuration => {
    'locale': context.read<LocaleProvider>().locale.languageCode,
    'dark': context.read<AppData>().isDark,
    'userId': widget.userId,
    'embedded': true,
    'nativeToolbar': true,
    'browser': true,
    'accent':
        '#${context.read<AppData>().accent.toARGB32().toRadixString(16).substring(2)}',
  };
  Future<void> setup(Object element) async {
    frame = element as html.IFrameElement;
    frame!.style.border = '0';
    frame!.style.width = '100%';
    frame!.style.height = '100%';
    final source = await rootBundle.loadString('assets/notation/index.html');
    if (!mounted) return;
    final bridge =
        '''<base href="${Uri.base.resolve('assets/assets/notation/')}">
<script>
window.NOTATION_BOOT=${jsonEncode(configuration)};
window.SornazNotation={postMessage:(data)=>parent.postMessage({channel:'$channel',data},${jsonEncode(Uri.base.origin)})};
window.addEventListener('message',(event)=>{
 if(event.source!==parent||event.origin!==${jsonEncode(Uri.base.origin)}||event.data.channel!=='$channel')return;
 const value=event.data;
 if(value.action==='reply')window.Notation.receive(value.id,value.data,value.error);
 if(value.action==='configure')window.Notation.configure(value.data);
 if(value.action==='command')window.Notation.command(value.data);
 if(value.action==='back')window.Notation.back();
 if(value.action==='search')window.Notation.search(value.data);
});
</script>''';
    frame!.srcdoc = source.replaceFirst('<head>', '<head>$bridge');
  }

  Future<void> message(html.MessageEvent event) async {
    if (!mounted ||
        event.source != frame?.contentWindow ||
        event.origin != Uri.base.origin)
      return;
    final envelope = event.data;
    if (envelope is! Map ||
        envelope['channel'] != channel ||
        envelope['data'] is! String)
      return;
    final raw = envelope['data'] as String;
    if (raw.length > 10000000) return;
    int? id;
    dynamic result;
    String? error;
    try {
      final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      id = data['id'] as int?;
      final action = data['action'];
      if (action == 'route') {
        final nextTop = (data['guestTop'] as num?)?.toDouble() ?? 88;
        final nextToolbar = Map<String, dynamic>.from(
          data['toolbar'] as Map? ?? {},
        );
        if (jsonEncode(toolbar) == jsonEncode(nextToolbar) &&
            route == data['route'] &&
            guestTab == (data['guest'] == true) &&
            guestTop == nextTop)
          return;
        setState(() {
          route = data['route'] as String;
          toolbar = nextToolbar;
          setEditorOpen?.call(route != 'list');
          guestTop = (data['guestTop'] as num?)?.toDouble() ?? 88;
          guestTab = data['guest'] == true;
        });
        return;
      }
      if (action == 'exit') {
        final tabs = MainTabsScope.maybeOf(context);
        if (tabs != null) {
          tabs.select(0);
        } else {
          Navigator.maybePop(context);
        }
        return;
      }
      if (action == 'login') {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
        );
        return;
      }
      if (action == 'export' || action == 'download') {
        await browserCall('exportText', {
          'text': data['content'],
          'name': data['name'] ?? 'sornaz-notation.json',
        });
        if (action == 'download')
          await api.markDownloaded(data['sheetId'] as int);
        result = true;
      } else {
        result = await api.request(action as String, data);
      }
    } catch (e) {
      error = 'Connection failed. Your changes are still here.';
    }
    if (mounted && id != null)
      frame?.contentWindow?.postMessage({
        'channel': channel,
        'action': 'reply',
        'id': id,
        'data': result,
        'error': error,
      }, Uri.base.origin);
  }

  @override
  void dispose() {
    setEditorOpen?.call(false);
    subscription?.cancel();
    frame?.src = 'about:blank';
    api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    setEditorOpen = MainTabsScope.maybeOf(context)?.setEditorOpen;
    context.watch<AppData>();
    context.watch<LocaleProvider>();
    frame?.contentWindow?.postMessage({
      'channel': channel,
      'action': 'configure',
      'data': configuration,
    }, Uri.base.origin);
    return PopScope(
      canPop: route == 'list',
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && route != 'list')
          frame?.contentWindow?.postMessage({
            'channel': channel,
            'action': 'back',
          }, Uri.base.origin);
      },
      child: Scaffold(
        appBar: route != 'list'
            ? NotationTopBar(
                editor: route == 'editor',
                signedIn: widget.userId > 0,
                data: toolbar,
                command: (action) => frame?.contentWindow?.postMessage({
                  'channel': channel,
                  'action': 'command',
                  'data': action,
                }, Uri.base.origin),
              )
            : HomeTopBar(
                leadingWidget: const BackButton(),
                hint: socialText(
                  context,
                  'جست‌وجوی نت‌ها…',
                  'Search music sheets…',
                ),
                onSearch: route != 'list'
                    ? null
                    : (q) => frame?.contentWindow?.postMessage({
                        'channel': channel,
                        'action': 'search',
                        'data': q,
                      }, Uri.base.origin),
              ),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: HtmlElementView.fromTagName(
                      tagName: 'iframe',
                      onElementCreated: setup,
                    ),
                  ),
                  if (guestTab)
                    Positioned.fill(
                      top: guestTop,
                      child: ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: const JoinCommunity(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
