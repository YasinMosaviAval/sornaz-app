import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/MusicPractice/practice_form_field.dart';
import 'package:sornaz/screens/MusicPractice/practice_manage_page.dart';
import 'package:sornaz/screens/MusicPractice/practice_player_page.dart';
import 'package:sornaz/screens/MusicPractice/practice_repository.dart';
import 'package:sornaz/screens/Social/social_api.dart';
import 'music_practice_test.dart' show TreePracticeRepository;

class FeedbackRepository extends TreePracticeRepository {
  bool failSave = true;
  @override
  Future<PracticeJson> request(String path, [PracticeJson? payload]) async {
    if (path == 'exams' && failSave) {
      throw const SocialException('Fixture validation error', 422);
    }
    return super.request(path, payload);
  }
}

void main() {
  test(
    'question prompt falls back for previously cached single-locale exams',
    () {
      expect(promptText({'promptFa': 'FA', 'promptEn': ''}, true), 'FA');
      expect(promptText({'promptEn': 'EN'}, false), 'EN');
      expect(promptText({'promptFa': 'FA', 'promptEn': 'EN'}, true), 'EN');
    },
  );
  for (final language in ['fa', 'en']) {
    for (final dark in [false, true]) {
      testWidgets(
        'single-locale question and bottom save feedback $language/$dark',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = FeedbackRepository(), en = language == 'en';
          final data = await repo.catalog(manage: true);
          data['notationQuestions'] = true;
          final promptKey = en ? 'promptEn' : 'promptFa';
          await tester.pumpWidget(
            ChangeNotifierProvider(
              create: (_) => AppData()..toggleDarkMode(dark),
              child: MaterialApp(
                locale: Locale(language),
                supportedLocales: const [Locale('fa'), Locale('en')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                theme: dark ? ThemeData.dark() : ThemeData.light(),
                home: MusicPracticeEditPage(
                  repository: repo,
                  catalog: data,
                  kind: 'exams',
                  item: {
                    'nodeId': 3,
                    'config': {
                      'kind': 'choice',
                      'questions': [
                        {
                          promptKey: 'Question',
                          'choices': ['A', 'B'],
                          'correct': 0,
                        },
                      ],
                    },
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final save = find.byKey(const ValueKey('practice-save'));
          expect(find.byIcon(Icons.save_outlined), findsNothing);
          expect(
            tester
                .widget<FilledButton>(save)
                .style
                ?.textStyle
                ?.resolve({})
                ?.fontSize,
            14,
          );
          expect(tester.getBottomRight(save).dy, closeTo(888, 1));
          addTearDown(tester.view.resetViewInsets);
          tester.view.viewInsets = const FakeViewPadding(bottom: 240);
          await tester.pumpAndSettle();
          expect(tester.getBottomRight(save).dy, closeTo(648, 1));
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
          // A local validation failure is shown in the same footer as server errors.
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('practice-form-error')),
            findsOneWidget,
          );
          final title = find.byWidgetPredicate(
            (w) =>
                w is PracticeFormField &&
                w.name == (en ? 'titleEn' : 'titleFa'),
          );
          await tester.enterText(
            find.descendant(of: title, matching: find.byType(TextField)),
            'New exam',
          );
          final prompt = find.byWidgetPredicate(
            (w) => w is PracticeFormField && w.name == promptKey,
          );
          await tester.scrollUntilVisible(
            prompt,
            180,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is PracticeFormField &&
                  w.name == (en ? 'promptFa' : 'promptEn'),
            ),
            findsNothing,
          );
          final input = tester.widget<TextField>(
            find.descendant(of: prompt, matching: find.byType(TextField)),
          );
          expect(input.decoration?.enabledBorder, isA<OutlineInputBorder>());
          expect(input.style?.fontSize, 12);
          final type = find.byWidgetPredicate(
            (w) =>
                w is InputDecorator &&
                w.decoration.labelText == (en ? 'Practice type' : 'نوع تمرین'),
          );
          await tester.ensureVisible(type);
          await tester.pumpAndSettle();
          expect(tester.getSize(type).width, closeTo(296, 1));
          await tester.tap(save);
          await tester.pumpAndSettle();
          final error = find.byKey(const ValueKey('practice-form-error'));
          final message = tester.widget<Text>(error);
          expect(message.data, 'Fixture validation error');
          expect(message.style?.color, Colors.red);
          expect(message.style?.fontSize, 12);
          expect(
            tester.getBottomRight(error).dy,
            lessThan(tester.getTopLeft(save).dy),
          );
          repo.failSave = false;
          await tester.tap(save);
          await tester.pumpAndSettle();
          final question = repo.writes.single['config']['questions'][0] as Map;
          expect(question[promptKey], 'Question');
          expect(question.containsKey(en ? 'promptFa' : 'promptEn'), false);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          repo.dispose();
        },
      );
    }
  }
}
