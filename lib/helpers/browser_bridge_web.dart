import 'dart:convert';
import 'dart:js_interop';
@JS('SornazBrowser.call')
external JSPromise<JSString> _call(JSString action, JSString data);
Future<dynamic> browserCall(String action, [Map<String, dynamic> data = const {}]) async =>
  jsonDecode((await _call(action.toJS, jsonEncode(data).toJS).toDart).toDart);
