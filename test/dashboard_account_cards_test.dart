import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/components/settings_section_header.dart';
import 'package:sornaz/screens/Site/panel_account.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_dashboard.dart';
import 'package:sornaz/screens/Site/panel_filter_contract.dart';
import 'package:sornaz/screens/Site/panel_presentation.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Site/panel_ui.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

class DashboardFixture extends PanelApi {
  DashboardFixture() : super('test');
  final queries = <Map<String, String>>[];
  bool failInvite = false;
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async {
    if (path == '/account/invite') {
      if (failInvite) throw const SocialException('Offline');
      return {
        'url': 'https://sornaz.com/register?ref=ABC123',
        'code': 'ABC123',
        'invitedUsers': 4,
      };
    }
    if (path == '/dashboard/list') {
      queries.add({...?query});
      return {
        'stats': {'activeStudents': 12, 'monthlyIncome': 500},
        'branches': [
          {'id': 7, 'name': 'شعبه مرکزی'},
        ],
        'todayClasses': [
          {
            'student': 'هنرجوی نمونه',
            'teacher': 'مدرس',
            'instrument': 'پیانو',
            'time': '09:00',
            'branch': 'مرکز',
            'branchId': 7,
          },
        ],
        'unreadMessages': [
          {'from': 'پیام مخفی', 'preview': 'نمایش نده'},
        ],
      };
    }
    return {};
  }
}

const dashboardSection = <String, dynamic>{
  'key': 'dashboard',
  'label': 'داشبورد',
  'en': 'Dashboard',
  'actions': {
    'list': {'row': false, 'method': 'GET'},
  },
  'filters': [
    {
      'key': 'branchId',
      'label': 'شعبه',
      'type': 'select',
      'options': {'source': 'branches'},
    },
  ],
  'relatedSections': [
    {'key': 'schedules', 'label': 'برنامه کلاس‌ها و حضور و غیاب'},
  ],
};
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('dashboard delegates organization scope to the right server key', () {
    expect(panelWebFilters(dashboardSection, {}, []), isEmpty);
    expect(panelFilterQuery([], {}, 'academy', 'dashboard'), {
      'branchId': 'academy',
    });
    expect(panelFilterQuery([], {}, 'branch:7', 'dashboard'), {
      'branchId': '7',
    });
    final source = {
      'stats': {'activeStudents': 20},
      'todayClasses': [
        {'branchId': 7, 'student': 'branch'},
        {'branchId': null, 'student': 'academy'},
      ],
    };
    final academy = panelDashboardOrganizationData(source, 'academy');
    expect(objects(academy['todayClasses']).single['student'], 'academy');
    expect(optionalObject(academy['stats'])['activeStudents'], 0);
    expect(objects(source['todayClasses']), hasLength(2));
  });
  testWidgets(
    'dashboard removes PDF and shortcut links and offers all academy and branch scopes',
    (tester) async {
      final api = DashboardFixture();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        fixture.host(PanelResourcePage(api: api, section: dashboardSection)),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNothing);
      expect(find.text('برنامه کلاس‌ها و حضور و غیاب'), findsNothing);
      expect(find.text('پیام‌های خوانده‌نشده'), findsNothing);
      expect(find.text('پیام مخفی'), findsNothing);
      await tester.tap(find.widgetWithText(PanelValueRow, 'سازمان'));
      await tester.pumpAndSettle();
      final modal = find.byType(PanelModal);
      for (final label in ['همه', 'آموزشگاه', 'شعبه مرکزی']) {
        expect(
          find.descendant(of: modal, matching: find.text(label)),
          findsOneWidget,
        );
      }
      await tester.tap(
        find.descendant(of: modal, matching: find.text('آموزشگاه')),
      );
      await tester.pumpAndSettle();
      expect(api.queries.last['branchId'], 'academy');
      expect(find.text('هنرجوی نمونه'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'dashboard sections are separate cards and view all opens the corresponding destination',
    (tester) async {
      String? opened;
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: SingleChildScrollView(
              child: PanelDashboard(
                data: const {},
                onOpen: (key) => opened = key,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('dashboard-todayClasses')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboard-recentPayments')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboard-unreadMessages')),
        findsNothing,
      );
      final view = find.descendant(
        of: find.byKey(const ValueKey('dashboard-todayClasses')),
        matching: find.text('مشاهده همه'),
      );
      await tester.ensureVisible(view);
      await tester.tap(view);
      await tester.pumpAndSettle();
      expect(opened, 'schedules');
      expect(tester.takeException(), isNull);
    },
  );
  for (final language in ['fa', 'en']) {
    testWidgets(
      'statistics use website titles and put values at the row end in $language',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => AppData(),
            child: MaterialApp(
              locale: Locale(language),
              supportedLocales: const [Locale('fa'), Locale('en')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: Scaffold(
                body: PanelStatistics(
                  stats: const {'monthlyIncome': 500, 'attendanceRate': '50%'},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final label = find.byKey(
          const ValueKey('panel-stat-label-monthlyIncome'),
        );
        final number = find.byKey(
          const ValueKey('panel-stat-value-monthlyIncome'),
        );
        expect(tester.widget<Text>(label).maxLines, 1);
        expect(
          tester.widget<Text>(label).data,
          language == 'fa' ? 'درآمد ماهانه' : 'Monthly income',
        );
        expect(
          tester.getCenter(number).dx,
          language == 'fa'
              ? lessThan(tester.getCenter(label).dx)
              : greaterThan(tester.getCenter(label).dx),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'account invitation loads link and small code with theme badge and collapsible sections',
    (tester) async {
      final api = DashboardFixture();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: SingleChildScrollView(
              child: PanelAccount(
                api: api,
                data: const {
                  'profile': {'accountType': 'academy', 'name': 'آموزشگاه'},
                },
                actions: const {},
                onAction: (_, row) async {},
                onChanged: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final inviteSection = find.byKey(
        const ValueKey('account-section-My invitation link'),
      );
      expect(
        tester.widget<SettingsSectionHeader>(inviteSection).initiallyExpanded,
        isFalse,
      );
      await tester.ensureVisible(inviteSection);
      await tester.tap(
        find.descendant(of: inviteSection, matching: find.text('لینک دعوت من')),
      );
      await tester.pumpAndSettle();
      final url = find.byKey(
        const ValueKey('invite-https://sornaz.com/register?ref=ABC123'),
      );
      expect(
        tester.widget<TextFormField>(url).initialValue,
        'https://sornaz.com/register?ref=ABC123',
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(of: url, matching: find.byType(TextField)),
            )
            .readOnly,
        isTrue,
      );
      final badge = find.text('4 کاربر دعوت‌شده');
      final context = tester.element(badge);
      expect(
        tester.widget<Text>(badge).style!.color,
        Theme.of(context).colorScheme.primary,
      );
      expect(
        tester.widget<Text>(find.text('کد اختصاصی: ABC123')).style!.fontSize,
        Theme.of(context).textTheme.bodySmall!.fontSize,
      );
      expect(find.byType(SettingsSectionHeader), findsWidgets);
      final invite = find.byKey(
        const ValueKey('account-section-My invitation link'),
      );
      await tester.ensureVisible(invite);
      await tester.tap(
        find.descendant(of: invite, matching: find.text('لینک دعوت من')),
      );
      await tester.pumpAndSettle();
      expect(url.hitTestable(), findsNothing);
      await tester.tap(
        find.descendant(of: invite, matching: find.text('لینک دعوت من')),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(url).initialValue,
        contains('ABC123'),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
