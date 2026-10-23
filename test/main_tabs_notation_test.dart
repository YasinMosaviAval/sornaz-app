import 'package:sornaz/components/main_tab_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/components/main_tabs.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'social_widget_test.dart' as fixture;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'main destinations swipe, buttons select, back returns home then exits',
    (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        fixture.host(
          MainTabs(
            pages: List.generate(
              5,
              (index) => MainTabScaffold(
                index: index,
                appBar: AppBar(title: Text('header $index')),
                body: Center(child: Text('page $index')),
                bottomNavigationBar: BottomNavBarWidget(selectedIndex: index),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(PageView),
          matching: find.byType(AppBar),
        ),
        findsNothing,
      );
      expect(find.byType(BottomNavBarWidget), findsOneWidget);
      final barRect = tester.getRect(find.byType(BottomNavBarWidget));
      expect(barRect.height, 48);
      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('page 1'), findsOneWidget);
      expect(tester.getRect(find.byType(BottomNavBarWidget)), barRect);
      await tester.tap(find.byIcon(Icons.tune).first);
      await tester.pumpAndSettle();
      expect(find.text('page 3'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('page 0'), findsOneWidget);
      expect(calls, isNot(contains('SystemNavigator.pop')));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(calls, contains('SystemNavigator.pop'));
    },
  );
}
