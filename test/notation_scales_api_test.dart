import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Notation/notation_api.dart';

void main() {
  test(
    'scale catalogs persist, refresh once, and retain last valid offline data',
    () async {
      SharedPreferences.setMockInitialValues({});
      var online = true, invalid = false;
      var version = 1, calls = 0;
      final api = NotationApi(
        '',
        client: MockClient((request) async {
          calls++;
          expect(request.url.path.endsWith('/music-sheets/scales'), isTrue);
          if (!online) throw http.ClientException('offline');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': invalid
                  ? [
                      {'id': 'bad'},
                    ]
                  : [
                      {
                        'id': 'major',
                        'fa': 'Major $version',
                        'en': 'Major $version',
                      },
                    ],
            }),
            200,
          );
        }),
      );
      expect(await api.request('scales', {}), isNull);
      await Future<void>.delayed(Duration.zero);
      expect((await api.request('scales', {}) as List).single['en'], 'Major 1');
      expect(calls, 1);
      version = 2;
      expect(
        (await api.request('scales', {'refresh': true}) as List).single['en'],
        'Major 2',
      );
      invalid = true;
      expect(
        (await api.request('scales', {'refresh': true}) as List).single['en'],
        'Major 2',
      );
      online = false;
      expect(
        (await api.request('scales', {'refresh': true}) as List).single['en'],
        'Major 2',
      );
      api.close();
      final offline = NotationApi(
        '',
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      expect(
        (await offline.request('scales', {}) as List).single['en'],
        'Major 2',
      );
      await Future<void>.delayed(Duration.zero);
      offline.close();
    },
  );
  test(
    'concurrent catalog refreshes share one request and support empty catalogs',
    () async {
      SharedPreferences.setMockInitialValues({
        'notation_scales_v1': jsonEncode([
          {'id': 'major', 'fa': 'Major', 'en': 'Major'},
        ]),
      });
      var calls = 0;
      final api = NotationApi(
        '',
        client: MockClient((_) async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return http.Response('{"success":true,"data":[]}', 200);
        }),
      );
      final results = await Future.wait(
        List.generate(5, (_) => api.request('scales', {'refresh': true})),
      );
      expect(calls, 1);
      expect(results.every((value) => (value as List).isEmpty), isTrue);
      expect(await api.request('scales', {}), isEmpty);
      api.close();
    },
  );
}
