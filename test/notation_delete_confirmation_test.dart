import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/components/app_dialog.dart';
import 'package:sornaz/screens/Notation/notation_delete_confirmation.dart';
import 'app_delete_dialog_test.dart' show host;

void main() {
  for (final locale in ['fa', 'en']) {
    for (final kind in ['part', 'section', 'subsection']) {
      testWidgets('notation removal confirms and cancels: $locale/$kind', (
        tester,
      ) async {
        bool? result;
        await tester.pumpWidget(
          host(
            Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await confirmNotationStructureDelete(context, kind);
                },
                child: const Text('open'),
              ),
            ),
            locale: locale,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.byType(DeleteConfirmationDialog), findsOneWidget);
        await tester.tap(find.text(locale == 'fa' ? 'انصراف' : 'Cancel'));
        await tester.pumpAndSettle();
        expect(result, false);
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(locale == 'fa' ? 'حذف' : 'Delete'));
        await tester.pumpAndSettle();
        expect(result, true);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
