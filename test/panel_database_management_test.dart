import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_database.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

class DatabaseSavePicker extends FilePicker {
  DatabaseSavePicker(this.target);
  final String target;
  int calls = 0;
  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    expect(bytes, isNull);
    expect(fileName, 'database.sql');
    calls++;
    return target;
  }
}

class DatabaseFixture extends PanelApi {
  DatabaseFixture() : super('founder');
  final downloads = <String>[];
  bool denyDownload = false;
  @override
  Future<Json> sensitiveGet(String path, [Map<String, String>? query]) async =>
      path.endsWith('/rows')
      ? {
          'table': query?['table'],
          'columns': [
            {'name': 'text', 'type': 'TEXT'},
            {'name': 'binary', 'type': 'BLOB'},
          ],
          'rows': [
            {
              'text': '<script>literal</script>',
              'binary': {
                'type': 'binary',
                'encoding': 'base64',
                'value': 'AAEC',
              },
            },
          ],
          'total': 1,
          'page': 1,
          'perPage': 10,
        }
      : {
          'tables': [
            {'name': 'f_example', 'type': 'BASE TABLE', 'estimatedRows': 1},
          ],
          'total': 11,
          'page': int.tryParse(query?['page'] ?? '1'),
          'perPage': 10,
        };
  @override
  Future<void> downloadDatabase(
    String action,
    Map<String, String> params,
    String filename,
  ) async {
    if (denyDownload) throw const SocialException('Denied', 403);
    downloads.add('$action:${params['table'] ?? ''}');
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'database reads bypass memory caching and cannot survive an account switch',
    () async {
      var requests = 0, current = true;
      final api = PanelApi(
        'private-token',
        isCurrentAccount: () => current,
        client: MockClient((request) async {
          requests++;
          expect(request.headers['Authorization'], 'Bearer private-token');
          expect(request.headers['Cache-Control'], 'no-store');
          expect(request.url.query, isNot(contains('private-token')));
          expect(request.followRedirects, false);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'rows': [
                  {'secret': 'fixture-$requests'},
                ],
              },
            }),
            200,
          );
        }),
      );
      expect(
        (await api.get('/database-management/rows'))['rows'][0]['secret'],
        'fixture-1',
      );
      expect(
        (await api.get('/database-management/rows'))['rows'][0]['secret'],
        'fixture-2',
      );
      expect(await api.saved('/database-management/rows'), isNull);
      current = false;
      await expectLater(
        api.get('/database-management/rows'),
        throwsA(isA<SocialException>()),
      );
      expect(requests, 2);
      api.dispose();
    },
  );
  test(
    'SQL errors and redirects are rejected before any file is created',
    () async {
      for (final status in [200, 302, 403]) {
        final api = PanelApi(
          'founder',
          client: MockClient(
            (request) async => http.Response(
              '{"success":false}',
              status,
              headers: {'content-type': 'application/json'},
            ),
          ),
        );
        await expectLater(
          api.downloadDatabase('download-data', {}, 'database.sql'),
          throwsA(isA<SocialException>()),
        );
        api.dispose();
      }
      final api = PanelApi(
        'founder',
        client: MockClient(
          (request) async => http.Response(
            '{"status":403,"data":{"success":false}}',
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      await expectLater(
        api.downloadDatabase('download-data', {}, 'database.sql'),
        throwsA(
          isA<SocialException>().having((error) => error.status, 'status', 403),
        ),
      );
      await expectLater(
        api.sensitiveGet('/database-management/rows'),
        throwsA(
          isA<SocialException>().having((error) => error.status, 'status', 403),
        ),
      );
      api.dispose();
    },
  );
  for (final changeAccount in [false, true]) {
    test(
      'SQL stream cleans private files after account change: $changeAccount',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'sornaz-sql-test-',
        );
        const channel = MethodChannel('plugins.flutter.io/path_provider');
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(
          channel,
          (_) async => directory.path,
        );
        FilePicker? previous;
        try {
          previous = FilePicker.platform;
        } catch (_) {}
        final picker = DatabaseSavePicker('${directory.path}/selected.sql');
        FilePicker.platform = picker;
        var current = true, canceled = false;
        Stream<List<int>> sql() async* {
          try {
            yield utf8.encode('CREATE TABLE fixture (id INT);\n');
            if (changeAccount) current = false;
            yield utf8.encode('INSERT INTO fixture VALUES (1);\n');
          } finally {
            canceled = true;
          }
        }

        final api = PanelApi(
          'founder',
          isCurrentAccount: () => current,
          client: MockClient.streaming((request, _) async {
            expect(request.headers['Authorization'], 'Bearer founder');
            expect(request.followRedirects, false);
            return http.StreamedResponse(
              sql(),
              200,
              headers: {'content-type': 'application/sql'},
            );
          }),
        );
        try {
          final download = api.downloadDatabase(
            'download-data',
            {},
            'database.sql',
          );
          if (changeAccount) {
            await expectLater(download, throwsA(isA<SocialException>()));
            expect(await directory.list().isEmpty, true);
            expect(picker.calls, 0);
          } else {
            await download;
            expect(picker.calls, 1);
            expect(
              await File(picker.target).readAsString(),
              'CREATE TABLE fixture (id INT);\nINSERT INTO fixture VALUES (1);\n',
            );
            expect(await directory.list().length, 1);
          }
          expect(canceled, true);
        } finally {
          api.dispose();
          messenger.setMockMethodCallHandler(channel, null);
          if (previous != null) FilePicker.platform = previous;
          await directory.delete(recursive: true);
        }
      },
    );
  }
  testWidgets(
    'database tables, rows, full values and scoped SQL downloads use their dedicated actions',
    (tester) async {
      final api = DatabaseFixture();
      addTearDown(api.dispose);
      await tester.pumpWidget(fixture.host(PanelDatabasePage(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('f_example'), findsOneWidget);
      expect(find.byTooltip('آخر'), findsOneWidget);
      await tester.tap(find.byTooltip('دانلود ساختار جدول‌ها').first);
      await tester.pumpAndSettle();
      expect(api.downloads, ['download-schema:']);
      await tester.tap(find.byTooltip('مشاهده سطرها'));
      await tester.pumpAndSettle();
      expect(find.text('<script>literal</script>'), findsOneWidget);
      expect(find.text('base64: AAEC'), findsOneWidget);
      expect(find.byTooltip('آخر'), findsNothing);
      await tester.tap(find.byTooltip('دانلود ساختار و اطلاعات جدول‌ها'));
      await tester.pumpAndSettle();
      expect(api.downloads.last, 'table-data:f_example');
      await tester.tap(find.text('<script>literal</script>'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsOneWidget);
      Navigator.of(tester.element(find.byType(SelectableText))).pop();
      await tester.pumpAndSettle();
      api.denyDownload = true;
      await tester.tap(find.byTooltip('دانلود ساختار و اطلاعات جدول‌ها'));
      await tester.pumpAndSettle();
      expect(find.text('f_example'), findsNothing);
      expect(find.text('<script>literal</script>'), findsNothing);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.download_outlined),
            )
            .onPressed,
        isNull,
      );
      api.denyDownload = false;
      await tester.tap(find.text('تلاش دوباره'));
      await tester.pumpAndSettle();
      expect(find.text('f_example'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
