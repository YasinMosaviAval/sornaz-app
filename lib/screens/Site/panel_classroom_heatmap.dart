import 'package:flutter/material.dart';
import '../../helpers/app_appearance.dart';
import '../../components/jalali_date_picker.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_api.dart';
import 'panel_insight_charts.dart';

class PanelClassroomHeatmap extends StatefulWidget {
  const PanelClassroomHeatmap({
    super.key,
    required this.api,
    required this.rooms,
    required this.enabled,
    required this.refreshKey,
  });
  final PanelApi api;
  final List<Json> rooms;
  final bool enabled;
  final Object refreshKey;
  @override
  State<PanelClassroomHeatmap> createState() => _PanelClassroomHeatmapState();
}

class _PanelClassroomHeatmapState extends State<PanelClassroomHeatmap> {
  late DateTime week;
  Json data = {};
  String selected = '';
  bool loading = false;
  int generation = 0;
  String t(String fa, String en) => socialText(context, fa, en);
  String iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    week = DateTime(now.year, now.month, now.day - ((now.weekday + 1) % 7));
    load();
  }

  @override
  void didUpdateWidget(covariant PanelClassroomHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey ||
        oldWidget.enabled != widget.enabled ||
        oldWidget.api != widget.api) {
      load(refresh: true);
    }
  }

  Future<void> load({bool refresh = false}) async {
    final request = ++generation;
    if (!widget.enabled) {
      data = {};
      loading = false;
      return;
    }
    setState(() {
      loading = true;
      data = {};
    });
    try {
      final result = await (refresh ? widget.api.refresh : widget.api.get)(
        '/classrooms/heatmap',
        {'week': iso(week)},
      );
      if (!mounted || request != generation) return;
      if (result['heatmap'] is! List) {
        throw const SocialException('Invalid heatmap response.');
      }
      setState(() {
        data = {'_panelHeatmap': result['heatmap']};
        loading = false;
      });
    } catch (_) {
      if (mounted && request == generation) {
        setState(() {
          data = {'_panelHeatmapError': true};
          loading = false;
        });
      }
    }
  }

  void move(int days) {
    setState(() {
      week = DateTime(week.year, week.month, week.day + days);
    });
    load();
  }

  Future<void> pickWeek() async {
    final date = await showSornazDatePicker(
      context: context,
      initialDate: week,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (date == null || !mounted) return;
    setState(() {
      week = DateTime(
        date.year,
        date.month,
        date.day - ((date.weekday + 1) % 7),
      );
    });
    load();
  }

  @override
  Widget build(BuildContext context) {
    final ids = widget.rooms.map((room) => '${room['id']}').toSet();
    final value = ids.contains(selected) ? selected : '';
    final chosen = widget.rooms
        .where((room) => value.isEmpty || '${room['id']}' == value)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: t('هفته قبل', 'Previous week'),
              onPressed: () => move(-7),
              icon: const Icon(Icons.chevron_left),
            ),
            TextButton(
              onPressed: pickWeek,
              child: Text(
                '${iso(week)} — ${iso(DateTime(week.year, week.month, week.day + 6))}',
              ),
            ),
            IconButton(
              tooltip: t('هفته بعد', 'Next week'),
              onPressed: () => move(7),
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              tooltip: t('تازه‌سازی نقشه حرارتی', 'Refresh occupancy'),
              onPressed: loading ? null : () => load(refresh: true),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        DropdownButtonFormField<String>(
          key: ValueKey(value),
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: t('کلاس', 'Classroom'),
            border: OutlineInputBorder(borderRadius: appRadius(context)),
          ),
          items: [
            DropdownMenuItem(
              value: '',
              child: Text(
                t('همه کلاس‌های مطابق فیلتر', 'All filtered classrooms'),
              ),
            ),
            for (final room in widget.rooms)
              DropdownMenuItem(
                value: '${room['id']}',
                child: Text('${room['name']}'),
              ),
          ],
          onChanged: (value) => setState(() => selected = value ?? ''),
        ),
        if (loading) const LinearProgressIndicator(),
        PanelInsightCharts(
          section: 'classrooms',
          rows: chosen,
          data: {
            ...data,
            '_occupancyWeek':
                '${iso(week)} — ${iso(DateTime(week.year, week.month, week.day + 6))}',
          },
        ),
      ],
    );
  }
}
