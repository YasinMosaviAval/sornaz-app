import 'package:flutter/material.dart';
import '../../helpers/app_appearance.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_parity.dart';

DateTime panelWeekStart(DateTime date) => DateTime(
  date.year,
  date.month,
  date.day,
).subtract(Duration(days: (date.weekday + 1) % 7));
String panelScheduleISO(DateTime date) =>
    date.toIso8601String().substring(0, 10);

class PanelSchedulePreferences {
  final layouts = <String, String>{};
  final swapped = <String>{},
      emptyRooms = <String>{},
      emptyDays = <String>{},
      emptyTimes = <String>{};
}

class PanelScheduleWeek extends StatefulWidget {
  const PanelScheduleWeek({
    super.key,
    required this.rows,
    required this.start,
    required this.open,
    this.data = const {},
    this.branch = '',
    this.first,
    this.last,
    this.changeWeek,
    this.preferences,
  });
  final List<Json> rows;
  final Json data;
  final String branch;
  final DateTime start;
  final DateTime? first, last;
  final ValueChanged<DateTime>? changeWeek;
  final ValueChanged<Json> open;
  final PanelSchedulePreferences? preferences;
  @override
  State<PanelScheduleWeek> createState() => _PanelScheduleWeekState();
}

class _PanelScheduleWeekState extends State<PanelScheduleWeek> {
  late final preferences = widget.preferences ?? PanelSchedulePreferences();
  Map<String, String> get layouts => preferences.layouts;
  Set<String> get swapped => preferences.swapped;
  Set<String> get emptyRooms => preferences.emptyRooms;
  Set<String> get emptyDays => preferences.emptyDays;
  Set<String> get emptyTimes => preferences.emptyTimes;
  String tr(String fa, String en) => socialText(context, fa, en);
  String date(DateTime value) => panelDate(
    panelScheduleISO(value),
    fa: Localizations.localeOf(context).languageCode == 'fa',
  );
  void toggle(Set<String> values, String id) => setState(() {
    values.contains(id) ? values.remove(id) : values.add(id);
  });
  @override
  Widget build(BuildContext context) {
    final branches = <String, Json>{
      for (final branch in objects(widget.data['branches'] ?? []))
        '${branch['id']}': branch,
    };
    for (final row in widget.rows) {
      branches.putIfAbsent(
        '${row['branchId']}',
        () => {'id': row['branchId'], 'name': row['branchName']},
      );
    }
    final selected = widget.branch.startsWith('branch:')
        ? widget.branch.substring(7)
        : widget.branch == 'academy'
        ? '0'
        : widget.branch;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '${date(widget.start)} ${tr('تا', 'to')} ${date(widget.start.add(const Duration(days: 6)))}',
            ),
          ),
          calendarControls(),
          for (final branch in branches.values)
            if (selected.isEmpty || '${branch['id']}' == selected)
              branchTable(branch),
          if (branches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(tr('شعبه‌ای یافت نشد.', 'No branches found.')),
            ),
        ],
      ),
    );
  }

  Widget navigation() {
    var start = widget.start.subtract(const Duration(days: 14));
    if (widget.first != null && start.isBefore(widget.first!))
      start = widget.first!;
    if (widget.last != null &&
        start.add(const Duration(days: 28)).isAfter(widget.last!)) {
      start = widget.last!.subtract(const Duration(days: 28));
      if (widget.first != null && start.isBefore(widget.first!))
        start = widget.first!;
    }
    Widget button(String label, DateTime? target, {bool active = false}) {
      final outside =
          target == null ||
          (widget.first != null && target.isBefore(widget.first!)) ||
          (widget.last != null && target.isAfter(widget.last!));
      return OutlinedButton(
        style: active
            ? OutlinedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              )
            : null,
        onPressed: outside || widget.changeWeek == null
            ? null
            : () => widget.changeWeek!(target),
        child: Text(label),
      );
    }

    return horizontalControls([
      button(tr('اول', 'First'), widget.first),
      button(
        tr('قبلی', 'Previous'),
        widget.start.subtract(const Duration(days: 7)),
      ),
      for (var i = 0; i < 5; i++)
        button(
          date(start.add(Duration(days: i * 7))),
          start.add(Duration(days: i * 7)),
          active: start.add(Duration(days: i * 7)) == widget.start,
        ),
      button(tr('بعدی', 'Next'), widget.start.add(const Duration(days: 7))),
      button(tr('آخر', 'Last'), widget.last),
    ]);
  }

  Widget horizontalControls(List<Widget> children) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final child in children)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: child,
          ),
      ],
    ),
  );

  Widget calendarControls() {
    const id = 'all';
    final mode = layouts['all'] ?? 'class-day';
    Widget emptyFilter(Set<String> values, String fa, String en) => FilterChip(
      shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
      label: Text(
        tr(
          '${values.contains(id) ? 'پنهان‌کردن' : 'نمایش'} $fa',
          '${values.contains(id) ? 'Hide' : 'Show'} $en',
        ),
      ),
      selected: values.contains(id),
      onSelected: (_) => toggle(values, id),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        navigation(),
        const SizedBox(height: 8),
        horizontalControls([
          Text(tr('نوع چیدمان:', 'Layout:')),
          for (final layout in [
            ('class-day', 'کلاس × روز', 'Class × day'),
            ('class-time', 'کلاس × بازه زمانی', 'Class × time range'),
            ('day-time', 'روز هفته × بازه زمانی', 'Weekday × time range'),
          ])
            ChoiceChip(
              shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
              label: Text(tr(layout.$2, layout.$3)),
              selected: mode == layout.$1,
              onSelected: (_) => setState(() => layouts[id] = layout.$1),
            ),
        ]),
        const SizedBox(height: 8),
        horizontalControls([
          if (mode != 'day-time')
            emptyFilter(emptyRooms, 'کلاس‌های خالی', 'empty classes'),
          if (mode != 'class-time')
            emptyFilter(emptyDays, 'روزهای خالی', 'empty days'),
          if (mode != 'class-day')
            emptyFilter(emptyTimes, 'بازه‌های زمانی خالی', 'empty time ranges'),
        ]),
        const SizedBox(height: 8),
        horizontalControls([
          OutlinedButton.icon(
            onPressed: () => toggle(swapped, id),
            icon: const Icon(Icons.swap_horiz),
            label: Text(tr('جابه‌جایی سطر و ستون', 'Swap rows and columns')),
          ),
        ]),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget branchTable(Json branch) {
    final id = '${branch['id']}';
    final sessions = widget.rows
        .where((s) => '${s['branchId']}' == id)
        .toList();
    final mode = layouts['all'] ?? 'class-day';
    var rooms = <Json>[
      for (final room in objects(widget.data['classrooms'] ?? []))
        if ('${room['branchId']}' == id) {...room, 'kind': 'class'},
    ];
    for (final session in sessions.where((s) => s['mode'] != 'online')) {
      if (!rooms.any((r) => '${r['id']}' == '${session['classroomId']}')) {
        rooms.add({
          'id': session['classroomId'],
          'name': session['classroom'],
          'kind': 'class',
        });
      }
    }
    if (sessions.any((s) => s['mode'] == 'online'))
      rooms.add({
        'id': 0,
        'online': true,
        'name': tr('کلاس آنلاین', 'Online class'),
        'kind': 'class',
      });
    bool roomMatches(Json s, Json r) => r['online'] == true
        ? s['mode'] == 'online'
        : s['mode'] != 'online' && '${s['classroomId']}' == '${r['id']}';
    final dayNames = [
      tr('شنبه', 'Saturday'),
      tr('یکشنبه', 'Sunday'),
      tr('دوشنبه', 'Monday'),
      tr('سه‌شنبه', 'Tuesday'),
      tr('چهارشنبه', 'Wednesday'),
      tr('پنجشنبه', 'Thursday'),
      tr('جمعه', 'Friday'),
    ];
    var days = List<Json>.generate(
      7,
      (i) => {
        'id': panelScheduleISO(widget.start.add(Duration(days: i))),
        'name': dayNames[i],
        'kind': 'day',
      },
    );
    if (!emptyRooms.contains('all'))
      rooms = rooms
          .where((r) => sessions.any((s) => roomMatches(s, r)))
          .toList();
    if (!emptyDays.contains('all'))
      days = days
          .where((d) => sessions.any((s) => s['date'] == d['id']))
          .toList();
    final sourceTimes = emptyTimes.contains('all')
        ? objects(widget.data['timeRanges'] ?? [])
        : [
            for (final s in sessions)
              {'start': s['startTime'], 'end': s['endTime']},
          ];
    final uniqueTimes = <String, Json>{
      for (final t in sourceTimes)
        '${t['start']}|${t['end']}': {
          'id': '${t['start']}|${t['end']}',
          'name': '${t['start']} ${tr('تا', 'to')} ${t['end']}',
          'start': t['start'],
          'end': t['end'],
          'kind': 'time',
        },
    };
    final times = uniqueTimes.values.toList()
      ..sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
    var rows = mode == 'day-time' ? days : rooms;
    var columns = mode == 'class-day' ? days : times;
    var axes = mode == 'class-day'
        ? [tr('کلاس', 'Class'), tr('روز', 'Day')]
        : mode == 'class-time'
        ? [tr('کلاس', 'Class'), tr('بازه زمانی', 'Time range')]
        : [tr('روز', 'Day'), tr('بازه زمانی', 'Time range')];
    if (swapped.contains('all')) {
      final old = rows;
      rows = columns;
      columns = old;
      axes = axes.reversed.toList();
    }
    bool matches(Json session, Json axis) => switch (axis['kind']) {
      'class' => roomMatches(session, axis),
      'day' => session['date'] == axis['id'],
      _ =>
        session['startTime'] == axis['start'] &&
            session['endTime'] == axis['end'],
    };
    Widget axis(Json item) => Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        '${item['name']}${item['kind'] == 'day' ? '\n${date(DateTime.parse(item['id']))}' : ''}',
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${branch['name'] ?? ''}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          if (rows.isEmpty || columns.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                tr(
                  'جلسه‌ای برای این چیدمان وجود ندارد.',
                  'No sessions for this layout.',
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(190),
                border: TableBorder.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.top,
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(axes.join(' / ')),
                      ),
                      for (final col in columns) axis(col),
                    ],
                  ),
                  for (final row in rows)
                    TableRow(
                      children: [
                        axis(row),
                        for (final col in columns)
                          Builder(
                            builder: (context) {
                              final cell =
                                  sessions
                                      .where(
                                        (s) =>
                                            matches(s, row) && matches(s, col),
                                      )
                                      .toList()
                                    ..sort(
                                      (a, b) => '${a['date']} ${a['startTime']}'
                                          .compareTo(
                                            '${b['date']} ${b['startTime']}',
                                          ),
                                    );
                              return Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (cell.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 20,
                                        ),
                                        child: Text(
                                          tr('بدون جلسه', 'No session'),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ),
                                    for (final session in cell)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer,
                                            padding: const EdgeInsets.all(8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: appRadius(context),
                                            ),
                                          ),
                                          onPressed: () => widget.open(session),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                mode == 'class-day'
                                                    ? '${session['startTime']} ${tr('تا', 'to')} ${session['endTime']}'
                                                    : mode == 'class-time'
                                                    ? '${session['day'] ?? ''}'
                                                    : '${session['classroom'] ?? ''}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.labelLarge,
                                              ),
                                              Text(
                                                '${session['title'] ?? session['termName'] ?? ''}',
                                              ),
                                              if (mode == 'class-day')
                                                Text(
                                                  '${session['lesson'] ?? ''}',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
