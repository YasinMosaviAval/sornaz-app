import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Site/panel_api.dart';
import 'package:sornaz/screens/Site/panel_form.dart';
import 'package:sornaz/screens/Site/panel_form_contract.dart';
import 'package:sornaz/screens/Site/panel_resource_page.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'social_widget_test.dart' as fixture;

const post = <String, dynamic>{
  'id': 1,
  'title': 'Article',
  'slug': 'article',
  'content': '<p>Keep body</p>',
  'summary': 'Keep summary',
  'description': 'Keep description',
  'status': 'request-confirmed',
  'categories': '1,99',
  'related_posts_id': '2',
  'cover': '/cover.png',
  'cover_media_id': 17,
  'visibility_user_id': 72,
};
const fields = <Map<String, dynamic>>[
  {'key': 'title', 'label': 'عنوان', 'type': 'text', 'required': true},
  {
    'key': 'status',
    'label': 'وضعیت',
    'type': 'select',
    'options': {'draft': 'پیش‌نویس', 'request-confirmed': 'درخواست تأییدشده'},
  },
  {
    'key': 'categories',
    'label': 'دسته‌ها',
    'type': 'multi',
    'csv': true,
    'preserveUnknown': true,
    'options': {'source': 'categories', 'id': 'id', 'label': 'title_fa'},
  },
  {
    'key': 'related_posts_id',
    'label': 'نوشته‌های مرتبط',
    'type': 'multi',
    'csv': true,
    'preserveUnknown': true,
    'options': {'source': 'relatedPosts', 'id': 'id', 'label': 'title'},
  },
];

class PostFixture extends PanelApi {
  PostFixture() : super('test');
  final writes = <Json>[];
  @override
  Future<Json> get(String path, [Map<String, String>? query]) async =>
      switch (path) {
        '/posts/list' => {
          'posts': [
            {...post},
          ],
          'total': 1,
          'page': 1,
          'perPage': 10,
        },
        '/posts/details' => {...post},
        '/posts/category-options' => {
          'items': [
            {'id': 1, 'title_fa': 'Category'},
          ],
        },
        '/posts/related-options' => {
          'posts': [
            {'id': 2, 'title': 'Related title'},
          ],
        },
        _ => {},
      };
  @override
  Future<Json> act(
    String section,
    String action, {
    Json values = const {},
    Map<String, String> params = const {},
    Map<String, dynamic> files = const {},
  }) async {
    writes.add({'action': action, 'values': values, 'id': params['id']});
    return {};
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'CSV post choices retain unknown selections and full edits retain hidden audience',
    () {
      final initial = panelInitialValues(fields, post, {});
      expect(initial['categories'], [1, 99]);
      final metadata = panelDialogPayload(
        'posts',
        'metadata',
        {
          'categories': [1, 99],
          'related_posts_id': [2],
        },
        {'record': post},
      );
      expect(metadata['categories'], '1,99');
      expect(metadata.containsKey('content'), false);
      expect(metadata.containsKey('visibility_user_id'), false);
      expect(
        panelDialogPayload(
          'posts',
          'update',
          {'title': 'New'},
          {'record': post},
        )['visibility_user_id'],
        72,
      );
    },
  );
  test(
    'post workflow captions use catalog English options with stable values',
    () {
      final previous = SocialApi.locale;
      try {
        SocialApi.locale = 'en';
        expect(
          panelSelectOptions({
            'options': {'request-confirmed': 'درخواست تأییدشده'},
            'optionsEn': {'request-confirmed': 'Confirmed request'},
          }, {}),
          {'request-confirmed': 'Confirmed request'},
        );
        SocialApi.locale = 'fa';
        expect(
          panelSelectOptions({
            'options': {'request-confirmed': 'درخواست تأییدشده'},
            'optionsEn': {'request-confirmed': 'Confirmed request'},
          }, {}),
          {'request-confirmed': 'درخواست تأییدشده'},
        );
      } finally {
        SocialApi.locale = previous;
      }
    },
  );
  testWidgets(
    'post row editing expands metadata without article fields and title opens full editor',
    (tester) async {
      final api = PostFixture();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        fixture.host(
          PanelResourcePage(
            api: api,
            section: const {
              'key': 'posts',
              'label': 'نوشته‌ها',
              'rows': 'posts',
              'optionActions': ['category-options', 'related-options'],
              'presentation': {
                'version': 2,
                'columns': [
                  {'key': 'title', 'label': 'عنوان'},
                ],
                'rowActions': ['metadata'],
              },
              'actions': {
                'list': {},
                'details': {'method': 'GET'},
                'category-options': {'optionResultKey': 'categories'},
                'related-options': {'optionResultKey': 'relatedPosts'},
                'metadata': {
                  'row': true,
                  'method': 'POST',
                  'formContractVersion': 2,
                  'fields': fields,
                },
                'update': {
                  'row': true,
                  'method': 'POST',
                  'recordAction': 'details',
                  'formContractVersion': 2,
                  'fields': [
                    ...fields,
                    {
                      'key': 'content',
                      'label': 'متن مقاله',
                      'type': 'multiline',
                    },
                    {'key': 'summary', 'label': 'خلاصه', 'type': 'multiline'},
                  ],
                },
              },
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('ویرایش'));
      await tester.pumpAndSettle();
      expect(find.byType(PanelFormPage), findsOneWidget);
      expect(
        tester.widget<PanelFormPage>(find.byType(PanelFormPage)).embedded,
        true,
      );
      expect(find.text('متن مقاله'), findsNothing);
      expect(find.text('خلاصه'), findsNothing);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Related title'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'New article');
      await tester.ensureVisible(find.text('ذخیره تغییرات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ذخیره تغییرات'));
      await tester.pumpAndSettle();
      expect(api.writes.single['action'], 'metadata');
      expect(api.writes.single['values']['categories'], '1,99');
      expect(api.writes.single['values']['status'], 'request-confirmed');
      expect(api.writes.single['values'].containsKey('content'), false);
      await tester.tap(find.text('Article'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PanelFormPage>(find.byType(PanelFormPage)).embedded,
        false,
      );
      expect(find.text('متن مقاله'), findsOneWidget);
      await tester.tap(find.byTooltip('ذخیره'));
      await tester.pumpAndSettle();
      expect(api.writes.last['action'], 'update');
      expect(api.writes.last['values']['cover_media_id'], 17);
      expect(api.writes.last['values']['cover'], '/cover.png');
      expect(api.writes.last['values']['visibility_user_id'], 72);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
