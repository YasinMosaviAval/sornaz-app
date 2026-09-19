import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Notation/notation_api.dart';

void main() {
  test(
    'instrument catalog uses its GET endpoint and persists for offline notation',
    () async {
      SharedPreferences.setMockInitialValues({});
      const items = [
        {'id': 42, 'fa': 'سنتور', 'en': 'Santur'},
      ];
      final online = NotationApi(
        '',
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(
            request.url.path.endsWith('/music-sheets/instruments'),
            isTrue,
          );
          return http.Response.bytes(
            utf8.encode(jsonEncode({'success': true, 'data': items})),
            200,
          );
        }),
      );
      expect(await online.request('instruments', {}), items);
      online.close();
      final offline = NotationApi(
        '',
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      expect(await offline.request('instruments', {}), items);
      offline.close();
    },
  );
}
