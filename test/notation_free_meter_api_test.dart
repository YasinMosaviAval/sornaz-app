import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Notation/notation_api.dart';

Map<String, dynamic> freeScore() => {
  'metadata': {
    'title': 'Free phrase',
    'time': 'free',
    'instrument': 'Tar',
    'clef': 'treble',
    'key': 'C',
    'tempo_note': 'q',
    'bpm': 100,
  },
  'score': {
    'measures': [
      {
        'notes': [
          {
            'pitch': 'C4',
            'duration': 'q',
            'rest': false,
            'durationSeconds': 0.01,
            'at': 0,
          },
          {
            'pitch': 'D4',
            'duration': 'q',
            'rest': false,
            'durationSeconds': 5,
            'at': 241920,
          },
        ],
      },
    ],
  },
  'visibility': 'private',
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'free timing survives local save and reopening in the Dart adapter',
    () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return http.Response('{}', 500);
      });
      final api = NotationApi('', userId: 71, client: client);
      final score = freeScore();
      final saved =
          await api.request('save', {'sheetId': 0, 'payload': score}) as Map;
      final reopenedApi = NotationApi('', userId: 71, client: client);
      final reopened =
          await reopenedApi.request('get', {'sheetId': saved['id']}) as Map;
      expect(reopened['metadata']['time'], 'free');
      expect(reopened['score'], score['score']);
      expect(reopened['editable'], isTrue);
      expect(requests, 0, reason: 'Local save and read must stay offline.');

      final other = NotationApi('', userId: 72, client: client);
      await expectLater(
        other.request('get', {'sheetId': saved['id']}),
        throwsFormatException,
      );
      expect(requests, 0, reason: 'Another account cannot fetch a local ID.');
      api.close();
    },
  );

  test(
    'explicit upload sends seconds and positions without changing schema',
    () async {
      var writes = 0;
      Map<String, dynamic>? uploaded;
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer fixture-token');
        writes++;
        uploaded = jsonDecode(request.body) as Map<String, dynamic>;
        expect(uploaded!['notation_schema'], 3);
        expect(uploaded!['notation_section_meters'], isTrue);
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {...uploaded!, 'id': 91, 'version': 1},
          }),
          200,
        );
      });
      final api = NotationApi('fixture-token', userId: 71, client: client);
      final score = freeScore();
      final saved =
          await api.request('save', {'sheetId': 0, 'payload': score}) as Map;
      expect(writes, 0);
      final result =
          await api.request('upload', {'sheetId': saved['id']}) as Map;
      expect(writes, 1);
      expect(uploaded!['metadata']['time'], 'free');
      expect(uploaded!['score'], score['score']);
      expect(result['uploaded'], isTrue);
      expect(result['remote_id'], 91);
      final reopened =
          await api.request('get', {'sheetId': saved['id']}) as Map;
      expect(reopened['score'], score['score']);
      api.close();
    },
  );
  test('mixed subsection meters survive storage and explicit upload', () async {
    Map<String, dynamic>? uploaded;
    final api = NotationApi(
      'fixture-token',
      userId: 71,
      client: MockClient((request) async {
        uploaded = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {...uploaded!, 'id': 92, 'version': 1},
          }),
          200,
        );
      }),
    );
    final score = freeScore();
    final timedMeasures = score['score']['measures'];
    score['metadata']['time'] = '4/4';
    final metered = {
      'notes': [
        {'pitch': 'C4', 'duration': 'q', 'rest': false},
      ],
    };
    score['score'] = {
      'time': '4/4',
      'measures': [metered],
      'subsections': [
        {'time': 'free', 'measures': timedMeasures},
      ],
      'sections': [
        {
          'time': '3/4',
          'measures': [metered],
        },
      ],
    };
    final saved =
        await api.request('save', {'sheetId': 0, 'payload': score}) as Map;
    final reopened = await api.request('get', {'sheetId': saved['id']}) as Map;
    expect(reopened['score'], score['score']);
    expect(uploaded, isNull);
    await api.request('upload', {'sheetId': saved['id']});
    expect(uploaded!['notation_section_meters'], isTrue);
    expect(uploaded!['score'], score['score']);
    expect(uploaded!['metadata']['time'], '4/4');
    api.close();
  });
}
