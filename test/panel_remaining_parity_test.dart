import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_navigation.dart';
import 'package:sornaz/screens/Site/panel_organization_filter.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

class MenuApi extends PanelApi {
  MenuApi() : super('test');
  final calls = <String>[];
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async {
    calls.add(path);
    return switch (path) {
      '/branches/list' => {'branches': <Json>[]},
      '/availabilities/list' => {
        'schedules': [
          {
            'id': 11,
            'day': 'شنبه',
            'timeLabel': '09:00 - 10:00',
            'timezone': 'Asia/Tehran',
            'status': 'فعال',
          },
        ],
      },
      '/scheduling-rules/list' => {
        'rules': [
          {'id': 12, 'title': 'قانون نمونه', 'type': 'رزرو', 'status': 'فعال'},
        ],
      },
      '/organization-holidays/list' => {
        'exceptions': [
          {
            'id': 13,
            'name': 'تعطیلی نمونه',
            'type': 'closed',
            'status': 'active',
          },
        ],
      },
      '/terms/list' => {'terms': <Json>[]},
      '/courses/list' => {},
      '/term-discounts/list' => {
        'ready': true,
        'organizations': [
          {'user_id': 91, 'kind': 'academy', 'name': 'آموزشگاه'},
        ],
        'discounts': [
          {
            'id': 4,
            'name': 'تخفیف ویژه',
            'type': 'percentage',
            'value': 15,
            'organizationKind': 'academy',
            'organizationUserId': 91,
            'organizationName': 'آموزشگاه',
            'canManage': false,
          },
        ],
      },
      '/finance/list' => {
        'invoices': <Json>[],
        'subscriptions': {
          'periods': [
            {
              'id': 6,
              'status': 'ماه اول رایگان',
              'statusCode': 'free',
              'amount': 0,
              'canPay': false,
            },
            {
              'id': 7,
              'status': 'در انتظار پرداخت',
              'statusCode': 'pending',
              'amount': 2000000,
              'canPay': true,
            },
          ],
          'plans': [
            {'months': 1, 'label': 'اشتراک یک ماهه', 'amount': 2000000},
          ],
        },
      },
      '/page-guidance/list' => {},
      _ => {},
    };
  }
}

Json section(String key, String rows) => {
  'key': key,
  'label': key,
  'en': key,
  'rows': rows,
  'actions': {'list': {}},
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> wide(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'organization menu keeps its tab bar inside the dedicated branches screen',
    (tester) async {
      await wide(tester);
      final api = MenuApi();
      addTearDown(api.dispose);
      final menu = websitePanelNavigation({
        'navigationVersion': 1,
        'sections': [
          section('branches', 'branches'),
          section('availabilities', 'schedules'),
          section('scheduling-rules', 'rules'),
          section('organization-holidays', 'exceptions'),
        ],
        'navigation': [
          {
            'key': 'branches',
            'section': 'branches',
            'label': 'سازمان',
            'en': 'Organization',
          },
        ],
      });
      await tester.pumpWidget(
        fixture.host(PanelResourcePage(api: api, section: menu.single)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(4));
      for (final index in [1, 2, 3, 0]) {
        await tester.ensureVisible(find.byType(Tab).at(index));
        await tester.tap(find.byType(Tab).at(index));
        await tester.pumpAndSettle();
        expect(find.byType(TabBar), findsOneWidget);
        expect(
          api.calls.lastWhere((path) => path != '/national-holidays/list'),
          '/${['branches', 'availabilities', 'scheduling-rules', 'organization-holidays'][index]}/list',
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'term menu switches to the discounts collection rather than opening a generic operation result',
    (tester) async {
      await wide(tester);
      final api = MenuApi();
      addTearDown(api.dispose);
      final menu = websitePanelNavigation({
        'navigationVersion': 1,
        'sections': [
          section('terms', 'terms'),
          section('term-discounts', 'discounts'),
        ],
        'navigation': [
          {
            'key': 'terms',
            'section': 'terms',
            'label': 'ترم‌ها',
            'en': 'Terms',
          },
        ],
      });
      await tester.pumpWidget(
        fixture.host(PanelResourcePage(api: api, section: menu.single)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Tab), findsNWidgets(2));
      await tester.tap(find.text('تخفیف‌ها'));
      await tester.pumpAndSettle();
      expect(api.calls.last, '/term-discounts/list');
      expect(find.text('تخفیف ویژه'), findsOneWidget);
      expect(find.text('عنوان تخفیف'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      expect(find.text('15%'), findsOneWidget);
      await tester.ensureVisible(find.byIcon(Icons.info_outline));
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      expect(find.text('جزئیات تخفیف'), findsOneWidget);
      expect(find.text('تاریخ شروع'), findsOneWidget);
      expect(find.text('organizationUserId'), findsNothing);
    },
  );
  test('gallery owner account IDs stay separate from branch entity IDs', () {
    final data = {
      'owners': [
        {'userId': 101, 'entityId': 7, 'kind': 'academy', 'name': 'آموزشگاه'},
        {'userId': 202, 'entityId': 8, 'kind': 'branch', 'name': 'شعبه مرکزی'},
      ],
    };
    final options = panelOrganizationOptions(data, [], fa: true);
    expect(options['owner:202'], 'شعبه مرکزی');
    expect(
      panelMatchesOrganization({'ownerId': 202}, 'owner:202', data),
      isTrue,
    );
    expect(
      panelMatchesOrganization({'ownerId': 101}, 'owner:202', data),
      isFalse,
    );
    expect(panelMatchesOrganization({'ownerId': 101}, 'academy', data), isTrue);
    expect(
      panelMatchesOrganization({'ownerId': 202}, 'academy', data),
      isFalse,
    );
  });
  testWidgets(
    'finance reads free and payable subscription periods from its list response without a catalog-only action',
    (tester) async {
      await wide(tester);
      final api = MenuApi();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(api: api, section: section('finance', 'invoices')),
        ),
      );
      await tester.pumpAndSettle();
      expect(api.calls, ['/finance/list']);
      expect(find.byTooltip('خروجی اکسل'), findsOneWidget);
      expect(find.byTooltip('خروجی PDF'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
      expect(find.text('ماه اول رایگان'), findsNWidgets(2));
      expect(find.text('در انتظار پرداخت'), findsWidgets);
      await tester.ensureVisible(find.byIcon(Icons.shopping_cart_outlined));
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pumpAndSettle();
      expect(find.text('انتخاب پلن اشتراک'), findsOneWidget);
      expect(find.text('اشتراک یک ماهه'), findsOneWidget);
    },
  );
  testWidgets(
    'website template guidance is visible even before database overrides exist',
    (tester) async {
      await wide(tester);
      final api = MenuApi();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(
            api: api,
            section: {
              ...section('terms', 'terms'),
              'pageGuidance': {'canEdit': true},
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('ترم‌ها را پیش از درخواست ثبت‌نام آماده کنید'),
        findsOneWidget,
      );
      expect(find.text('ویرایش توضیحات صفحه'), findsOneWidget);
    },
  );
}
