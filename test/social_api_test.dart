import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sornaz/screens/Social/social_api.dart';

http.Response jsonResponse(String body, int status) =>
    http.Response.bytes(utf8.encode(body), status);
void main() {
  test('decodes the real PHP envelope and authenticates requests', () async {
    final api = SocialApi(
      'test-token',
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-token');
        expect(request.url.path, '/api/sornaz/v1/social/me');
        return jsonResponse(
          jsonEncode({
            'status': 200,
            'data': {
              'success': true,
              'data': {'id': 8, 'name': 'گیتار'},
            },
          }),
          200,
        );
      }),
    );
    expect((await api.get('/me'))['name'], 'گیتار');
    api.dispose();
  });
  test(
    'surfaces expired-session errors without exposing envelope data',
    () async {
      final api = SocialApi(
        'expired',
        client: MockClient(
          (_) async => jsonResponse(
            jsonEncode({
              'status': 401,
              'data': {'success': false, 'message': 'نشست معتبر نیست'},
            }),
            401,
          ),
        ),
      );
      await expectLater(
        api.get('/me'),
        throwsA(isA<SocialException>().having((e) => e.status, 'status', 401)),
      );
      api.dispose();
    },
  );
  test('handles non-JSON gateway responses', () async {
    final api = SocialApi(
      'token',
      client: MockClient(
        (_) async => jsonResponse('<html>Bad gateway</html>', 502),
      ),
    );
    await expectLater(api.get('/posts'), throwsA(isA<SocialException>()));
    api.dispose();
  });
  test('does not send a bearer token to another media origin', () {
    final api = SocialApi('secret');
    expect(
      () => api.media('https://untrusted.example/video.mp4'),
      throwsA(isA<SocialException>()),
    );
    expect(
      api.media('/course-market/media/42'),
      endsWith('/social/course-media/42'),
    );
    api.dispose();
  });
  test(
    'follow sends the desired state instead of a retry-unsafe toggle',
    () async {
      final api = SocialApi(
        'token',
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.bodyFields['active'], '1');
          return jsonResponse(
            jsonEncode({
              'status': 200,
              'data': {
                'success': true,
                'data': {'isFollowing': true},
              },
            }),
            200,
          );
        }),
      );
      expect(
        (await api.post('/users/2/follow', {'active': '1'}))['isFollowing'],
        true,
      );
      api.dispose();
    },
  );
}
