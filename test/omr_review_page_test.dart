import 'dart:io';
import 'development_test_host.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Notation/omr_review_page.dart';

import 'social_widget_test.dart' as fixture;

Future<void> waitForDetection(WidgetTester tester) async {
  for (var attempt = 0; attempt < 300; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
  }
  fail('Image analysis did not finish within 30 seconds.');
}

void main() {
  testWidgets(
    'printed image is analyzed in review UI without inventing durations',
    (tester) async {
      tester.view.physicalSize = const Size(390, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bytes = File('tool/omr_feasibility/treble.png').readAsBytesSync();
      await tester.pumpWidget(
        developmentAdmin(fixture.host(OmrReviewPage(imageBytes: bytes))),
      );
      await tester.tap(find.byIcon(Icons.auto_fix_high));
      await tester.pump();
      await waitForDetection(tester);
      await tester.pump();
      expect(find.text('کشش؟'), findsWidgets);
      expect(find.text('ارتفاع؟'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('blank image keeps review empty and allows retry', (
    tester,
  ) async {
    final bytes = File('tool/omr_feasibility/invalid.png').readAsBytesSync();
    await tester.pumpWidget(
      developmentAdmin(fixture.host(OmrReviewPage(imageBytes: bytes))),
    );
    await tester.tap(find.byIcon(Icons.crop));
    await tester.pumpAndSettle();
    expect(find.text('برش تصویر'), findsOneWidget);
    Navigator.of(tester.element(find.text('برش تصویر'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.auto_fix_high));
    await tester.pump();
    await waitForDetection(tester);
    await tester.pump();
    expect(find.byIcon(Icons.auto_fix_high), findsOneWidget);
    expect(
      find.textContaining('یک حامل پنج‌خطیِ مستقل لازم است'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
