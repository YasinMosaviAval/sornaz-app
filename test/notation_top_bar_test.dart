import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Notation/notation_top_bar.dart';
import 'social_widget_test.dart' as fixture;

void main() {
  testWidgets(
    'notation actions share the top bar and dispatch editor commands',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final actions = <String>[];
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            appBar: NotationTopBar(
              editor: true,
              signedIn: true,
              data: const {'editable': true, 'playing': false},
              command: actions.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<AppBar>(find.byType(AppBar)).bottom, isNull);
      expect(find.byIcon(Icons.file_download_outlined), findsNothing);
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNothing);
      for (final icon in [
        Icons.save_outlined,
        Icons.play_arrow,
        Icons.edit_outlined,
      ]) {
        expect(
          tester.getCenter(find.byIcon(icon)).dy,
          tester.getCenter(find.byType(BackButton)).dy,
        );
        await tester.tap(find.byIcon(icon));
      }
      expect(actions, ['save', 'play', 'metadata']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        fixture.host(
          Scaffold(
            appBar: NotationTopBar(
              editor: true,
              signedIn: false,
              data: const {'editable': false, 'playing': true},
              command: actions.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.save_outlined), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.pause), findsOneWidget);
    },
  );
}
