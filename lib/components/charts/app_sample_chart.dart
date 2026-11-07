import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_line_chart.dart';

typedef SampleChartJson = Map<String, dynamic>;
SampleChartJson sampleObject(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
List<dynamic> sampleList(dynamic value) => value is List ? value : [];
double sampleNumber(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

/// Renders the website gallery's deterministic sample options with native Canvas.
/// No JavaScript, account data or network request is executed by this widget.
class AppSampleChart extends StatefulWidget {
  const AppSampleChart({
    super.key,
    required this.type,
    required this.option,
    required this.translate,
  });
  final String type;
  final SampleChartJson option;
  final String Function(String) translate;
  @override
  State<AppSampleChart> createState() => _AppSampleChartState();
}

class _AppSampleChartState extends State<AppSampleChart> {
  final hidden = <int>{}, collapsed = <String>{};
  final hiddenLabels = <String>{};
  RangeValues range = const RangeValues(0, 18);
  SampleChartJson? root;
  String? selected;

  @override
  void didUpdateWidget(covariant AppSampleChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type || oldWidget.option != widget.option) {
      hidden.clear();
      hiddenLabels.clear();
      collapsed.clear();
      root = null;
      selected = null;
      range = const RangeValues(0, 18);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), option = widget.option;
    final series = sampleList(option['series']).map(sampleObject).toList();
    if (widget.type == 'line' && series.length == 1) {
      final labels = sampleList(sampleObject(option['xAxis'])['data']);
      final values = sampleList(series.first['data']);
      return AppLineChart(
        points: [
          for (var i = 0; i < values.length; i++)
            AppChartPoint(
              widget.translate('${i < labels.length ? labels[i] : i + 1}'),
              sampleNumber(values[i]),
            ),
        ],
        formatValue: (value) => widget.translate('$value'),
      );
    }
    final legends = sampleList(
      option['legend'] is Map ? [option['legend']] : option['legend'],
    );
    final itemLegend = <String>[];
    if (legends.isNotEmpty && series.isNotEmpty) {
      if (['pie', 'radar'].contains(widget.type)) {
        itemLegend.addAll(
          sampleList(series.first['data'])
              .map(sampleObject)
              .where((v) => v['name'] != null)
              .map((v) => '${v['name']}'),
        );
      } else if (widget.type == 'graph') {
        itemLegend.addAll(
          sampleList(
            series.first['categories'],
          ).map(sampleObject).map((v) => '${v['name']}'),
        );
      } else if (widget.type == 'themeRiver') {
        itemLegend.addAll(
          sampleList(
            series.first['data'],
          ).map(sampleList).map((v) => '${v[2]}').toSet(),
        );
      }
    }
    final painter = SampleChartPainter(
      type: widget.type,
      option: option,
      colors: [
        theme.colorScheme.primary,
        Colors.teal,
        Colors.amber,
        Colors.purple,
        Colors.blue,
        Colors.orange,
      ],
      textStyle: theme.textTheme.bodySmall ?? const TextStyle(),
      foreground: theme.colorScheme.onSurface,
      background: theme.colorScheme.surface,
      outline: theme.colorScheme.outlineVariant,
      translate: widget.translate,
      hidden: Set.of(hidden),
      hiddenLabels: Set.of(hiddenLabels),
      collapsed: Set.of(collapsed),
      root: root,
      range: range,
      direction: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    final fa = Localizations.localeOf(context).languageCode == 'fa';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (itemLegend.isNotEmpty)
          Wrap(
            spacing: 8,
            children: [
              for (final label in itemLegend)
                FilterChip(
                  label: Text(widget.translate(label)),
                  selected: !hiddenLabels.contains(label),
                  onSelected: (show) => setState(
                    () => show
                        ? hiddenLabels.remove(label)
                        : hiddenLabels.add(label),
                  ),
                ),
            ],
          ),
        if (legends.isNotEmpty && series.length > 1)
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < series.length; i++)
                if (series[i]['name'] != null)
                  FilterChip(
                    label: Text(widget.translate('${series[i]['name']}')),
                    selected: !hidden.contains(i),
                    onSelected: (show) =>
                        setState(() => show ? hidden.remove(i) : hidden.add(i)),
                  ),
            ],
          ),
        if (root != null)
          TextButton(
            onPressed: () => setState(() => root = null),
            child: Text(fa ? 'بازگشت به کل نمودار' : 'Show complete chart'),
          ),
        Semantics(
          label: fa
              ? 'نمودار نمونه، برای بزرگ‌نمایی دو انگشت را حرکت دهید'
              : 'Sample chart. Pinch to zoom',
          child: SizedBox(
            height: 260,
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: LayoutBuilder(
                builder: (context, bounds) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (event) {
                    final hit = painter.at(event.localPosition);
                    if (hit == null) return;
                    setState(() {
                      selected = hit.label;
                      if (hit.node != null) {
                        if (widget.type == 'tree') {
                          if (!collapsed.remove(hit.label)) {
                            collapsed.add(hit.label);
                          }
                        } else if (sampleList(
                          hit.node!['children'],
                        ).isNotEmpty) {
                          root = hit.node;
                        }
                      }
                    });
                  },
                  child: CustomPaint(
                    key: ValueKey('sample-chart-${widget.type}'),
                    size: Size(bounds.maxWidth, 260),
                    painter: painter,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (sampleObject(option['visualMap'])['calculable'] == true)
          RangeSlider(
            min: 0,
            max: 18,
            divisions: 18,
            values: range,
            labels: RangeLabels(
              '${range.start.toInt()}',
              '${range.end.toInt()}',
            ),
            onChanged: (value) => setState(() => range = value),
          ),
        if (selected != null) Text(selected!, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class SampleChartHit {
  const SampleChartHit(this.bounds, this.label, [this.node]);
  final Rect bounds;
  final String label;
  final SampleChartJson? node;
}

class SampleChartPainter extends CustomPainter {
  SampleChartPainter({
    required this.type,
    required this.option,
    required this.colors,
    required this.textStyle,
    required this.foreground,
    required this.background,
    required this.outline,
    required this.translate,
    required this.hidden,
    required this.hiddenLabels,
    required this.collapsed,
    required this.root,
    required this.range,
    required this.direction,
    required this.textScaler,
  });
  final String type;
  final SampleChartJson option;
  final List<Color> colors;
  final TextStyle textStyle;
  final Color foreground, outline, background;
  final String Function(String) translate;
  final Set<int> hidden;
  final Set<String> hiddenLabels;
  final Set<String> collapsed;
  final SampleChartJson? root;
  final RangeValues range;
  final TextDirection direction;
  final TextScaler textScaler;
  final hits = <SampleChartHit>[];
  late Canvas canvas;
  late Rect plot;
  SampleChartHit? at(Offset point) => hits.reversed
      .where((hit) => hit.bounds.inflate(4).contains(point))
      .firstOrNull;
  Color color(int index) => colors[index % colors.length];
  List<SampleChartJson> get series => sampleList(option['series'])
      .map(sampleObject)
      .indexed
      .where((s) => !hidden.contains(s.$1))
      .map((s) => s.$2)
      .toList();
  void text(String value, Offset at, {double width = 70, Color? ink}) {
    final painter = TextPainter(
      text: TextSpan(
        text: translate(value),
        style: textStyle.copyWith(color: ink ?? foreground),
      ),
      textDirection: direction,
      textScaler: textScaler,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: width);
    painter.paint(canvas, at);
  }

  void line(Offset a, Offset b, Color ink, [double width = 1]) =>
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = ink
          ..strokeWidth = width,
      );
  void box(Rect rect, Color ink, String label, [SampleChartJson? node]) {
    canvas.drawRect(rect, Paint()..color = ink);
    hits.add(SampleChartHit(rect, label, node));
  }

  void dot(
    Offset center,
    double radius,
    Color ink,
    String label, [
    SampleChartJson? node,
  ]) {
    canvas.drawCircle(center, radius, Paint()..color = ink);
    hits.add(
      SampleChartHit(
        Rect.fromCircle(center: center, radius: radius),
        label,
        node,
      ),
    );
  }

  List<double> values(SampleChartJson s) => sampleList(
    s['data'],
  ).map((v) => sampleNumber(v is Map ? v['value'] : v)).toList();
  void axes(List<dynamic> labels, double maximum) {
    for (var i = 0; i <= 4; i++) {
      final y = plot.bottom - plot.height * i / 4;
      line(
        Offset(plot.left, y),
        Offset(plot.right, y),
        outline.withValues(alpha: .45),
      );
      text(
        (maximum * i / 4).toStringAsFixed(maximum < 5 ? 1 : 0),
        Offset(0, y - 7),
        width: 38,
      );
    }
    for (var i = 0; i < labels.length; i++) {
      text(
        '${labels[i]}',
        Offset(
          plot.left + (i + .5) * plot.width / labels.length - 22,
          plot.bottom + 5,
        ),
        width: 50,
      );
    }
  }

  @override
  void paint(Canvas target, Size size) {
    canvas = target;
    hits.clear();
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    plot = Rect.fromLTWH(
      42,
      18,
      math.max(1, size.width - 58),
      size.height - 58,
    );
    if (series.isNotEmpty) {
      switch (type) {
        case 'line':
        case 'area':
        case 'bar':
        case 'pictorialBar':
          cartesian();
        case 'pie':
          pie();
        case 'scatter':
          scatter();
        case 'radar':
          radar();
        case 'gauge':
          gauge();
        case 'funnel':
          funnel();
        case 'heatmap':
          heatmap();
        case 'candlestick':
        case 'boxplot':
          ranges();
        case 'tree':
          hierarchy();
        case 'treemap':
          treemap();
        case 'sunburst':
          sunburst();
        case 'graph':
          graph();
        case 'sankey':
          sankey();
        case 'parallel':
          parallel();
        case 'themeRiver':
          river();
      }
    }
    canvas.restore();
  }

  void cartesian() {
    final rows = series,
        labels = sampleList(sampleObject(option['xAxis'])['data']);
    final length = rows.map((r) => values(r).length).fold<int>(0, math.max);
    if (length == 0) return;
    final stacked = rows.any((s) => s['stack'] != null),
        totals = List.filled(length, 0.0);
    var maximum = 1.0;
    for (final row in rows) {
      for (final entry in values(row).indexed) {
        if (stacked) totals[entry.$1] += entry.$2;
        maximum = math.max(maximum, stacked ? totals[entry.$1] : entry.$2);
      }
    }
    axes(labels, maximum);
    totals.fillRange(0, length, 0);
    for (final entry in rows.indexed) {
      final row = entry.$2, data = values(row), path = Path(), bottom = Path();
      final step = plot.width / length;
      for (var i = 0; i < data.length; i++) {
        final base = stacked ? totals[i] : 0.0;
        final x = plot.left + step * (i + .5),
            y = plot.bottom - (base + data[i]) / maximum * plot.height;
        final name =
            '${translate('${row['name'] ?? (i < labels.length ? labels[i] : '${i + 1}')}')}: ${data[i]}';
        if (type == 'bar') {
          final width = step * .65 / (stacked ? 1 : rows.length);
          box(
            Rect.fromLTWH(
              x - step * .325 + (stacked ? 0 : entry.$1 * width),
              y,
              width - 2,
              math.max(0, plot.bottom - base / maximum * plot.height - y),
            ),
            color(entry.$1),
            name,
          );
        } else if (type == 'pictorialBar') {
          for (var j = 0; j < data[i].toInt(); j++) {
            final rect = Rect.fromLTWH(
              x - 10,
              plot.bottom - (j + 1) * plot.height / maximum,
              20,
              math.max(2, plot.height / maximum - 3),
            );
            if (row['symbolRepeat'] == true) {
              final star = Path();
              for (var p = 0; p < 10; p++) {
                final a = p * math.pi / 5 - math.pi / 2,
                    r = p.isEven ? 9.0 : 4.0;
                final point =
                    rect.center + Offset(math.cos(a) * r, math.sin(a) * r);
                if (p == 0) {
                  star.moveTo(point.dx, point.dy);
                } else {
                  star.lineTo(point.dx, point.dy);
                }
              }
              star.close();
              canvas.drawPath(star, Paint()..color = color(i));
              hits.add(SampleChartHit(rect, name));
            } else {
              box(rect, color(i), name);
            }
          }
        } else {
          if (i == 0) {
            path.moveTo(x, y);
            bottom.moveTo(x, plot.bottom - base / maximum * plot.height);
          } else {
            final previousY =
                plot.bottom -
                (stacked ? totals[i - 1] : data[i - 1]) / maximum * plot.height;
            if (row['step'] != null) {
              path.lineTo(x - step / 2, previousY);
              path.lineTo(x - step / 2, y);
              path.lineTo(x, y);
            } else if (row['smooth'] == true) {
              path.cubicTo(x - step / 2, previousY, x - step / 2, y, x, y);
            } else {
              path.lineTo(x, y);
            }
            bottom.lineTo(x, plot.bottom - base / maximum * plot.height);
          }
          dot(Offset(x, y), 3, color(entry.$1), name);
        }
        if (stacked) totals[i] += data[i];
      }
      if (type == 'line' || type == 'area') {
        if (type == 'area' && data.isNotEmpty) {
          final area = Path.from(path)
            ..lineTo(
              plot.left + step * (data.length - .5),
              plot.bottom -
                  (stacked ? totals[data.length - 1] - data.last : 0) /
                      maximum *
                      plot.height,
            );
          for (var i = data.length - 1; i >= 0; i--) {
            area.lineTo(
              plot.left + step * (i + .5),
              plot.bottom -
                  (stacked ? totals[i] - data[i] : 0) / maximum * plot.height,
            );
          }
          area.close();
          canvas.drawPath(
            area,
            Paint()..color = color(entry.$1).withValues(alpha: .25),
          );
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = color(entry.$1)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  void pie() {
    final row = series.first,
        data = sampleList(row['data'])
            .map(sampleObject)
            .where((d) => !hiddenLabels.contains('${d['name']}'))
            .toList();
    final total = data.fold<double>(0, (n, d) => n + sampleNumber(d['value']));
    if (total <= 0) return;
    final center = plot.center,
        radius = math.min(plot.width, plot.height) * .43;
    var angle = -math.pi / 2;
    for (final entry in data.indexed) {
      final portion = sampleNumber(entry.$2['value']) / total,
          sweep = portion * math.pi * 2;
      final outer = row['roseType'] != null ? radius * (.65 + portion) : radius;
      final ring = row['radius'] is List;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: outer),
          angle,
          sweep,
          false,
        )
        ..close();
      canvas.drawPath(path, Paint()..color = color(entry.$1));
      if (ring) {
        canvas.drawCircle(center, radius * .44, Paint()..color = background);
      }
      final at =
          center +
          Offset(math.cos(angle + sweep / 2), math.sin(angle + sweep / 2)) *
              outer *
              .7;
      dot(
        at,
        2,
        color(entry.$1),
        '${translate('${entry.$2['name']}')}: ${entry.$2['value']} (${(portion * 100).round()}%)',
      );
      hits.add(
        SampleChartHit(
          Rect.fromCircle(center: at, radius: outer * .35),
          '${translate('${entry.$2['name']}')}: ${entry.$2['value']}',
        ),
      );
      text(
        '${entry.$2['name']}',
        Offset(plot.left, plot.top + entry.$1 * 18),
        ink: color(entry.$1),
      );
      angle += sweep;
    }
  }

  void scatter() {
    final points = sampleList(series.first['data']).map(sampleList).toList();
    axes([], 100);
    for (final point in points) {
      if (point.length >= 2) {
        final at = Offset(
          plot.left + sampleNumber(point[0]) / 14 * plot.width,
          plot.bottom - sampleNumber(point[1]) / 100 * plot.height,
        );
        final bubble = series.first['symbolSize'] is Map;
        dot(
          at,
          bubble && point.length > 2 ? 4 + sampleNumber(point[2]) / 6 : 6,
          color(0),
          point.join(' / '),
        );
      }
    }
  }

  void radar() {
    final indicators = sampleList(sampleObject(option['radar'])['indicator']),
        count = indicators.length;
    if (count == 0) return;
    final center = plot.center,
        radius = math.min(plot.width, plot.height) * .38;
    Offset point(int i, double value) =>
        center +
        Offset(
              math.sin(2 * math.pi * i / count),
              -math.cos(2 * math.pi * i / count),
            ) *
            radius *
            value;
    for (var j = 1; j <= 4; j++) {
      final p = Path();
      for (var i = 0; i < count; i++) {
        final a = point(i, j / 4);
        if (i == 0) {
          p.moveTo(a.dx, a.dy);
        } else {
          p.lineTo(a.dx, a.dy);
        }
      }
      p.close();
      canvas.drawPath(
        p,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke,
      );
    }
    for (var i = 0; i < count; i++) {
      line(center, point(i, 1), outline);
      text(
        '${sampleObject(indicators[i])['name']}',
        point(i, 1.1) - const Offset(20, 5),
        width: 64,
      );
    }
    for (final entry
        in sampleList(series.first['data'])
            .map(sampleObject)
            .where((d) => !hiddenLabels.contains('${d['name']}'))
            .indexed) {
      final data = sampleList(entry.$2['value']), p = Path();
      for (var i = 0; i < math.min(data.length, count); i++) {
        final at = point(i, sampleNumber(data[i]) / 100);
        if (i == 0) {
          p.moveTo(at.dx, at.dy);
        } else {
          p.lineTo(at.dx, at.dy);
        }
        dot(
          at,
          3,
          color(entry.$1),
          '${translate('${sampleObject(indicators[i])['name']}')}: ${data[i]}',
        );
      }
      p.close();
      canvas.drawPath(
        p,
        Paint()..color = color(entry.$1).withValues(alpha: .16),
      );
      canvas.drawPath(
        p,
        Paint()
          ..color = color(entry.$1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void gauge() {
    final row = series.first,
        value = sampleNumber(
          sampleObject(sampleList(row['data']).firstOrNull)['value'],
        );
    final radius = math.min(plot.width, plot.height) * .43,
        center = plot.center;
    final start = (360 - sampleNumber(row['startAngle'])) * math.pi / 180,
        sweep =
            (sampleNumber(row['startAngle']) - sampleNumber(row['endAngle'])) *
            math.pi /
            180;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep * value / 100,
      false,
      Paint()
        ..color = color(0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );
    final a = start + sweep * value / 100;
    line(
      center,
      center + Offset(math.cos(a), math.sin(a)) * radius * .75,
      color(0),
      3,
    );
    text('${value.round()}%', center + const Offset(-20, 25));
    hits.add(SampleChartHit(plot, '${value.round()}%'));
  }

  void funnel() {
    final data = sampleList(series.first['data']).map(sampleObject).toList();
    for (final entry in data.indexed) {
      final i = entry.$1,
          width = plot.width * sampleNumber(entry.$2['value']) / 100;
      final next = i + 1 < data.length
          ? plot.width * sampleNumber(data[i + 1]['value']) / 100
          : width * .65;
      final y = plot.top + i * plot.height / data.length,
          h = plot.height / data.length - 3;
      final p = Path()
        ..moveTo(plot.center.dx - width / 2, y)
        ..lineTo(plot.center.dx + width / 2, y)
        ..lineTo(plot.center.dx + next / 2, y + h)
        ..lineTo(plot.center.dx - next / 2, y + h)
        ..close();
      canvas.drawPath(p, Paint()..color = color(i));
      text(
        '${entry.$2['name']}',
        Offset(plot.center.dx - 30, y + 8),
        ink: Colors.white,
      );
      hits.add(
        SampleChartHit(
          Rect.fromLTWH(plot.center.dx - width / 2, y, width, h),
          '${translate('${entry.$2['name']}')}: ${entry.$2['value']}',
        ),
      );
    }
  }

  void heatmap() {
    final xs = sampleList(sampleObject(option['xAxis'])['data']),
        ys = sampleList(sampleObject(option['yAxis'])['data']);
    if (xs.isEmpty || ys.isEmpty) return;
    for (final point in sampleList(series.first['data']).map(sampleList)) {
      if (point.length >= 3) {
        final x = sampleNumber(point[0]).toInt(),
            y = sampleNumber(point[1]).toInt(),
            v = sampleNumber(point[2]);
        final cell = Rect.fromLTWH(
          plot.left + x * plot.width / xs.length,
          plot.bottom - (y + 1) * plot.height / ys.length,
          plot.width / xs.length - 2,
          plot.height / ys.length - 2,
        );
        box(
          cell,
          v < range.start || v > range.end
              ? outline.withValues(alpha: .2)
              : Color.lerp(outline, color(0), v / 18)!,
          '${translate('${xs[x]}')} / ${ys[y]}: $v',
        );
        if (sampleObject(option['visualMap'])['calculable'] == true) {
          text('${v.toInt()}', cell.center - const Offset(5, 7), width: 24);
        }
      }
    }
    for (var i = 0; i < xs.length; i++) {
      text(
        '${xs[i]}',
        Offset(plot.left + i * plot.width / xs.length, plot.bottom + 4),
        width: 40,
      );
    }
    for (var i = 0; i < ys.length; i++) {
      text(
        '${ys[i]}',
        Offset(8, plot.bottom - (i + .5) * plot.height / ys.length - 7),
        width: 28,
      );
    }
  }

  void ranges() {
    final rows = sampleList(series.first['data']).map(sampleList).toList(),
        labels = sampleList(sampleObject(option['xAxis'])['data']);
    final max = rows
        .expand((r) => r)
        .map(sampleNumber)
        .fold<double>(1, math.max);
    axes(labels, max);
    for (final entry in rows.indexed) {
      final v = entry.$2.map(sampleNumber).toList(),
          x = plot.left + (entry.$1 + .5) * plot.width / rows.length,
          w = plot.width / rows.length * .45;
      double y(double n) => plot.bottom - n / max * plot.height;
      final low = type == 'boxplot' ? v[0] : v[2],
          high = type == 'boxplot' ? v[4] : v[3],
          a = type == 'boxplot' ? v[1] : v[0],
          b = type == 'boxplot' ? v[3] : v[1];
      final ink = type == 'boxplot'
          ? color(entry.$1)
          : b >= a
          ? Colors.teal
          : Colors.red;
      line(Offset(x, y(low)), Offset(x, y(high)), ink, 2);
      line(Offset(x - w / 3, y(low)), Offset(x + w / 3, y(low)), ink);
      line(Offset(x - w / 3, y(high)), Offset(x + w / 3, y(high)), ink);
      box(
        Rect.fromLTRB(
          x - w / 2,
          y(math.max(a, b)),
          x + w / 2,
          y(math.min(a, b)),
        ),
        ink.withValues(alpha: .7),
        v.join(' / '),
      );
      if (type == 'boxplot') {
        line(
          Offset(x - w / 2, y(v[2])),
          Offset(x + w / 2, y(v[2])),
          foreground,
          2,
        );
      }
    }
    if (series.length > 1) {
      for (final raw in sampleList(series[1]['data']).map(sampleList)) {
        if (raw.length >= 2) {
          dot(
            Offset(
              plot.left +
                  (sampleNumber(raw[0]) + .5) * plot.width / rows.length,
              plot.bottom - sampleNumber(raw[1]) / max * plot.height,
            ),
            4,
            color(0),
            raw.join(' / '),
          );
        }
      }
    }
  }

  SampleChartJson treeRoot() =>
      root ?? sampleObject(sampleList(series.first['data']).firstOrNull);
  double weight(SampleChartJson node) {
    final children = sampleList(node['children']).map(sampleObject).toList();
    return children.isEmpty
        ? math.max(1, sampleNumber(node['value']))
        : children.fold<double>(0, (n, c) => n + weight(c));
  }

  void hierarchy() {
    final row = series.first, radial = row['layout'] == 'radial';
    final nodes = <({SampleChartJson node, int depth, int parent})>[];
    void add(SampleChartJson node, int depth, int parent) {
      final index = nodes.length;
      nodes.add((node: node, depth: depth, parent: parent));
      if (!collapsed.contains(translate('${node['name']}'))) {
        for (final child in sampleList(node['children'])) {
          add(sampleObject(child), depth + 1, index);
        }
      }
    }

    add(treeRoot(), 0, -1);
    final positions = <Offset>[], levels = <int, int>{};
    for (final node in nodes) {
      levels[node.depth] = (levels[node.depth] ?? 0) + 1;
    }
    final counts = <int, int>{};
    for (final node in nodes) {
      final index = counts.update(node.depth, (n) => n + 1, ifAbsent: () => 0);
      positions.add(
        radial
            ? plot.center +
                  Offset(
                        math.cos(
                          index * math.pi * 2 / (levels[node.depth] ?? 1),
                        ),
                        math.sin(
                          index * math.pi * 2 / (levels[node.depth] ?? 1),
                        ),
                      ) *
                      (node.depth * math.min(plot.width, plot.height) / 6)
            : Offset(
                plot.left + node.depth * plot.width / 3,
                plot.top +
                    (index + .5) * plot.height / (levels[node.depth] ?? 1),
              ),
      );
    }
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i], at = positions[i];
      if (node.parent >= 0) line(positions[node.parent], at, outline, 2);
      dot(
        at,
        6,
        color(node.depth),
        translate('${node.node['name']}'),
        node.node,
      );
      text('${node.node['name']}', at + const Offset(7, -8), width: 65);
    }
  }

  void treemap() {
    void draw(SampleChartJson node, Rect bounds, int depth) {
      final children = sampleList(node['children']).map(sampleObject).toList();
      if (children.isEmpty) {
        box(
          bounds.deflate(2),
          color(depth + hits.length).withValues(alpha: .8),
          '${translate('${node['name']}')}: ${node['value']}',
          node,
        );
        text(
          '${node['name']}',
          bounds.topLeft + const Offset(5, 4),
          width: bounds.width - 8,
        );
        return;
      }
      var offset = 0.0;
      final total = weight(node);
      for (final child in children) {
        final size =
            weight(child) /
            total *
            (depth.isEven ? bounds.width : bounds.height);
        final rect = depth.isEven
            ? Rect.fromLTWH(
                bounds.left + offset,
                bounds.top,
                size,
                bounds.height,
              )
            : Rect.fromLTWH(
                bounds.left,
                bounds.top + offset,
                bounds.width,
                size,
              );
        draw(child, rect, depth + 1);
        offset += size;
      }
      hits.add(
        SampleChartHit(
          Rect.fromLTWH(bounds.left, bounds.top, bounds.width, 16),
          translate('${node['name']}'),
          node,
        ),
      );
    }

    final data =
        root ??
        {'name': 'آموزشگاه', 'children': sampleList(series.first['data'])};
    draw(data, plot, 0);
  }

  void sunburst() {
    final center = plot.center, unit = math.min(plot.width, plot.height) / 6;
    final data = root != null
        ? [root!]
        : sampleList(series.first['data']).map(sampleObject).toList();
    void draw(
      List<SampleChartJson> nodes,
      double angle,
      double sweep,
      int depth,
    ) {
      final total = nodes.fold<double>(0, (n, c) => n + weight(c));
      for (final node in nodes) {
        final arc = sweep * weight(node) / total, radius = (depth + 1) * unit;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - unit / 2),
          angle,
          arc,
          false,
          Paint()
            ..color = color(hits.length)
            ..style = PaintingStyle.stroke
            ..strokeWidth = unit - 2,
        );
        final at =
            center +
            Offset(math.cos(angle + arc / 2), math.sin(angle + arc / 2)) *
                (radius - unit / 2);
        hits.add(
          SampleChartHit(
            Rect.fromCircle(center: at, radius: unit * .4),
            translate('${node['name']}'),
            node,
          ),
        );
        text('${node['name']}', at - const Offset(18, 6), width: 55);
        final children = sampleList(
          node['children'],
        ).map(sampleObject).toList();
        if (children.isNotEmpty && depth < 2) {
          draw(children, angle, arc, depth + 1);
        }
        angle += arc;
      }
    }

    draw(data, -math.pi / 2, 2 * math.pi, 0);
  }

  void graph() {
    final row = series.first,
        nodes = sampleList(row['data']).map(sampleObject).toList(),
        links = sampleList(row['links']).map(sampleObject).toList();
    final positions = [
      for (var i = 0; i < nodes.length; i++)
        plot.center +
            Offset(
                  math.cos(i * 2 * math.pi / nodes.length),
                  math.sin(i * 2 * math.pi / nodes.length),
                ) *
                math.min(plot.width, plot.height) *
                .35,
    ];
    if (row['layout'] == 'force') {
      for (var iteration = 0; iteration < 40; iteration++) {
        for (var i = 0; i < positions.length; i++) {
          var force = Offset.zero;
          for (var j = 0; j < positions.length; j++) {
            if (j != i) {
              final delta = positions[i] - positions[j],
                  dist = math.max(10.0, delta.distance);
              force += delta / dist * (100 / dist);
            }
          }
          for (final link in links) {
            final a = sampleNumber(link['source']).toInt(),
                b = sampleNumber(link['target']).toInt();
            if (i == a || i == b) {
              force += (positions[i == a ? b : a] - positions[i]) * .02;
            }
          }
          final next = positions[i] + force;
          positions[i] = Offset(
            next.dx.clamp(plot.left + 15, plot.right - 15),
            next.dy.clamp(plot.top + 15, plot.bottom - 15),
          );
        }
      }
    }
    final categories = sampleList(row['categories']).map(sampleObject).toList();
    bool visible(dynamic index) => !hiddenLabels.contains(
      '${categories[sampleNumber(nodes[sampleNumber(index).toInt()]['category']).toInt()]['name']}',
    );
    for (final edge in links) {
      if (!visible(edge['source']) || !visible(edge['target'])) continue;
      line(
        positions[sampleNumber(edge['source']).toInt()],
        positions[sampleNumber(edge['target']).toInt()],
        outline,
        2,
      );
    }
    for (var i = 0; i < nodes.length; i++) {
      if (!visible(i)) continue;
      dot(
        positions[i],
        sampleNumber(nodes[i]['symbolSize']) / 2,
        color(sampleNumber(nodes[i]['category']).toInt()),
        '${translate('${nodes[i]['name']}')}: ${nodes[i]['value']}',
      );
      text(
        '${nodes[i]['name']}',
        positions[i] - const Offset(15, 7),
        width: 45,
      );
    }
  }

  void sankey() {
    final row = series.first,
        nodes = sampleList(row['data']).map(sampleObject).toList(),
        links = sampleList(row['links']).map(sampleObject).toList();
    final names = [for (final node in nodes) '${node['name']}'];
    final positions = <String, Offset>{
      for (var i = 0; i < names.length; i++)
        names[i]: Offset(
          plot.left + plot.width * math.min(i, 3) / 3,
          i == 4 ? plot.bottom - 20 : plot.top + 30,
        ),
    };
    for (final edge in links) {
      final a = positions['${edge['source']}']!,
          b = positions['${edge['target']}']!,
          p = Path()
            ..moveTo(a.dx, a.dy)
            ..cubicTo(
              (a.dx + b.dx) / 2,
              a.dy,
              (a.dx + b.dx) / 2,
              b.dy,
              b.dx,
              b.dy,
            );
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, sampleNumber(edge['value']) / 5);
      if (row['layoutIterations'] == 0) {
        paint.color = color(
          names.indexOf('${edge['source']}'),
        ).withValues(alpha: .5);
      } else {
        paint.shader = LinearGradient(
          colors: [
            color(names.indexOf('${edge['source']}')),
            color(names.indexOf('${edge['target']}')),
          ],
        ).createShader(Rect.fromPoints(a, b).inflate(1));
      }
      canvas.drawPath(p, paint);
      hits.add(
        SampleChartHit(
          Rect.fromCenter(center: (a + b) / 2, width: 25, height: 25),
          '${translate('${edge['source']}')} → ${translate('${edge['target']}')}: ${edge['value']}',
        ),
      );
    }
    for (final entry in positions.entries) {
      box(
        Rect.fromCenter(center: entry.value, width: 10, height: 40),
        color(names.indexOf(entry.key)),
        translate(entry.key),
      );
      text(entry.key, entry.value + const Offset(-25, 25), width: 65);
    }
  }

  void parallel() {
    final axesData = sampleList(option['parallelAxis']);
    if (axesData.isEmpty) return;
    for (var i = 0; i < axesData.length; i++) {
      final x = plot.left + i * plot.width / (axesData.length - 1);
      line(Offset(x, plot.top), Offset(x, plot.bottom), outline);
      text(
        '${sampleObject(axesData[i])['name']}',
        Offset(x - 20, plot.bottom + 4),
        width: 60,
      );
    }
    for (final entry in sampleList(
      series.first['data'],
    ).map(sampleList).indexed) {
      final path = Path();
      for (var i = 0; i < entry.$2.length; i++) {
        final at = Offset(
          plot.left + i * plot.width / (axesData.length - 1),
          plot.bottom - sampleNumber(entry.$2[i]) / 100 * plot.height,
        );
        if (i == 0) {
          path.moveTo(at.dx, at.dy);
        } else {
          path.lineTo(at.dx, at.dy);
        }
        dot(
          at,
          3,
          color(entry.$1),
          '${translate('${sampleObject(axesData[i])['name']}')}: ${entry.$2[i]}',
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = color(entry.$1)
          ..strokeWidth = sampleNumber(
            sampleObject(series.first['lineStyle'])['width'],
          ),
      );
    }
  }

  void river() {
    final data = sampleList(
      series.first['data'],
    ).map(sampleList).where((v) => !hiddenLabels.contains('${v[2]}')).toList();
    final topics = data.map((v) => '${v[2]}').toSet().toList(),
        dates = data.map((v) => '${v[0]}').toSet().toList();
    final totals = [
      for (final date in dates)
        data
            .where((r) => '${r[0]}' == date)
            .fold<double>(0, (n, r) => n + sampleNumber(r[1])),
    ];
    final maximum = totals.fold<double>(1, math.max),
        bases = [for (final total in totals) (maximum - total) / 2];
    for (final entry in topics.indexed) {
      final values = [
            for (final date in dates)
              data
                  .where((r) => '${r[0]}' == date && '${r[2]}' == entry.$2)
                  .fold<double>(0, (n, r) => n + sampleNumber(r[1])),
          ],
          p = Path();
      for (var i = 0; i < dates.length; i++) {
        final x = plot.left + i * plot.width / (dates.length - 1),
            y = plot.bottom - (bases[i] + values[i]) / maximum * plot.height;
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      for (var i = dates.length - 1; i >= 0; i--) {
        p.lineTo(
          plot.left + i * plot.width / (dates.length - 1),
          plot.bottom - bases[i] / maximum * plot.height,
        );
      }
      p.close();
      canvas.drawPath(
        p,
        Paint()..color = color(entry.$1).withValues(alpha: .75),
      );
      for (var i = 0; i < dates.length; i++) {
        dot(
          Offset(
            plot.left + i * plot.width / (dates.length - 1),
            plot.bottom - (bases[i] + values[i] / 2) / maximum * plot.height,
          ),
          3,
          color(entry.$1),
          '${translate(entry.$2)} / ${dates[i]}: ${values[i]}',
        );
        bases[i] += values[i];
      }
      text(
        entry.$2,
        Offset(plot.left, plot.top + entry.$1 * 18),
        ink: color(entry.$1),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SampleChartPainter oldDelegate) => true;
}
