import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Players/ui/components/player_dialog.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('player dialog follows $brightness and selected accent', (
      tester,
    ) async {
      final colors = ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: brightness,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: colors),
          home: Scaffold(
            body: PlayerDialog(
              title: const Text('Title'),
              content: const TextField(),
              actions: [
                PlayerDialogButton(onPressed: () {}, child: const Text('Save')),
                PlayerDialogButton(
                  primary: false,
                  onPressed: () {},
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      );
      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.titleTextStyle!.color, colors.onSurface);
      expect(dialog.contentTextStyle!.color, colors.onSurface);
      expect(dialog.backgroundColor, colors.surface);
      final save = tester.widget<TextButton>(find.byType(TextButton).first);
      expect(save.style!.backgroundColor!.resolve({}), colors.primary);
      expect(save.style!.foregroundColor!.resolve({}), colors.onPrimary);
      expect(tester.takeException(), isNull);
    });
  }
}
