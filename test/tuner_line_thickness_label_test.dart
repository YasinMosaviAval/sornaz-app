import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/screens/Metronome/ui/components/labeled_slider.dart';

void main() {
  testWidgets('fractional slider value is preserved in its popup label', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppData(),
        child: MaterialApp(
          home: Scaffold(
            body: LabeledSlider(
              leadingIcon: const Icon(Icons.line_weight),
              label: 'Thickness: 1.5',
              value: 1.5,
              min: 1,
              max: 3,
              divisions: 20,
              isDark: false,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(tester.widget<Slider>(find.byType(Slider)).label, '1.5');
  });
}
