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
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/screens/Authentication/ui/pages/authentication.dart';
import 'notation_api.dart';

class BrowserNotationHost extends StatefulWidget {
  const BrowserNotationHost({super.key, required this.token, required this.userId});
  final String token;
  final int userId;
  @override
  State<BrowserNotationHost> createState() => _BrowserNotationHostState();
}
class _BrowserNotationHostState extends State<BrowserNotationHost> {
  html.IFrameElement? frame;
  late final NotationApi api = NotationApi(widget.token);
  StreamSubscription<html.MessageEvent>? subscription;
  final channel = DateTime.now().microsecondsSinceEpoch.toString();
  String route = 'list';
  @override
  void initState() { super.initState(); subscription = html.window.onMessage.listen(message); }
  Map<String,dynamic> get configuration => {'locale': context.read<LocaleProvider>().locale.languageCode,
    'dark': context.read<AppData>().isDark, 'userId':widget.userId, 'embedded':true};
  Future<void> setup(Object element) async {
    frame = element as html.IFrameElement;
    frame!.style.border = '0'; frame!.style.width = '100%'; frame!.style.height = '100%';
    final source = await rootBundle.loadString('assets/notation/index.html');
    if (!mounted) return;
    final bridge = '''<base href="${Uri.base.resolve('assets/assets/notation/')}">
<script>
window.NOTATION_BOOT=${jsonEncode(configuration)};
window.SornazNotation={postMessage:(data)=>parent.postMessage({channel:'$channel',data},${jsonEncode(Uri.base.origin)})};
window.addEventListener('message',(event)=>{
 if(event.source!==parent||event.origin!==${jsonEncode(Uri.base.origin)}||event.data.channel!=='$channel')return;
 const value=event.data;
 if(value.action==='reply')window.Notation.receive(value.id,value.data,value.error);
 if(value.action==='configure')window.Notation.configure(value.data);
});
</script>''';
    frame!.srcdoc = source.replaceFirst('<head>', '<head>$bridge');
  }
  Future<void> message(html.MessageEvent event) async {
    if (!mounted || event.source != frame?.contentWindow || event.origin != Uri.base.origin) return;
    final envelope = event.data;
    if (envelope is! Map || envelope['channel'] != channel || envelope['data'] is! String) return;
    final raw = envelope['data'] as String;
    if (raw.length > 400000) return;
    int? id;
    dynamic result;
    String? error;
    try {
      final data = Map<String,dynamic>.from(jsonDecode(raw) as Map);
      id = data['id'] as int?;
      final action = data['action'];
      if (action == 'route') { setState(() => route = data['route'] as String); return; }
      if (action == 'exit') { Navigator.maybePop(context); return; }
      if (action == 'login') { await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SignInScreen())); return; }
      if (action == 'export') {
        await browserCall('exportText', {'text':data['content'], 'name':'sornaz-notation.json'}); result=true;
      } else { result=await api.request(action as String, data); }
    } catch (e) { error=e.toString(); }
    if (mounted && id != null) frame?.contentWindow?.postMessage({'channel':channel,'action':'reply','id':id,'data':result,'error':error}, Uri.base.origin);
  }
  @override
  void dispose() { subscription?.cancel(); frame?.src='about:blank'; api.close(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    context.watch<AppData>(); context.watch<LocaleProvider>();
    frame?.contentWindow?.postMessage({'channel':channel,'action':'configure','data':configuration}, Uri.base.origin);
    return Scaffold(appBar: AppBar(title: Text(socialText(context, 'نت‌های موسیقی', 'Music Sheets'))), body: Column(children: [
      Expanded(child: HtmlElementView.fromTagName(tagName:'iframe', onElementCreated:setup)),
    ]),
      bottomNavigationBar: route == 'editor' ? null : const BottomNavBarWidget());
  }
}
