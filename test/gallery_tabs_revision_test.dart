import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_form.dart';
import 'package:sornaz/screens/Site/panel_gallery.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

const galleryData = <String, dynamic>{
  'owners': [
    {'userId': 101, 'kind': 'academy', 'name': 'سرناز'},
    {'userId': 202, 'kind': 'branch', 'name': 'مرکز'},
  ],
  'items': [
    {'id': 1, 'ownerId': 101, 'category': 'gallery', 'title': 'عکس', 'url': ''},
    {
      'id': 2,
      'ownerId': 202,
      'category': 'gallery',
      'title': 'عکس شعبه',
      'url': '',
    },
    {'id': 3, 'ownerId': 101, 'category': 'cover', 'title': 'کاور', 'url': ''},
  ],
};

class GalleryFixture extends PanelApi {
  GalleryFixture() : super('test');
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async => {
    ...galleryData,
  };
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('gallery numbering counts only the selected owner gallery items', () {
    for (final owner in [101, 202]) {
      expect(
        panelGallerySuggestedTitle(
          {'ownerId': owner, 'collection': 'gallery'},
          galleryData,
          fa: true,
        ),
        'آیتم شماره 2 گالری (${owner == 101 ? 'سرناز' : 'مرکز'})',
      );
    }
    expect(
      panelGallerySuggestedTitle(
        {'ownerId': 202, 'collection': 'logo'},
        galleryData,
        fa: true,
      ),
      'لوگو (مرکز)',
    );
  });
  testWidgets('four tabs seed the media form and remove export actions', (
    tester,
  ) async {
    final api = GalleryFixture();
    addTearDown(api.dispose);
    await tester.pumpWidget(
      fixture.host(
        PanelResourcePage(
          api: api,
          section: const {
            'key': 'gallery',
            'label': 'گالری',
            'en': 'Gallery',
            'rows': 'items',
            'organizationFilter': true,
            'actions': {
              'list': {},
              'create': {
                'row': false,
                'label': 'افزودن',
                'fields': [
                  {
                    'key': 'collection',
                    'label': 'نوع رسانه',
                    'type': 'select',
                    'default': 'gallery',
                    'options': {
                      'cover': 'کاور',
                      'logo': 'لوگو',
                      'intro_video': 'ویدیو معرفی',
                      'gallery': 'گالری',
                    },
                  },
                  {
                    'key': 'ownerId',
                    'label': 'مالک',
                    'type': 'select',
                    'options': {'source': 'owners', 'id': 'userId'},
                  },
                  {'key': 'title', 'label': 'عنوان', 'type': 'text'},
                ],
              },
            },
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Tab), findsNWidgets(4));
    for (final category in panelGalleryCategories) {
      await tester.ensureVisible(find.widgetWithText(Tab, category.$2));
      await tester.tap(find.widgetWithText(Tab, category.$2));
      await tester.pumpAndSettle();
      tester
          .state<NestedScrollViewState>(find.byType(NestedScrollView).first)
          .outerController
          .jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.table_view), findsNothing);
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(
        find.byIcon(Icons.add),
        findsOneWidget,
        reason:
            '${category.$1}: ${tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).join(' | ')}',
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      final form = tester.widget<PanelFormPage>(find.byType(PanelFormPage));
      expect(form.initial['collection'], category.$1);
      expect(
        find.text(panelGalleryAddTitle(category.$1, fa: true)),
        findsOneWidget,
      );
      final title = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(
        title.controller!.text,
        panelGallerySuggestedTitle(
          {'ownerId': 101, 'collection': category.$1},
          galleryData,
          fa: true,
        ),
      );
      final ownerField = find.byWidgetPredicate(
        (widget) => widget is PanelField && widget.field['key'] == 'ownerId',
      );
      tester.widget<PanelField>(ownerField).changed(202);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        panelGallerySuggestedTitle(
          {'ownerId': 202, 'collection': category.$1},
          galleryData,
          fa: true,
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'عنوان دلخواه');
      tester.widget<PanelField>(ownerField).changed(101);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'عنوان دلخواه',
      );
      Navigator.of(tester.element(find.byType(PanelFormPage))).pop();
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
