import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Notation/notation_api.dart';

void main() {
  test(
    'instrument catalog opens immediately and refreshes its offline cache',
    () async {
      SharedPreferences.setMockInitialValues({});
      const items = [
        {'id': 42, 'fa': 'سنتور', 'en': 'Santur'},
        {'id': 43, 'fa': 'پیانو', 'en': 'Piano'},
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
      expect(await online.request('instruments', {}), isNotEmpty);
      await Future<void>.delayed(Duration.zero);
      online.close();
      final offline = NotationApi(
        '',
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      final catalog = await offline.request('instruments', {}) as List;
      expect(catalog.first, items.first);
      expect(catalog.last['staves'], [
        {'clef': 'treble'},
        {'clef': 'bass'},
      ]);
      offline.close();
    },
  );

  test('local piano score preserves both staves and chord tones', () async {
    SharedPreferences.setMockInitialValues({});
    final api = NotationApi('', userId: 7);
    final score = <String, dynamic>{
      'metadata': {
        'instrument': 'piano',
        'staves': [
          {'clef': 'treble'},
          {'clef': 'bass'},
        ],
        'time': '4/4',
      },
      'score': {
        'measures': [
          {
            'notes': [
              {'pitch': 'C4', 'duration': 'q', 'staff': 1},
              {
                'pitch': 'C3',
                'duration': 'q',
                'staff': 2,
                'pitches': [
                  {'pitch': 'E3', 'accidental': ''},
                ],
              },
            ],
          },
        ],
      },
    };
    final saved =
        await api.request('save', {'sheetId': 0, 'payload': score}) as Map;
    final reopened = await api.request('get', {'sheetId': saved['id']}) as Map;
    expect(reopened['metadata']['staves'], score['metadata']!['staves']);
    expect(reopened['score'], score['score']);
    api.close();
  });
}
