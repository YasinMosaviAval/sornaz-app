import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_form.dart';
import 'package:sornaz/screens/Site/panel_presentation.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as localized;

http.Response reply(Object value, [int status = 200]) => http.Response.bytes(
  utf8.encode(
    jsonEncode({
      'status': status,
      'data': {'success': status == 200, 'data': value},
    }),
  ),
  status,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SocialApi.locale = 'fa';
  });

  test(
    'bearer stays in headers; changed account cannot send any request',
    () async {
      var current = true;
      var sent = 0;
      final api = PanelApi(
        'token',
        isCurrentAccount: () => current,
        client: MockClient((request) async {
          sent++;
          expect(request.headers['Authorization'], 'Bearer token');
          expect(request.url.query, isNot(contains('token')));
          expect(request.followRedirects, false);
          return reply({'items': []});
        }),
      );
      await api.get('/courses/list');
      current = false;
      await expectLater(
        api.get('/courses/list'),
        throwsA(isA<SocialException>()),
      );
      await expectLater(
        api.act('courses', 'create'),
        throwsA(isA<SocialException>()),
      );
      expect(sent, 1);
      api.dispose();
    },
  );

  test('native payload preserves unicode and nested arrays', () async {
    final values = {
      'name': 'پیانو',
      'sessions': [
        {'date': '2026-09-12', 'startTime': '12:30'},
      ],
    };
    final api = PanelApi(
      'token',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        final encoded = request.body
            .split('name="payload_b64"')
            .last
            .trim()
            .split(RegExp(r'\s'))
            .first;
        expect(jsonDecode(utf8.decode(base64Decode(encoded))), values);
        return reply({'id': 4});
      }),
    );
    expect((await api.act('terms', 'create', values: values))['id'], 4);
    api.dispose();
  });

  test('failed responses do not expose server internals', () {
    expect(
      () => PanelApi.decode(http.Response('SQLSTATE /private/api', 500)),
      throwsA(
        isA<SocialException>().having(
          (e) => e.toString(),
          'message',
          isNot(contains('SQLSTATE')),
        ),
      ),
    );
    expect(panelTitle({'course_title': 'پیانو'}), 'پیانو');
  });

  testWidgets(
    'editing roles preserves saved selections and sends selected ids',
    (tester) async {
      PanelFormResult? saved;
      await tester.pumpWidget(
        localized.host(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                child: const Text('open'),
                onPressed: () async {
                  saved = await Navigator.of(context).push<PanelFormResult>(
                    MaterialPageRoute(
                      builder: (_) => const PanelFormPage(
                        title: 'ویرایش دسترسی',
                        fields: [
                          {
                            'key': 'roleIds',
                            'initial': 'roles',
                            'type': 'multi',
                            'label': 'نقش‌ها',
                            'options': {'source': 'roles'},
                          },
                        ],
                        initial: {
                          'roles': [
                            {'id': 1},
                          ],
                        },
                        data: {
                          'roles': [
                            {'id': 1, 'title': 'مدرس'},
                            {'id': 2, 'title': 'مدیر'},
                          ],
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile).first)
            .value,
        true,
      );
      await tester.tap(find.text('مدیر'));
      await tester.tap(find.byIcon(Icons.save_outlined));
      await tester.pumpAndSettle();
      expect(saved!.values['roleIds'], [1, 2]);
      expect(tester.takeException(), null);
    },
  );

  testWidgets(
    'student list filters staff, loads hidden choices and paginates',
    (tester) async {
      final requests = <String>[];
      final api = PanelApi(
        'test',
        client: MockClient((request) async {
          requests.add(request.url.toString());
          if (request.url.path.endsWith('/options')) {
            return reply({'organizations': []});
          }
          final page = request.url.queryParameters['page'];
          return reply({
            'members': page == '2'
                ? [
                    {'id': 3, 'name': 'هنرجوی دوم', 'type': 'student'},
                  ]
                : [
                    {'id': 1, 'name': 'هنرجوی اول', 'type': 'student'},
                    {'id': 2, 'name': 'مدرس پنهان', 'type': 'teacher'},
                  ],
            'total': 51,
            'perPage': 50,
          });
        }),
      );
      await tester.pumpWidget(
        localized.host(
          PanelResourcePage(
            api: api,
            section: const {
              'key': 'students',
              'label': 'هنرجویان',
              'rows': 'members',
              'where': {'type': 'student'},
              'optionActions': ['options'],
              'actions': {
                'list': {'method': 'GET', 'row': false},
                'options': {
                  'method': 'GET',
                  'row': false,
                  'hidden': true,
                  'label': 'گزینه‌های داخلی',
                },
              },
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('هنرجوی اول'), findsOneWidget);
      expect(find.text('مدرس پنهان'), findsNothing);
      expect(find.text('گزینه‌های داخلی'), findsNothing);
      expect(requests.any((v) => v.contains('/students/options')), true);
      await tester.tap(find.text('بعدی'));
      await tester.pumpAndSettle();
      expect(find.text('هنرجوی دوم'), findsOneWidget);
      expect(requests.any((v) => v.contains('page=2')), true);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  testWidgets('page content keeps its page slug and opens a native edit form', (
    tester,
  ) async {
    final api = PanelApi(
      'test',
      client: MockClient((request) async {
        expect(request.url.queryParameters['page'], 'home');
        return reply({
          'items': [
            {
              'key': 'site.page.home.text.welcome',
              'kind': 'text',
              'value': 'خوش آمدید',
              'fa': 'خوش آمدید',
              'en': 'Welcome',
            },
          ],
        });
      }),
    );
    await tester.pumpWidget(
      localized.host(
        PanelResourcePage(
          api: api,
          params: const {'page': 'home'},
          section: const {
            'key': 'page-content',
            'label': 'محتوا',
            'rows': 'items',
            'actions': {
              'list': {'method': 'GET', 'row': false},
              'update': {
                'method': 'POST',
                'row': true,
                'label': 'ویرایش محتوا',
                'fields': [
                  {'key': 'fa', 'label': 'فارسی', 'type': 'multiline'},
                ],
              },
            },
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ویرایش محتوا').last);
    await tester.pumpAndSettle();
    expect(find.byType(PanelFormPage), findsOneWidget);
    expect(find.text('خوش آمدید'), findsWidgets);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    api.dispose();
  });

  testWidgets(
    'conversation fetches additional batches only on demand and exposes owner actions',
    (tester) async {
      var calls = 0;
      final api = PanelApi(
        'test',
        client: MockClient((request) async {
          calls++;
          final after = request.url.queryParameters['after'];
          return reply({
            'messages': after == '0'
                ? List.generate(
                    200,
                    (i) => {
                      'id': i + 1,
                      'sender': 'کاربر',
                      'body': 'پیام ${i + 1}',
                      'mine': true,
                    },
                  )
                : [
                    {
                      'id': 201,
                      'sender': 'کاربر',
                      'body': 'آخرین پیام',
                      'mine': true,
                    },
                  ],
          });
        }),
      );
      await tester.pumpWidget(
        localized.host(
          PanelConversationPage(
            api: api,
            conversation: const {'id': 7, 'title': 'گفتگو'},
            section: const {
              'actions': {
                'edit-message': {'label': 'ویرایش پیام'},
                'delete-message': {'label': 'حذف پیام'},
                'forward': {'label': 'ارسال'},
              },
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 1);
      await tester.tap(find.byKey(const ValueKey('panel-more-messages')));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('آخرین پیام'), findsOneWidget);
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      expect(find.byTooltip('ویرایش پیام'), findsWidgets);
      expect(find.text('پاک کردن پیام'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  test('PDF export creates an A4 document with long Persian records', () async {
    final bytes = await panelPdf(
      'گزارش هنرجویان',
      [
        {
          'name': 'هنرجوی پیانو',
          'description': List.filled(300, 'آموزش موسیقی').join(' '),
        },
        {'name': 'هنرجوی ویولن', 'phone': '09123456789'},
      ],
      rtl: true,
      labels: const {'name': 'نام', 'description': 'توضیحات', 'phone': 'تماس'},
    );
    final content = latin1.decode(bytes);
    expect(content.startsWith('%PDF-'), true);
    expect(
      content.contains('/Type /Pages') || content.contains('/Type/Pages'),
      true,
    );
    expect(bytes.length, greaterThan(1000));
  });

  test(
    'CSV preserves Unicode and quotes while neutralizing spreadsheet formulas',
    () {
      final csv = panelCsv([
        {'name': '=1+1', 'title': 'پیانو, "آغاز"', 'password': 'secret'},
      ]);
      expect(csv, contains('"\'=1+1"'));
      expect(csv, contains('پیانو, ""آغاز""'));
      expect(csv, isNot(contains('secret')));
    },
  );

  testWidgets(
    'group details honor permissions and remove the selected member',
    (tester) async {
      final mutations = <Uri>[];
      final api = PanelApi(
        'test',
        client: MockClient((request) async {
          if (request.method == 'POST') {
            mutations.add(request.url);
            return reply({});
          }
          return reply({
            'id': 7,
            'title': 'کلاس پیانو',
            'type': 'group',
            'canManage': true,
            'canDelete': true,
            'members': [
              {'id': 1, 'name': 'مدیر گروه', 'isMe': true},
              {'id': 2, 'name': 'عضو دوم', 'isMe': false},
            ],
          });
        }),
      );
      await tester.pumpWidget(
        localized.host(
          PanelGroupDetails(
            api: api,
            id: '7',
            section: const {
              'actions': {
                'remove-member': {
                  'label': 'حذف عضو',
                  'method': 'POST',
                  'fields': [],
                },
              },
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.person_remove_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.person_remove_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('بلی'));
      await tester.pumpAndSettle();
      expect(mutations.single.path, endsWith('/chat/remove-member'));
      expect(mutations.single.queryParameters, {'id': '7', 'userId': '2'});
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );

  test(
    'late responses are discarded after the active account changes',
    () async {
      final pending = Completer<http.Response>();
      var current = true;
      final api = PanelApi(
        'old',
        isCurrentAccount: () => current,
        client: MockClient((_) => pending.future),
      );
      final result = api.get('/account/list');
      final assertion = expectLater(
        result,
        throwsA(isA<SocialException>().having((e) => e.status, 'status', 401)),
      );
      current = false;
      pending.complete(
        reply({
          'profile': {'name': 'old account'},
        }),
      );
      await assertion;
      api.dispose();
    },
  );
}
