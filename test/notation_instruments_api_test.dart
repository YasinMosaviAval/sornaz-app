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

  test(
    'sheet search filters local scores and forwards query to server',
    () async {
      SharedPreferences.setMockInitialValues({});
      final api = NotationApi(
        '',
        userId: 7,
        client: MockClient((request) async {
          expect(request.url.queryParameters['q'], 'Sonata');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'items': [], 'has_more': false},
            }),
            200,
          );
        }),
      );
      final ids = <String, int>{};
      for (final title in ['Sonata', 'Prelude']) {
        final saved =
            await api.request('save', {
                  'sheetId': 0,
                  'payload': {
                    'metadata': {'title': title},
                    'score': {'measures': []},
                  },
                })
                as Map;
        ids[title] = saved['id'] as int;
      }
      final result =
          await api.request('list', {
                'mode': 'all',
                'page': 1,
                'query': 'Sonata',
              })
              as Map;
      expect((result['items'] as List).map((item) => item['title']), [
        'Sonata',
      ]);
      await api.request('create-list', {'name': 'Practice'});
      await api.request('add-to-list', {
        'name': 'Practice',
        'sheetIds': ids.values.toList(),
      });
      final matchingList =
          await api.request('list', {
                'mode': 'lists',
                'page': 1,
                'query': 'Sonata',
              })
              as Map;
      expect((matchingList['items'] as List).length, 1);
      expect((matchingList['items'][0]['items'] as List).length, 1);
      api.close();
    },
  );

  test(
    'damaged primary score storage restores its last valid backup',
    () async {
      SharedPreferences.setMockInitialValues({});
      final api = NotationApi('', userId: 71);
      final first =
          await api.request('save', {
                'sheetId': 0,
                'payload': {
                  'metadata': {'title': 'First'},
                  'score': {'measures': []},
                },
              })
              as Map;
      await api.request('save', {
        'sheetId': first['id'],
        'payload': {
          'metadata': {'title': 'Second'},
          'score': {'measures': []},
        },
      });
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('notation_local_v3_backup_71'), isNotNull);
      await prefs.setString('notation_local_v3_71', '{broken');
      final recovered =
          await api.request('get', {'sheetId': first['id']}) as Map;
      expect(recovered['metadata']['title'], 'First');
      expect(prefs.getString('notation_local_v3_71'), '{broken');
      await api.request('save', {
        'sheetId': first['id'],
        'payload': {
          'metadata': {'title': 'Recovered'},
          'score': {'measures': []},
        },
      });
      expect(
        (await api.request('get', {
          'sheetId': first['id'],
        }))['metadata']['title'],
        'Recovered',
      );
      api.close();
    },
  );

  test('damaged score storage without backup reports an error', () async {
    SharedPreferences.setMockInitialValues({'notation_local_v3_72': '{broken'});
    final api = NotationApi('', userId: 72);
    await expectLater(
      api.request('list', {'mode': 'mine', 'page': 1}),
      throwsA(isA<FormatException>()),
    );
    api.close();
  });
}
