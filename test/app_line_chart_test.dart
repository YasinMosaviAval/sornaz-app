import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sornaz/components/charts/app_line_chart.dart';

void main() {
  testWidgets('native chart handles empty, single zero and non-finite data', (
    tester,
  ) async {
    Future<void> show(List<AppChartPoint> points) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AppLineChart(points: points)),
      ),
    );
    await show([]);
    expect(find.byType(LineChart), findsNothing);
    await show(const [
      AppChartPoint('Only day', 0),
      AppChartPoint('Invalid', double.nan),
    ]);
    await tester.pumpAndSettle();
    final data = tester.widget<LineChart>(find.byType(LineChart)).data;
    expect(data.lineBarsData.single.spots, [const FlSpot(0, 0)]);
    expect(data.maxY, greaterThan(data.minY));
    expect(data.maxX, greaterThan(data.minX));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'chart theme, tooltip radius and actual negative values are preserved',
    (tester) async {
      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        textTheme: const TextTheme(
          labelSmall: TextStyle(
            fontFamily: 'Vazir',
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: AppLineChart(
              points: const [
                AppChartPoint('First', -3),
                AppChartPoint('Last', 7),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final chart = tester.widget<LineChart>(find.byType(LineChart)).data;
      expect(chart.lineBarsData.single.color, theme.colorScheme.primary);
      expect(chart.lineBarsData.single.spots.map((spot) => spot.y), [-3, 7]);
      expect(chart.minY, -3);
      expect(
        chart.lineTouchData.touchTooltipData.tooltipBorderRadius,
        BorderRadius.circular(13),
      );
      final text = tester.widget<Text>(find.text('First'));
      expect(text.style?.fontSize, 17);
      expect(text.style?.fontFamily, 'Vazir');
      expect(text.style?.fontWeight, FontWeight.w600);
      expect(tester.takeException(), isNull);
    },
  );
}
