import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_appearance.dart';

class AppChartPoint {
  const AppChartPoint(this.label, this.value);
  final String label;
  final double value;
}

/// Native chart adapter: typography and colors follow the main app theme.
class AppLineChart extends StatelessWidget {
  const AppLineChart({super.key, required this.points, this.formatValue});
  final List<AppChartPoint> points;
  final String Function(double value)? formatValue;

  @override
  Widget build(BuildContext context) {
    final valid = points.where((point) => point.value.isFinite).toList();
    if (valid.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final minimum = valid.fold<double>(
      0,
      (value, point) => point.value < value ? point.value : value,
    );
    final maximum = valid.fold<double>(
      0,
      (value, point) => point.value > value ? point.value : value,
    );
    final interval = valid.length < 5
        ? 1.0
        : ((valid.length - 1) / 4).ceilToDouble();
    final tooltipStyle =
        theme.textTheme.bodySmall?.copyWith(color: colors.onSurface) ??
        TextStyle(color: colors.onSurface);
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: valid.length == 1 ? -1 : 0,
          maxX: valid.length == 1 ? 1 : (valid.length - 1).toDouble(),
          minY: minimum,
          maxY: maximum == minimum ? minimum + 1 : maximum,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: colors.outlineVariant, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (value != index.toDouble() ||
                      index < 0 ||
                      index >= valid.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      valid[index].label,
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBorderRadius: appRadius(context),
              getTooltipColor: (_) => colors.surfaceContainerHighest,
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    '${valid[spot.x.toInt()].label}\n${formatValue?.call(spot.y) ?? spot.y.toString()}',
                    tooltipStyle,
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (final entry in valid.indexed)
                  FlSpot(entry.$1.toDouble(), entry.$2.value),
              ],
              color: colors.primary,
              barWidth: 2,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: colors.primary.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}
