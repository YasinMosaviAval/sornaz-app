import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_session_files.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

class SessionFixture extends PanelApi {
  SessionFixture({this.uploadAllowed = false}) : super('fixture');
  final bool uploadAllowed;
  bool deny = false;
  final downloads = <String>[];
  @override
  Future<Json> sensitiveGet(String path, [Map<String, String>? query]) async {
    expect(path, '/schedules/session-files');
    expect(query, {'id': '91'});
    if (deny) throw const SocialException('Denied', 403);
    return {
      'canUpload': uploadAllowed,
      'canDownload': true,
      'maxBytes': 1024,
      'files': [
        {
          'id': 4,
          'name': 'تمرین جلسه.pdf',
          'size': 64,
          'mime': 'application/pdf',
          'canDelete': uploadAllowed,
        },
      ],
    };
  }

  @override
  Future<void> downloadSessionFile(
    String sessionId,
    String fileId,
    String filename, {
    required String mime,
  }) async {
    if (deny) throw const SocialException('Denied', 403);
    downloads.add('$sessionId/$fileId');
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'session download rejects redirects, inline content and JSON denials',
    () async {
      for (final response in [
        http.Response(
          'redirect',
          302,
          headers: {'location': 'https://example.test/public'},
        ),
        http.Response(
          'inline PDF',
          200,
          headers: {'content-type': 'application/pdf'},
        ),
        http.Response(
          '{"status":403,"data":{"success":false}}',
          200,
          headers: {'content-type': 'application/json'},
        ),
      ]) {
        final api = PanelApi(
          'fixture',
          client: MockClient((request) async {
            expect(request.followRedirects, false);
            expect(
              request.url.path,
              endsWith('/schedules/session-file-download'),
            );
            expect(request.url.queryParameters, {'id': '91', 'file': '4'});
            expect(request.headers['Authorization'], 'Bearer fixture');
            return response;
          }),
        );
        await expectLater(
          api.downloadSessionFile(
            '91',
            '4',
            'lesson.pdf',
            mime: 'application/pdf',
          ),
          throwsA(isA<SocialException>()),
        );
        api.dispose();
      }
    },
  );
  test('session file lists bypass cache and reject account changes', () async {
    var reads = 0, current = true;
    final api = PanelApi(
      'fixture-token',
      isCurrentAccount: () => current,
      client: MockClient((request) async {
        reads++;
        expect(request.headers['Authorization'], 'Bearer fixture-token');
        expect(request.headers['Cache-Control'], 'no-store');
        expect(request.followRedirects, false);
        return http.Response(
          jsonEncode({
            'status': 200,
            'data': {
              'success': true,
              'data': {'files': [], 'read': reads},
            },
          }),
          200,
        );
      }),
    );
    expect(
      (await api.get('/schedules/session-files', {'id': '91'}))['read'],
      1,
    );
    expect(
      (await api.get('/schedules/session-files', {'id': '91'}))['read'],
      2,
    );
    expect(await api.saved('/schedules/session-files'), isNull);
    current = false;
    await expectLater(
      api.get('/schedules/session-files'),
      throwsA(isA<SocialException>()),
    );
    expect(reads, 2);
    api.dispose();
  });
  for (final width in [320.0, 430.0]) {
    testWidgets('student session files and denial at $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = SessionFixture();
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: PanelSessionFiles(api: api, sessionId: '91'),
          ),
          dark: width == 430,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('تمرین جلسه.pdf'), findsOneWidget);
      expect(find.byKey(const ValueKey('session-file-upload')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('session-file-download-4')));
      await tester.pumpAndSettle();
      expect(api.downloads, ['91/4']);
      api.deny = true;
      await tester.tap(find.byKey(const ValueKey('session-file-download-4')));
      await tester.pumpAndSettle();
      expect(find.text('تمرین جلسه.pdf'), findsNothing);
      expect(
        find.byKey(const ValueKey('session-file-download-4')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      api.dispose();
    });
  }
  testWidgets('server permission enables upload and deletion', (tester) async {
    final api = SessionFixture(uploadAllowed: true);
    await tester.pumpWidget(
      fixture.host(
        Scaffold(
          body: PanelSessionFiles(api: api, sessionId: '91'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('session-file-upload')), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    api.dispose();
  });
}
