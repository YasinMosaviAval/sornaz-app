import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/MusicPractice/practice_form_field.dart';
import 'package:sornaz/screens/MusicPractice/practice_manage_page.dart';
import 'package:sornaz/screens/MusicPractice/practice_repository.dart';
import 'package:http/testing.dart';
import 'social_widget_test.dart' as fixture;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'new section suggests an English address and preserves a manual override',
    (tester) async {
      final repo = MusicPracticeRepository(
        userId: 1,
        token: () => null,
        client: MockClient((_) async => throw StateError('Unexpected request')),
      );
      await tester.pumpWidget(
        fixture.host(
          MusicPracticeEditPage(
            repository: repo,
            kind: 'nodes',
            catalog: {
              'nodes': [],
              'exams': [],
              'capabilities': {'publish': true},
            },
          ),
        ),
      );
      final english = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'عنوان انگلیسی',
      );
      await tester.enterText(english, 'Ear Training');
      await tester.pumpAndSettle();
      final address = find.byWidgetPredicate(
        (w) => w is PracticeFormField && w.name == 'slug',
      );
      expect(
        tester.widget<PracticeFormField>(address).controller.text,
        'ear-training',
      );
      final addressInput = find.descendant(
        of: address,
        matching: find.byType(TextField),
      );
      await Scrollable.ensureVisible(
        tester.element(addressInput),
        alignment: .3,
      );
      await tester.pumpAndSettle();
      await tester.enterText(addressInput, 'CUSTOM-SLUG');
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(tester.element(english), alignment: .3);
      await tester.pumpAndSettle();
      await tester.enterText(english, 'Another Title');
      await tester.pumpAndSettle();
      expect(
        tester.widget<PracticeFormField>(address).controller.text,
        'custom-slug',
      );
      await tester.pumpWidget(const SizedBox());
      repo.dispose();
    },
  );
  test('music authoring constraints match accepted server formats', () {
    expect(PracticeFieldValidation.normalize('quarterSteps', '۱۴،٢٤'), '14,24');
    expect(
      PracticeFieldValidation.suggestSlug(' Ear Training '),
      'ear-training',
    );
    expect(
      PracticeFieldValidation.suggestSlug('2026 Practice'),
      'section-2026-practice',
    );
    for (final pair in <(String, String)>[
      ('slug', 'Ear-TRAINING'),
      ('position', '0'),
      ('stageCount', '100'),
      ('requiredWins', '1'),
      ('amount', '1000'),
      ('days', '366'),
      ('teacherPercent', '72.55'),
      ('quarterSteps', '۱۴،۲۴'),
      ('beats', '1,0.5,0.125'),
      ('bpm', '240'),
      ('choices', 'First\nSecond'),
    ]) {
      expect(
        PracticeFieldValidation.error(pair.$1, pair.$2, true),
        isNull,
        reason: pair.toString(),
      );
    }
    for (final pair in <(String, String)>[
      ('slug', 'آزمون'),
      ('slug', 'https://example.com'),
      ('slug', '1-test'),
      ('position', '-1'),
      ('stageCount', '0'),
      ('stageCount', '101'),
      ('amount', '999'),
      ('days', '367'),
      ('teacherPercent', '72.555'),
      ('quarterSteps', '14,25'),
      ('quarterSteps', '1,,2'),
      ('beats', '0x1'),
      ('beats', '0.1'),
      ('bpm', '241'),
      ('choices', 'Only one'),
    ]) {
      expect(
        PracticeFieldValidation.error(pair.$1, pair.$2, true),
        isNotNull,
        reason: pair.toString(),
      );
    }
    expect(
      PracticeFieldValidation.error('correct', '0', true, choiceCount: 2),
      isNull,
    );
    expect(
      PracticeFieldValidation.error('correct', '2', true, choiceCount: 2),
      isNotNull,
    );
    expect(
      PracticeFieldValidation.error('titleFa', 'a' * 201, true),
      isNotNull,
    );
  });
  testWidgets(
    'field guidance changes neutral, invalid and valid colors while focused',
    (tester) async {
      final controller = TextEditingController(), form = GlobalKey<FormState>();
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            body: Form(
              key: form,
              child: PracticeFormField(
                name: 'slug',
                label: 'نشانی',
                controller: controller,
              ),
            ),
          ),
        ),
      );
      InputDecoration decoration() =>
          tester.widget<TextField>(find.byType(TextField)).decoration!;
      final theme = Theme.of(tester.element(find.byType(PracticeFormField)));
      expect(
        decoration().helperStyle!.color,
        theme.colorScheme.onSurfaceVariant,
      );
      expect(decoration().helperText, contains('ear-training'));
      await tester.enterText(find.byType(TextField), 'موسیقی');
      await tester.pumpAndSettle();
      expect(decoration().helperStyle!.color, theme.colorScheme.error);
      expect(form.currentState!.validate(), isFalse);
      await tester.enterText(find.byType(TextField), 'EAR-TRAINING');
      await tester.pumpAndSettle();
      expect(controller.text, 'ear-training');
      expect(form.currentState!.validate(), isTrue);
      expect(decoration().helperStyle!.color, Colors.green.shade700);
      expect(decoration().helperText, 'مقدار واردشده قابل قبول است.');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(
        decoration().helperStyle!.color,
        theme.colorScheme.onSurfaceVariant,
      );
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}
