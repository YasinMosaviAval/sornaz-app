import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../helpers/app_appearance.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_insight_data.dart';
import 'panel_parity.dart';
import 'panel_section_card.dart';

/// The same authorized, filtered rows as the table, before local pagination.
class PanelInsightCharts extends StatefulWidget {
  const PanelInsightCharts({
    super.key,
    required this.section,
    required this.rows,
    required this.data,
    this.weekly = false,
    this.contractType = '',
  });
  final String section, contractType;
  final List<Json> rows;
  final Json data;
  final bool weekly;
  @override
  State<PanelInsightCharts> createState() => _PanelInsightChartsState();
}

class _PanelInsightChartsState extends State<PanelInsightCharts> {
  final boundary = GlobalKey();
  bool exporting = false;
  RangeValues? heatRange;
  String t(String fa, String en) => socialText(context, fa, en);
  bool get fa => Localizations.localeOf(context).languageCode == 'fa';
  String n(num value) => panelNumber(value, fa: fa);
  List<Color> get palette => [
    Theme.of(context).colorScheme.primary,
    Colors.teal,
    Colors.amber,
    Colors.purple,
    Colors.blue,
    Colors.orange,
  ];

  Future<void> export() async {
    if (exporting) return;
    setState(() => exporting = true);
    ui.Image? image;
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final render = boundary.currentContext?.findRenderObject();
      if (render is! RenderRepaintBoundary) return;
      image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final png = bytes.buffer.asUint8List();
      final path = await FilePicker.platform.saveFile(
        fileName: '${widget.section}-chart.png',
        bytes: png,
      );
      if (path != null &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        await File(path).writeAsBytes(png);
      }
    } catch (error) {
      if (mounted) socialError(context, error);
    } finally {
      image?.dispose();
      if (mounted) setState(() => exporting = false);
    }
  }

  String label(String key) {
    const labels = {
      'general': ('عمومی', 'General'),
      'professional': ('حرفه‌ای', 'Professional'),
      'specialized': ('تخصصی', 'Specialized'),
      'teacher': ('مدرس', 'Teacher'),
      'receptionist': ('پذیرش', 'Receptionist'),
      'manager': ('مدیر', 'Manager'),
      'owner': ('مالک', 'Owner'),
      'other': ('سایر', 'Other'),
    };
    final names = labels[key];
    return names == null ? key : t(names.$1, names.$2);
  }

  Widget empty() => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(t('داده‌ای مطابق فیلترها یافت نشد.', 'No matching data.')),
  );

  Widget pie(PanelDistribution value, {bool donut = false}) {
    final entries = value.values.entries.toList();
    final total = entries.fold<double>(0, (sum, entry) => sum + entry.value);
    return Column(
      children: [
        if (total == 0)
          empty()
        else
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: donut ? 48 : 0,
                sectionsSpace: 2,
                sections: [
                  for (final entry in entries.indexed)
                    PieChartSectionData(
                      value: entry.$2.value,
                      color: palette[entry.$1 % palette.length],
                      radius: donut ? 55 : 90,
                      title: entry.$2.value == 0
                          ? ''
                          : '${n(entry.$2.value)}\n${n((entry.$2.value * 100 / total).round())}%',
                      titleStyle: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(
                            color:
                                ThemeData.estimateBrightnessForColor(
                                      palette[entry.$1 % palette.length],
                                    ) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                    ),
                ],
              ),
              duration: Duration.zero,
            ),
          ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final entry in entries.indexed)
              Text(
                '${label(entry.$2.key)}: ${n(entry.$2.value)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette[entry.$1 % palette.length],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget lessons(PanelLessonDistribution data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t(
            '${n(data.counted)} مورد · ${n(data.unknown)} با شیوه نامشخص',
            '${n(data.counted)} records · ${n(data.unknown)} with unknown mode',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          children: [
            Text(t('حضوری', 'In person'), style: TextStyle(color: palette[0])),
            Text(t('آنلاین', 'Online'), style: TextStyle(color: palette[1])),
          ],
        ),
        if (data.groups.isEmpty)
          empty()
        else
          LayoutBuilder(
            builder: (context, size) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: math.max(size.maxWidth, data.groups.length * 100.0),
                  height: 280,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      minY: 0,
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, _) =>
                                value == value.roundToDouble()
                                ? Text(
                                    n(value),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 56,
                            getTitlesWidget: (value, _) => SizedBox(
                              width: 90,
                              child: Text(
                                data.groups[value.toInt()].name,
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          getTooltipItem: (group, index, rod, rodIndex) =>
                              BarTooltipItem(
                                '${data.groups[index].name}\n${rodIndex == 0 ? t('حضوری', 'In person') : t('آنلاین', 'Online')}: ${n(rod.toY)}',
                                Theme.of(context).textTheme.bodySmall ??
                                    const TextStyle(),
                              ),
                        ),
                      ),
                      barGroups: [
                        for (final entry in data.groups.indexed)
                          BarChartGroupData(
                            x: entry.$1,
                            barRods: [
                              BarChartRodData(
                                toY: entry.$2.inPerson.length.toDouble(),
                                color: palette[0],
                                width: 22,
                                borderRadius: appRadius(context),
                              ),
                              BarChartRodData(
                                toY: entry.$2.online.length.toDouble(),
                                color: palette[1],
                                width: 22,
                                borderRadius: appRadius(context),
                              ),
                            ],
                          ),
                      ],
                      borderData: FlBorderData(show: false),
                    ),
                    duration: Duration.zero,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget heatmap() {
    final occupancy = widget.section == 'classrooms';
    if (!widget.weekly && widget.data['_panelHeatmap'] is! List) {
      return Text(
        widget.data['_panelHeatmapError'] == true
            ? t(
                'دریافت آمار نقشه حرارتی ناموفق بود. دوباره تازه‌سازی کنید.',
                'Heatmap could not be loaded. Refresh to retry.',
              )
            : t(
                'برای آمار کامل نقشه حرارتی، API پنل باید به‌روز شود.',
                'Update the panel API to load the complete heatmap.',
              ),
      );
    }
    final data = occupancy
        ? panelClassroomHeatmap(
            widget.rows,
            objects(widget.data['_panelHeatmap']),
          )
        : panelHeatmapData(
            widget.weekly ? widget.rows : objects(widget.data['_panelHeatmap']),
          );
    final available = widget.rows
        .where((room) => room['statusValue'] == 'available')
        .length;
    final maxValue = data.cells
        .expand((row) => row)
        .fold<int>(1, math.max)
        .toDouble();
    final range = RangeValues(
      (heatRange?.start ?? 0).clamp(0, maxValue),
      (heatRange?.end ?? maxValue).clamp(0, maxValue),
    );
    final days = fa
        ? ['شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه']
        : ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (occupancy) Text('${widget.data['_occupancyWeek'] ?? ''}'),
        Text(
          t(
            occupancy
                ? '${n(available)} کلاس در دسترس · ${n(widget.rows.length - available)} خارج از دسترس/در انتظار'
                : '${n(data.sessions)} جلسه مستقل · ${n(data.unknown)} زمان نامشخص',
            occupancy
                ? '${n(available)} available classrooms · ${n(widget.rows.length - available)} unavailable/pending'
                : '${n(data.sessions)} distinct sessions · ${n(data.unknown)} with invalid time',
          ),
        ),
        Text(
          t(
            occupancy
                ? 'هر سلول تعداد کلاس‌های پر است. صفر یعنی بدون رزرو، نه تضمین امکان رزرو؛ تعطیلی و ساعات کاری لحاظ نمی‌شوند.'
                : 'جلسه چندساعته در چند سلول شمرده می‌شود.',
            occupancy
                ? 'Cells count occupied classrooms. Zero means no booking, not guaranteed availability; closures and working hours are not included.'
                : 'A multi-hour session appears in multiple cells.',
          ),
        ),
        if (occupancy ? widget.rows.isEmpty : data.sessions == 0)
          empty()
        else ...[
          Text(
            t(
              'دامنه رنگ: ${n(range.start)} تا ${n(range.end)}',
              'Color range: ${n(range.start)} to ${n(range.end)}',
            ),
          ),
          RangeSlider(
            values: range,
            max: maxValue,
            divisions: math.min(100, maxValue.ceil()),
            labels: RangeLabels(n(range.start), n(range.end)),
            onChanged: (value) => setState(() => heatRange = value),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 560,
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 56),
                      for (final day in days)
                        Expanded(
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                  for (var hour = 0; hour < 24; hour++)
                    Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        for (var day = 0; day < 7; day++)
                          Expanded(
                            child: Tooltip(
                              message:
                                  '${days[day]} ${hour.toString().padLeft(2, '0')}:00 · ${n(data.cells[day][hour])}${occupancy ? t(' کلاس پر · ${n(available - data.cells[day][hour])} بدون رزرو', ' occupied · ${n(available - data.cells[day][hour])} without bookings') : ''}',
                              child: Container(
                                height: 28,
                                margin: const EdgeInsets.all(1),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: appRadius(context),
                                  color: Color.lerp(
                                    colors.surfaceContainerHighest,
                                    colors.primary,
                                    data.cells[day][hour] == 0
                                        ? 0
                                        : ((data.cells[day][hour] -
                                                      range.start) /
                                                  math.max(
                                                    1,
                                                    range.end - range.start,
                                                  ))
                                              .clamp(0, 1),
                                  ),
                                ),
                                child: Text(
                                  n(data.cells[day][hour]),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color:
                                            data.cells[day][hour] >=
                                                    range.end &&
                                                data.cells[day][hour] > 0
                                            ? colors.onPrimary
                                            : colors.onSurface,
                                      ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (![
      'students',
      'members',
      'terms',
      'my-points',
      'schedules',
      'classrooms',
    ].contains(widget.section)) {
      return const SizedBox.shrink();
    }
    final title = switch (widget.section) {
      'members' => t('نمودار نوع قراردادها', 'Contract types'),
      'students' => t(
        'هنرجویان بر اساس درس و شیوه برگزاری',
        'Students by lesson and attendance mode',
      ),
      'terms' => t(
        'ترم‌های هنرجودار بر اساس درس و شیوه برگزاری',
        'Student terms by lesson and attendance mode',
      ),
      'my-points' => t('نمودار امتیازهای من', 'My point balances'),
      'classrooms' => t(
        'نقشه حرارتی پر و خالی کلاس‌ها',
        'Classroom occupancy heatmap',
      ),
      _ => t('نقشه حرارتی تقویم کلاس‌ها', 'Class calendar heatmap'),
    };
    Widget content;
    if (['schedules', 'classrooms'].contains(widget.section)) {
      content = heatmap();
    } else if (['students', 'terms'].contains(widget.section)) {
      content = lessons(
        panelLessonDistribution(
          widget.section,
          widget.rows,
          widget.data,
          unknownLesson: t('درس نامشخص', 'Unknown lesson'),
        ),
      );
    } else {
      final value = widget.section == 'members'
          ? panelContractDistribution(widget.rows, type: widget.contractType)
          : panelPointDistribution(optionalObject(widget.data['balance']));
      content = Column(
        children: [
          if (widget.section == 'members')
            Text(
              t(
                '${n(value.people)} شخص یکتا؛ هر نوع قرارداد یک‌بار برای هر شخص.',
                '${n(value.people)} distinct people; each person counts once per contract type.',
              ),
            ),
          if (value.negative)
            Text(
              t(
                'موجودی منفی در سهم نمودار نمایش داده نمی‌شود؛ موجودی اصلی تغییر نکرده است.',
                'Negative balances are excluded from pie shares; actual balances are unchanged.',
              ),
            ),
          pie(value),
          if (widget.section == 'members') pie(value, donut: true),
        ],
      );
    }
    return PanelSectionCard(
      title: title,
      storageId: 'insight-${widget.section}',
      icon: Icons.bar_chart,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  tooltip: t('ذخیره نمودار PNG', 'Save chart as PNG'),
                  onPressed:
                      exporting ||
                          ([
                                'schedules',
                                'classrooms',
                              ].contains(widget.section) &&
                              !widget.weekly &&
                              widget.data['_panelHeatmap'] is! List)
                      ? null
                      : export,
                  icon: const Icon(Icons.image_outlined),
                ),
              ),
              RepaintBoundary(
                key: boundary,
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: content,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
