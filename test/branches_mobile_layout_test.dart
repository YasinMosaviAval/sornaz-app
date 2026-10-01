import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/components/expanding_search_bar.dart';
import 'package:sornaz/screens/Site/branch_form.dart';
import 'package:sornaz/screens/Site/branch_style.dart';
import 'package:sornaz/screens/Site/branch_export.dart';
import 'package:sornaz/screens/Site/branch_color_picker.dart';
import 'package:sornaz/screens/Site/branches_page.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as localized;

Json catalog() => {
  'site_admin': false,
  'branch_account': false,
  'can_create_branch': true,
  'can_delete_branch': true,
  'types': [
    {
      'id': 1,
      'name': 'موسیقی',
      'title': 'موسیقی',
      'summary': 'خلاصه',
      'description': 'شرح',
    },
  ],
  'academies': [],
  'manager_candidates': [
    {'user_id': 8, 'academy_id': 3, 'name': 'مدیر نمونه'},
  ],
  'provinces': [
    {'province_id': 1, 'province_name': 'تهران'},
    {'province_id': 2, 'province_name': 'فارس'},
  ],
  'counties': [
    {'province_id': 1, 'county_name': 'تهران'},
    {'province_id': 2, 'county_name': 'شیراز'},
  ],
  'branches': [
    for (var i = 1; i <= 2; i++)
      {
        'id': i,
        'academy_id': 3,
        'academy_name': 'آموزشگاه نمونه',
        'name': i == 1 ? 'شعبه مرکزی' : 'شعبه دوم',
        'username': 'branch$i',
        'type_id': 1,
        'type': 'موسیقی',
        'physical_type': 'physical',
        'is_main': i == 1,
        'manager_user_id': 8,
        'manager': 'مدیر نمونه',
        'status': 'فعال',
        'classrooms': 4,
        'slogan': 'شعار شعبه',
        'short_description': 'معرفی کوتاه',
        'bio': 'بیوگرافی',
        'phones': [
          {'number': '02112345678', 'priority': 'primary', 'is_main': true},
        ],
        'links': [
          {
            'title': 'وب‌سایت',
            'url': 'https://example.com',
            'mode': 'social',
            'platform': 'website',
            'priority': 'secondary',
            'is_main': true,
          },
        ],
        'addresses': [
          {
            'province': 'تهران',
            'city': 'تهران',
            'address': 'خیابان نمونه',
            'postal_code': '1234567890',
            'lat': '35.7',
            'lng': '51.4',
            'is_main': true,
          },
        ],
      },
  ],
};
const section = {
  'key': 'branches',
  'label': 'شعبه‌ها',
  'en': 'Branches',
  'actions': {'list': {}, 'create': {}, 'update': {}, 'delete': {}},
};

class BranchApi extends PanelApi {
  BranchApi(this.data) : super('test');
  final Json data;
  int reads = 0;
  final changes = <Json>[];
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async {
    reads++;
    return data;
  }

  @override
  Future<Json> act(
    String section,
    String action, {
    Json values = const {},
    Map<String, String> params = const {},
    files = const {},
  }) async {
    changes.add({
      'section': section,
      'action': action,
      'values': values,
      'params': params,
    });
    if (action == 'update') {
      final rows = objects(data['branches']);
      final index = rows.indexWhere((r) => '${r['id']}' == params['id']);
      rows[index] = {...rows[index], ...values};
      data['branches'] = rows;
    }
    return values;
  }
}

void main() {
  testWidgets(
    'toolbar actions, compact statistics, modal filters and PDF palettes',
    (tester) async {
      final data = catalog()..['site_admin'] = true;
      final api = BranchApi(data);
      addTearDown(api.dispose);
      tester.view.physicalSize = const Size(375, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        localized.host(BranchesPage(api: api, section: section)),
      );
      await tester.pumpAndSettle();
      final title = tester.widget<Text>(find.text('مدیریت شعبه‌ها'));
      expect(title.style!.fontSize, 14);
      expect(find.byIcon(Icons.refresh), findsNothing);
      for (final tooltip in [
        'افزودن شعبه جدید',
        'خروجی اکسل',
        'خروجی PDF',
        'جستجو',
      ]) {
        expect(
          find.descendant(
            of: find.byType(ExpandingSearchBar),
            matching: find.byTooltip(tooltip),
          ),
          findsOneWidget,
        );
      }
      final academies = find.byKey(const ValueKey('stat-تعداد آموزشگاه‌ها'));
      final branches = find.byKey(const ValueKey('stat-تعداد شعبه‌ها'));
      expect(tester.getSize(academies).height, 40);
      expect(tester.getTopLeft(academies).dy, tester.getTopLeft(branches).dy);
      expect(
        tester
            .getSize(find.widgetWithText(OutlinedButton, 'نمایش جدولی'))
            .height,
        40,
      );
      await tester.tap(find.byKey(const ValueKey('branch-filter-mode')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.text('نوع ارائه').last).style!.fontSize,
        14,
      );
      await tester.tap(find.text('آنلاین'));
      await tester.pumpAndSettle();
      expect(find.text('شعبه‌ای یافت نشد'), findsOneWidget);
      expect(api.reads, 1);
      await tester.tap(find.byTooltip('خروجی PDF'));
      await tester.pumpAndSettle();
      expect(find.byType(BranchColorPicker), findsNWidgets(3));
      expect(
        tester.widget<Text>(find.text('تنظیمات خروجی PDF')).style!.fontSize,
        14,
      );
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'continuous palette changes the selected RGB color while dragging',
    (tester) async {
      var selected = 'ffffff';
      await tester.pumpWidget(
        localized.host(
          Scaffold(
            body: BranchColorPicker(
              label: 'Color',
              value: selected,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      );
      final plane = find.byKey(const ValueKey('palette-Color'));
      await tester.tapAt(tester.getTopLeft(plane) + const Offset(150, 60));
      await tester.pump();
      expect(selected, matches(RegExp(r'^[0-9a-f]{6}$')));
      expect(selected, isNot('ffffff'));
      final first = selected;
      await tester.drag(plane, const Offset(60, 40));
      await tester.pump();
      expect(selected, isNot(first));
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 375.0, 430.0]) {
    testWidgets('mobile branch cards and dialogs fit RTL at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = BranchApi(catalog());
      addTearDown(api.dispose);
      await tester.pumpWidget(
        localized.host(PanelResourcePage(api: api, section: section)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BranchesPage), findsOneWidget);
      expect(api.reads, 1);
      expect(find.text('مدیریت شعبه‌ها'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('branch-card-1')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('branch-card-1'));
      expect(
        tester.widget<BranchSurface>(card).color,
        branchHighlight(tester.element(card)),
      );
      expect(
        find.descendant(of: card, matching: find.text('حذف')),
        findsNothing,
      );
      final details = find.descendant(of: card, matching: find.text('جزئیات'));
      await tester.ensureVisible(details);
      await tester.tap(details);
      await tester.pumpAndSettle();
      expect(find.byType(BranchDialog), findsOneWidget);
      expect(find.textContaining('شعبه اصلی'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 10));
      expect(api.reads, 1);
    });
  }
  testWidgets(
    'search stays local and switching to table preserves filtered rows',
    (tester) async {
      final api = BranchApi(catalog());
      addTearDown(api.dispose);
      await tester.pumpWidget(
        localized.host(PanelResourcePage(api: api, section: section)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('جستجو'));
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey('branch-search'));
      await tester.scrollUntilVisible(
        search,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(search, 'دوم');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('branch-card-2')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey('branch-card-1')), findsNothing);
      expect(api.reads, 1);
      await tester.scrollUntilVisible(
        find.text('نمایش جدولی'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('نمایش جدولی'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(DataTable),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<DataTable>(find.byType(DataTable)).rows.length, 1);
      expect(api.reads, 1);
    },
  );
  testWidgets(
    'read-only branch accounts cannot create, edit, delete or cycle status',
    (tester) async {
      final data = catalog()
        ..addAll({
          'read_only': true,
          'branch_account': true,
          'site_admin': true,
        });
      final api = BranchApi(data);
      addTearDown(api.dispose);
      await tester.pumpWidget(
        localized.host(BranchesPage(api: api, section: section)),
      );
      await tester.pumpAndSettle();
      expect(find.text('افزودن شعبه جدید'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('نمایش کارتی'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('نمایش کارتی'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('branch-card-1')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('ویرایش'), findsNothing);
      expect(find.text('حذف'), findsNothing);
      expect(find.text('همه آموزشگاه‌ها'), findsNothing);
      final badge = find.descendant(
        of: find.byKey(const ValueKey('branch-card-1')),
        matching: find.text('فعال'),
      );
      await tester.ensureVisible(badge);
      await tester.tap(badge);
      await tester.pump();
      expect(api.changes, isEmpty);
    },
  );
  testWidgets(
    'edit preserves nested contacts, main branch identity and selected manager',
    (tester) async {
      final data = catalog();
      final api = BranchApi(data);
      addTearDown(api.dispose);
      final original = objects(data['branches']).first;
      await tester.pumpWidget(
        localized.host(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) =>
                      BranchForm(api: api, data: data, row: original),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'نام ویرایش شده',
      );
      final save = find.widgetWithText(FilledButton, 'ذخیره تغییرات');
      await tester.scrollUntilVisible(
        save,
        500,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(api.changes.length, 1);
      final saved = object(api.changes.single['values']);
      expect(saved['name'], 'نام ویرایش شده');
      expect(saved['username'], original['username']);
      expect(saved['is_main'], true);
      for (final key in ['phones', 'links', 'addresses', 'manager_user_id'])
        expect(saved[key], original[key]);
      expect(find.byType(BranchDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  test('branch PDF supports selected columns and page options', () async {
    final options =
        BranchPdfOptions(
            title: 'Branches',
            subtitle: 'Report',
            footer: 'Footer',
            columns: {'name', 'status'},
          )
          ..format = 'letter'
          ..landscape = false;
    final bytes = await branchPdf(
      [
        {'name': 'شعبه مرکزی', 'status': 'فعال', 'hidden': 'secret'},
      ],
      {'name': 'نام', 'status': 'وضعیت', 'hidden': 'Hidden'},
      options,
      rtl: true,
    );
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });
  testWidgets(
    'status cycling uses the existing update API and retains contact data',
    (tester) async {
      final data = catalog();
      final original = objects(data['branches']).first;
      final api = BranchApi(data);
      addTearDown(api.dispose);
      await tester.pumpWidget(
        localized.host(BranchesPage(api: api, section: section)),
      );
      await tester.pumpAndSettle();
      final card = find.byKey(const ValueKey('branch-card-1'));
      await tester.scrollUntilVisible(
        card,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      final status = find.descendant(of: card, matching: find.text('فعال'));
      await tester.ensureVisible(status);
      await tester.tap(status);
      await tester.pumpAndSettle();
      expect(api.changes.single['action'], 'update');
      final payload = object(api.changes.single['values']);
      expect(payload['status'], 'inactive');
      for (final key in [
        'phones',
        'links',
        'addresses',
        'username',
        'manager_user_id',
      ]) {
        expect(payload[key], original[key]);
      }
      expect(api.reads, 2);
    },
  );
  testWidgets(
    'education type form saves title, summary and description through its own API',
    (tester) async {
      final api = BranchApi(catalog());
      addTearDown(api.dispose);
      await tester.pumpWidget(
        localized.host(
          BranchesPage(api: api, section: {...section, 'key': 'branch-types'}),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('نوع آموزشی جدید'));
      await tester.pumpAndSettle();
      final inputs = find.byType(TextFormField);
      await tester.enterText(inputs.at(0), 'نوع جدید');
      await tester.enterText(inputs.at(1), 'خلاصه جدید');
      await tester.enterText(inputs.at(2), 'شرح جدید');
      final save = find.widgetWithText(FilledButton, 'ذخیره تغییرات');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(api.changes.single['section'], 'branch-types');
      expect(api.changes.single['action'], 'create');
      expect(object(api.changes.single['values'])['summary'], 'خلاصه جدید');
    },
  );
}
