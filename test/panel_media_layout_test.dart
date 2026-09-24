import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/components/media_dialogs.dart';
import 'package:sornaz/screens/Social/member_grid.dart';
import 'package:sornaz/screens/Social/media_picker.dart';

void main() {
  testWidgets(
    'member grid keeps photos and toggles selection in three columns',
    (tester) async {
      final selected = <String>{};
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, update) => MemberGrid(
                users: List.generate(4, (i) => {'id': i, 'username': 'user$i'}),
                selected: selected,
                onToggle: (id) => update(() {
                  if (!selected.remove(id)) selected.add(id);
                }),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('user0')).dy,
        tester.getTopLeft(find.text('user2')).dy,
      );
      expect(
        tester.getTopLeft(find.text('user3')).dy,
        greaterThan(tester.getTopLeft(find.text('user0')).dy),
      );
      await tester.tap(find.text('user1'));
      await tester.pump();
      expect(selected, {'1'});
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsNWidgets(4));
      await tester.tap(find.text('user1'));
      await tester.pump();
      expect(selected, isEmpty);
    },
  );
  testWidgets('rename is prefilled and saves trimmed text without a new page', (
    tester,
  ) async {
    String? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                saved = await renameMediaDialog(context, 'Original');
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Original'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '  Updated  ');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(saved, 'Updated');
    expect(find.byType(AlertDialog), findsNothing);
  });
  testWidgets('crop editor changes aspect ratio and resets zoom', (
    tester,
  ) async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aRZkAAAAASUVORK5CYII=',
    );
    await tester.pumpWidget(MaterialApp(home: ImageCropPage(bytes: bytes)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('16:9'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<AspectRatio>(find.byType(AspectRatio)).aspectRatio,
      16 / 9,
    );
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    viewer.transformationController!.value = Matrix4.diagonal3Values(2, 2, 1);
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    expect(viewer.transformationController!.value, Matrix4.identity());
    expect(tester.takeException(), isNull);
  });
}
