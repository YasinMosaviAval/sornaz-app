import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_finance.dart';
import 'package:sornaz/screens/Site/panel_navigation.dart';
import 'package:sornaz/screens/Site/panel_organization_filter.dart';
import 'package:sornaz/screens/Site/panel_page_guidance.dart';
import 'package:sornaz/screens/Site/panel_presentation.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

class FinanceApi extends PanelApi {
  FinanceApi({this.editor = false}) : super('test');
  final bool editor;
  Json? savedGuide;
  bool failSave = true;
  @override
  Future<Json> act(
    String section,
    String action, {
    Json values = const {},
    Map<String, String> params = const {},
    Map<String, PlatformFile> files = const {},
  }) async {
    if (failSave) throw const SocialException('Save failed');
    savedGuide = values;
    return {};
  }

  @override
  Future<Json> get(String path, [Map<String, String>? query]) async =>
      switch (path) {
        '' => {
          'sections': [
            {
              'key': 'page-guidance',
              'actions': {if (editor) 'save': {}},
            },
          ],
        },
        '/page-guidance/list' => {
          'finance': {
            'title': {'fa': 'راهنمای مالی', 'en': 'Finance guide'},
            'body': {'fa': 'متن ثبت‌شده در دیتابیس', 'en': 'Database guidance'},
          },
        },
        '/finance/list' => {'invoices': <Json>[]},
        '/finance/subscriptions' => {
          'plans': [
            {'months': 3, 'label': 'اشتراک سه ماهه', 'amount': 5000000},
          ],
          'periods': [
            {
              'id': 1,
              'amount': 0,
              'statusCode': 'free',
              'status': 'ماه اول رایگان',
              'canPay': false,
            },
            {
              'id': 2,
              'amount': 2000000,
              'statusCode': 'pending',
              'status': 'در انتظار پرداخت',
              'canPay': true,
            },
          ],
        },
        _ => {},
      };
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'guidance editor preserves bilingual values on failure and submits the website page key',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = FinanceApi(editor: true);
      addTearDown(api.dispose);
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: PanelPageGuidance(
              api: api,
              section: 'finance',
              canEdit: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ویرایش توضیحات صفحه'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(4));
      await tester.enterText(fields.at(0), 'توضیح جدید');
      await tester.enterText(fields.at(1), 'محتوای فارسی جدید');
      await tester.enterText(fields.at(2), 'New guide');
      await tester.enterText(fields.at(3), 'New English content');
      await tester.tap(find.text('ذخیره تغییرات'));
      await tester.pumpAndSettle();
      expect(fields, findsNWidgets(4));
      expect(
        tester.widget<TextFormField>(fields.first).controller!.text,
        'توضیح جدید',
      );
      api.failSave = false;
      await tester.tap(find.text('ذخیره تغییرات'));
      await tester.pumpAndSettle();
      expect(api.savedGuide, {
        'page': 'panel-finance',
        'fa': {'title': 'توضیح جدید', 'body': 'محتوای فارسی جدید'},
        'en': {'title': 'New guide', 'body': 'New English content'},
      });
      expect(fields, findsNothing);
    },
  );
  test('academy scope remains selectable without academy records', () {
    final options = panelOrganizationOptions(
      {
        'branches': [
          {'id': 8, 'name': 'Branch'},
        ],
      },
      [],
      fa: true,
    );
    expect(options.keys, ['academy', 'branch:8']);
    expect(panelMatchesOrganization({'branchId': null}, 'academy'), isTrue);
    expect(panelMatchesOrganization({'branchId': 8}, 'academy'), isFalse);
  });
  test('totals include paid subscription and only paid installments', () {
    final rows = [
      {
        'amount': 500,
        'installments': [
          {'amount': 100, 'statusCode': 'paid'},
          {'amount': 400, 'statusCode': 'pending'},
        ],
      },
      ...panelSubscriptionRows({
        'periods': [
          {'id': 1, 'amount': 200, 'statusCode': 'paid'},
        ],
      }),
    ];
    expect(panelFinanceTotals(rows), {
      'total': 700,
      'paid': 300,
      'remaining': 400,
    });
    expect(panelFinanceTotals([]), {'total': 0, 'paid': 0, 'remaining': 0});
  });
  test(
    'XLSX contains readable labels and escaped text rather than formulas',
    () {
      final archive = ZipDecoder().decodeBytes(
        panelExcelBytes([
          {'عنوان': '=SUM(A1) & <test>'},
        ]),
      );
      final sheet = utf8.decode(
        archive.findFile('xl/worksheets/sheet1.xml')!.content as List<int>,
      );
      expect(sheet, contains('عنوان'));
      expect(sheet, contains('=SUM(A1) &amp; &lt;test&gt;'));
      expect(sheet, isNot(contains('<f>')));
      expect(archive.findFile('xl/workbook.xml'), isNotNull);
    },
  );
  test('new internal tabs only include authorized resources', () {
    for (final keys in [
      [
        'branches',
        'availabilities',
        'scheduling-rules',
        'organization-holidays',
      ],
      ['members', 'users', 'member-schedules', 'employee-leaves'],
      ['terms', 'term-discounts'],
    ]) {
      final sections = [
        for (final key in keys) {'key': key},
      ];
      expect(
        objects(
          panelSectionWithTabs(sections.first, sections)['pageTabs'],
        ).map((s) => s['key']),
        keys,
      );
      expect(
        objects(
          panelSectionWithTabs(sections.first, [sections.first])['pageTabs'],
        ).length,
        1,
      );
    }
  });
  testWidgets(
    'finance combines subscriptions, summaries, guidance, exports and plan dialog',
    (tester) async {
      tester.view.physicalSize = const Size(1800, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = FinanceApi();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(
            api: api,
            section: {
              'key': 'finance',
              'label': 'امور مالی',
              'rows': 'invoices',
              'pageGuidance': {'canEdit': false},
              'actions': {
                'list': {},
                'subscriptions': {'hidden': true},
              },
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('راهنمای مالی'), findsOneWidget);
      expect(find.text('مجموع مبلغ فاکتورها'), findsOneWidget);
      expect(find.byTooltip('خروجی اکسل'), findsOneWidget);
      expect(find.byTooltip('خروجی PDF'), findsOneWidget);
      await tester.ensureVisible(find.byIcon(Icons.shopping_cart_outlined));
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pumpAndSettle();
      expect(find.text('انتخاب پلن اشتراک'), findsOneWidget);
      expect(find.text('اشتراک سه ماهه'), findsOneWidget);
    },
  );
  testWidgets('only an authorized guide editor sees editing controls', (
    tester,
  ) async {
    final reader = FinanceApi();
    addTearDown(reader.dispose);
    await tester.pumpWidget(
      fixture.host(PanelPageGuidance(api: reader, section: 'finance')),
    );
    await tester.pumpAndSettle();
    expect(find.text('ویرایش توضیحات صفحه'), findsNothing);
    final editor = FinanceApi(editor: true);
    addTearDown(editor.dispose);
    await tester.pumpWidget(
      fixture.host(
        PanelPageGuidance(
          key: const ValueKey('editor'),
          api: editor,
          section: 'finance',
          canEdit: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ویرایش توضیحات صفحه'), findsOneWidget);
  });
}
