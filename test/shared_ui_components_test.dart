import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/components/app_async_state.dart';
import 'package:sornaz/components/app_text_input_dialog.dart';
import 'package:sornaz/components/app_view_mode_selector.dart';
import 'package:sornaz/components/settings_switch_tile.dart';
import 'package:sornaz/components/media_dialogs.dart';
import 'package:sornaz/screens/Notation/notation_list_dialog.dart';
import 'package:sornaz/screens/Voice%20Recorder/ui/pages/recordings_list.dart';

Widget host(Widget child, {bool dark = false, String language = 'en'}) =>
    MaterialApp(
      locale: Locale(language),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: dark ? Brightness.dark : Brightness.light,
        ),
        fontFamily: 'SelectedFont',
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
      home: Scaffold(body: child),
    );

void main() {
  for (final dark in [false, true]) {
    for (final language in ['fa', 'en']) {
      testWidgets(
        'empty/error states share typography and retry at $language/$dark',
        (tester) async {
          tester.view.physicalSize = const Size(320, 340);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var retries = 0;
          await tester.pumpWidget(
            host(
              AppErrorState(
                message: List.filled(16, 'Server unavailable').join(' '),
                onRetry: () => retries++,
              ),
              dark: dark,
              language: language,
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(AppEmptyState), findsOneWidget);
          expect(
            tester.widget<Icon>(find.byIcon(Icons.error_outline)).color,
            Theme.of(
              tester.element(find.byType(AppErrorState)),
            ).colorScheme.error,
          );
          final retry = find.text(language == 'fa' ? 'تلاش دوباره' : 'Retry');
          await tester.ensureVisible(retry);
          await tester.tap(retry);
          await tester.pump();
          expect(retries, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('shared loading keeps semantics and a bounded inline size', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const AppLoadingIndicator(
          centered: false,
          size: 20,
          label: 'Loading lessons',
        ),
      ),
    );
    expect(find.bySemanticsLabel('Loading lessons'), findsOneWidget);
    expect(
      tester.getSize(find.byType(CircularProgressIndicator)),
      const Size(20, 20),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'settings switch toggles once and respects disabled/null callbacks',
    (tester) async {
      var value = false, changes = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => SettingsSwitchTile(
              title: 'Setting',
              subtitle: 'Description',
              value: value,
              onChanged: (v) => setState(() {
                value = v;
                changes++;
              }),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Setting'));
      await tester.pumpAndSettle();
      expect(value, true);
      expect(changes, 1);
      await tester.pumpWidget(
        host(
          SettingsSwitchTile.widgets(
            title: const Text('Read only'),
            value: true,
            onChanged: null,
          ),
        ),
      );
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNull,
      );
      await tester.tap(find.text('Read only'));
      await tester.pumpAndSettle();
      expect(changes, 1);
      await tester.pumpWidget(
        host(
          SettingsSwitchTile(
            title: 'Disabled',
            subtitle: '',
            value: false,
            enabled: false,
            onChanged: (_) => changes++,
          ),
        ),
      );
      await tester.tap(find.text('Disabled'));
      await tester.pumpAndSettle();
      expect(changes, 1);
    },
  );
  testWidgets('settings switch retains an ink surface inside colored groups',(tester) async {
    var changes=0;
    await tester.pumpWidget(host(Container(color:Colors.amber,child:SettingsSwitchTile(title:'Grouped setting',subtitle:'Description',value:false,onChanged:(_)=>changes++))));
    await tester.tap(find.text('Grouped setting'));await tester.pumpAndSettle();
    expect(changes,1);expect(tester.takeException(),isNull);
  });
  for (final dark in [false, true]) {
    testWidgets(
      'view selection uses theme/radius and emits the selected value: $dark',
      (tester) async {
        bool? selected;
        await tester.pumpWidget(
          host(
            AppViewModeSelector<bool>(
              value: false,
              options: const [
                AppViewMode(
                  value: false,
                  label: 'Table',
                  icon: Icons.table_chart_outlined,
                ),
                AppViewMode(value: true, label: 'Cards', icon: Icons.grid_view),
              ],
              onChanged: (v) => selected = v,
            ),
            dark: dark,
          ),
        );
        final table = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Table'),
        );
        final colors = Theme.of(
          tester.element(find.byType(AppViewModeSelector<bool>)),
        ).colorScheme;
        expect(
          table.style!.backgroundColor!.resolve({}),
          colors.primaryContainer,
        );
        expect(
          (table.style!.shape!.resolve({})! as RoundedRectangleBorder)
              .borderRadius,
          BorderRadius.circular(11),
        );
        await tester.tap(find.text('Cards'));
        expect(selected, true);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('name dialog validates trimmed input and submits from keyboard', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (c) => TextButton(
            onPressed: () async {
              result = await showTextInputDialog(
                c,
                title: 'Name',
                initialValue: 'Previous',
                validator: (v) => v == 'reserved' ? 'Already used' : null,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Previous'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.pump();
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Save'))
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextFormField), 'reserved');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Already used'), findsOneWidget);
    expect(result, isNull);
    await tester.enterText(find.byType(TextFormField), '  New name  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(result, 'New name');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'rename, notation and recorder entry points use the same name dialog',
    (tester) async {
      final entries = <Future<String?> Function(BuildContext)>[
        (c) => renameMediaDialog(c, 'Old'),
        createNotationList,
        (c) => recordingNameDialog(c, 'Recording', 'Old'),
      ];
      for (final entry in entries) {
        bool completed = false;
        String? result;
        await tester.pumpWidget(
          host(
            Builder(
              builder: (c) => TextButton(
                onPressed: () async {
                  result = await entry(c);
                  completed = true;
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byType(AppTextInputDialog), findsOneWidget);
        await tester.enterText(find.byType(TextFormField), 'Unsaved');
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(completed, true);
        expect(result, isNull);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
