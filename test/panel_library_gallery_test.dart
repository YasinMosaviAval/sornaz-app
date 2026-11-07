import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/components/charts/app_sample_chart.dart';
import 'package:sornaz/components/charts/app_line_chart.dart';
import 'package:sornaz/screens/Authentication/models/auth_user.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_chart_gallery.dart';
import 'package:sornaz/screens/Site/panel_guides.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'panel_parity_completion_test.dart' show ExportPicker;
import 'social_widget_test.dart' as fixture;

final samples = object(
  jsonDecode(File('assets/panel/chart-gallery.json').readAsStringSync()),
);
final guideSection = <String, dynamic>{
  'key': 'guides',
  'documentLibrary': {'section': 'guide-documents'},
  'actions': {
    'update': {
      'fields': [
        for (final language in ['fa', 'en'])
          {
            'key': language,
            'label': language,
            'type': 'object',
            'options': [
              {'key': 'title', 'label': 'Title'},
              {'key': 'content', 'label': 'Content', 'type': 'multiline'},
            ],
          },
      ],
    },
  },
};

class GuideApi extends PanelApi {
  GuideApi() : super('test');
  final reads = <(String, Map<String, String>)>[];
  final writes = <(String, String, Json)>[];
  bool conflict = false;
  String version = 'a' * 64;
  @override
  Future<Json> get(String path, [Map<String, String>? params]) async {
    reads.add((path, {...?params}));
    return switch (path) {
      '/guides/list' => {
        'items': [
          {
            'key': 'registration',
            'title': 'Registration',
            'content': 'Registration body',
            'html': '<p>Registration body</p>',
            'fa': {'title': 'ثبت نام', 'content': 'راهنما'},
            'en': {'title': 'Registration', 'content': 'Guide'},
          },
        ],
      },
      '/guide-documents/list' => {
        'documents': [
          {'path': 'docs/sample.md', 'title': 'Sample guide'},
          {'path': 'Modules/Test/README.md', 'title': 'Module guide'},
        ],
      },
      '/guide-documents/read' => {
        'path': params?['path'],
        'title': 'Sample guide',
        'version': version,
        'content': '# Initial\n\nBody',
        'html': '<h1>Initial</h1><p>Body</p>',
      },
      _ => {},
    };
  }

  @override
  Future<Json> act(
    String section,
    String action, {
    Json values = const {},
    Map<String, String> params = const {},
    Map<String, PlatformFile> files = const {},
  }) async {
    writes.add((section, action, values));
    if (conflict) {
      throw const SocialException('File changed; reload first.', 409);
    }
    version = 'b' * 64;
    return {
      ...values,
      'version': version,
      'title': 'Changed',
      'html': '<h1>Changed</h1>',
    };
  }
}

class GuideSession extends AuthSession {
  GuideSession() {
    token = 'test';
    user = AuthUser(id: 1, username: 'admin', fullName: 'Admin');
  }
  void switchAccount() {
    token = 'other';
    user = AuthUser(id: 7, username: 'user', fullName: 'User');
    notifyListeners();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('packaged gallery asset contains all website samples', () async {
    final bundled =
        jsonDecode(
              await rootBundle.loadString('assets/panel/chart-gallery.json'),
            )
            as Map;
    expect((bundled['types'] as List).length, 19);
    expect(bundled['sourceSha256'], samples['sourceSha256']);
  });
  for (final dark in [false, true]) {
    testWidgets(
      'all nineteen sample charts and both variants render and expose touch values, dark=$dark',
      (tester) async {
        for (final type in objects(samples['types'])) {
          for (final variant in ['basic', 'advanced']) {
            await tester.pumpWidget(
              fixture.host(
                Theme(
                  data: dark ? ThemeData.dark() : ThemeData.light(),
                  child: Scaffold(
                    body: SingleChildScrollView(
                      child: AppSampleChart(
                        key: ValueKey('${type['id']}-$variant-$dark'),
                        type: '${type['id']}',
                        option: optionalObject(type[variant]),
                        translate: (s) => s,
                      ),
                    ),
                  ),
                ),
                dark: dark,
              ),
            );
            await tester.pumpAndSettle();
            if (type['id'] == 'line' && variant == 'basic') {
              final chart = tester.widget<AppLineChart>(
                find.byType(AppLineChart),
              );
              expect(chart.points.map((p) => p.value), [
                12,
                18,
                15,
                24,
                31,
                28,
              ]);
              continue;
            }
            final target = find.byKey(ValueKey('sample-chart-${type['id']}'));
            final painter =
                tester.widget<CustomPaint>(target).painter!
                    as SampleChartPainter;
            expect(
              painter.hits,
              isNotEmpty,
              reason: '${type['id']} $variant must draw interactive data',
            );
            final point = painter.hits.first.bounds.center;
            final expected = painter.at(point)!.label;
            await tester.tapAt(tester.getTopLeft(target) + point);
            await tester.pump();
            expect(
              find.text(expected),
              findsWidgets,
              reason: '${type['id']} touch value',
            );
            expect(tester.takeException(), isNull);
          }
        }
      },
    );
  }
  testWidgets('gallery filters, selects variants and exports a PNG', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final picker = ExportPicker();
    FilePicker? previous;
    try {
      previous = FilePicker.platform;
    } catch (_) {}
    FilePicker.platform = picker;
    addTearDown(() {
      if (previous != null) FilePicker.platform = previous;
    });
    await tester.pumpWidget(
      fixture.host(PanelChartGalleryPage(catalog: samples)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('۱۹'), findsWidgets);
    await tester.enterText(find.byKey(const ValueKey('chart-search')), 'خطی');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gallery-line')), findsOneWidget);
    expect(find.byKey(const ValueKey('gallery-bar')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('chart-variant-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('پایه').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('line-basic')), findsOneWidget);
    expect(find.byKey(const ValueKey('line-advanced')), findsNothing);
    final export = find.byTooltip('ذخیره نمودار PNG');
    await tester.ensureVisible(export);
    await tester.tap(export);
    await tester.pump();
    await tester.runAsync(() async {
      for (var i = 0; i < 60 && picker.bytes == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pumpAndSettle();
    expect(picker.name, 'line-basic.png');
    expect(picker.bytes?.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'guide library loads metadata only, searches paths and preserves editing text on conflict',
    (tester) async {
      final api = GuideApi();
      await tester.pumpWidget(
        fixture.host(PanelGuidesPage(api: api, section: guideSection)),
      );
      await tester.pumpAndSettle();
      expect(api.reads.map((c) => c.$1), [
        '/guides/list',
        '/guide-documents/list',
      ]);
      await tester.enterText(
        find.byKey(const ValueKey('guide-library-search')),
        'sample',
      );
      await tester.pumpAndSettle();
      expect(find.text('Module guide'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('guide-docs/sample.md')));
      await tester.pumpAndSettle();
      expect(api.reads.last.$1, '/guide-documents/read');
      expect(api.reads.last.$2, {'path': 'docs/sample.md'});
      await tester.tap(find.byTooltip('ویرایش'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        '# My unsaved change',
      );
      api.conflict = true;
      await tester.tap(find.byTooltip('ذخیره'));
      await tester.pumpAndSettle();
      expect(find.text('# My unsaved change'), findsOneWidget);
      expect(find.textContaining('File changed'), findsWidgets);
      expect(api.writes.last.$3['version'], 'a' * 64);
      api.conflict = false;
      await tester.tap(find.byTooltip('ذخیره'));
      await tester.pumpAndSettle();
      expect(api.writes.last.$3['path'], 'docs/sample.md');
      expect(api.writes.last.$3['content'], '# My unsaved change');
      expect(find.text('Changed'), findsWidgets);
      await tester.tap(find.byTooltip('حذف'));
      await tester.pumpAndSettle();
      expect(api.writes.last.$2, 'update');
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(api.writes.last.$2, 'update');
      await tester.pumpWidget(const SizedBox.shrink());
      api.dispose();
    },
  );
  testWidgets(
    'switching account hides a document editor and its private text',
    (tester) async {
      final api = GuideApi(), session = GuideSession();
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthSession>.value(
          value: session,
          child: fixture.host(
            PanelGuideDocumentPage(
              api: api,
              document: const {'path': 'docs/sample.md'},
              documents: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('ویرایش'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Private unsaved text',
      );
      session.switchAccount();
      await tester.pumpAndSettle();
      expect(find.text('Private unsaved text'), findsNothing);
      expect(find.text('دسترسی لازم را ندارید.'), findsOneWidget);
      expect(api.writes, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
      api.dispose();
    },
  );
  testWidgets(
    'older API still shows and edits translated guides without library calls',
    (tester) async {
      final api = GuideApi(),
          section = {...guideSection}..remove('documentLibrary');
      await tester.pumpWidget(
        fixture.host(PanelGuidesPage(api: api, section: section)),
      );
      await tester.pumpAndSettle();
      expect(api.reads.map((c) => c.$1), ['/guides/list']);
      await tester.tap(find.byTooltip('ویرایش راهنما'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('ذخیره تغییرات'));
      await tester.tap(find.text('ذخیره تغییرات'));
      await tester.pumpAndSettle();
      expect(api.writes.single.$3['key'], 'registration');
      await tester.pumpWidget(const SizedBox.shrink());
      api.dispose();
    },
  );
  test('guide document reads bypass memory and offline caches', () async {
    var calls = 0;
    final api = PanelApi(
      'test',
      client: MockClient((request) async {
        calls++;
        return http.Response(
          jsonEncode({
            'data': {'content': 'private'},
          }),
          200,
        );
      }),
    );
    await api.get('/guide-documents/read', {'path': 'docs/sample.md'});
    await api.get('/guide-documents/read', {'path': 'docs/sample.md'});
    expect(calls, 2);
    expect(await api.saved('/guide-documents/read'), isNull);
    api.dispose();
  });
}
