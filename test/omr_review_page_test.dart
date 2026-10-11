import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/screens/Notation/omr_review_page.dart';

import 'social_widget_test.dart' as fixture;

void main() {
  testWidgets('printed image is analyzed in review UI without inventing durations',
      (tester) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bytes = File('tool/omr_feasibility/treble.png').readAsBytesSync();
    await tester.pumpWidget(fixture.host(OmrReviewPage(imageBytes: bytes)));
    await tester.tap(find.byIcon(Icons.auto_fix_high));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 3));
    });
    await tester.pump();
    expect(find.text('کشش؟'), findsWidgets);
    expect(find.text('ارتفاع؟'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blank image keeps review empty and allows retry', (tester) async {
    final bytes = File('tool/omr_feasibility/invalid.png').readAsBytesSync();
    await tester.pumpWidget(fixture.host(OmrReviewPage(imageBytes: bytes)));
    await tester.tap(find.byIcon(Icons.auto_fix_high));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 3));
    });
    await tester.pump();
    expect(find.byIcon(Icons.auto_fix_high), findsOneWidget);
    expect(find.textContaining('فقط تصویر نت'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
