import 'package:flutter/material.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_parity.dart';

DateTime panelWeekStart(DateTime date) => DateTime(
  date.year,
  date.month,
  date.day,
).subtract(Duration(days: (date.weekday + 1) % 7));

class PanelScheduleWeek extends StatelessWidget {
  const PanelScheduleWeek({
    super.key,
    required this.rows,
    required this.start,
    required this.open,
  });
  final List<Json> rows;
  final DateTime start;
  final ValueChanged<Json> open;
  @override
  Widget build(BuildContext context) {
    final fa = Localizations.localeOf(context).languageCode == 'fa';
    final times =
        rows
            .map((r) => '${r['startTime'] ?? ''} – ${r['endTime'] ?? ''}')
            .toSet()
            .toList()
          ..sort();
    final days = List.generate(7, (i) => start.add(Duration(days: i)));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(socialText(context, 'ساعت', 'Time'))),
          for (final day in days)
            DataColumn(
              label: Text(
                panelDate(day.toIso8601String().substring(0, 10), fa: fa),
              ),
            ),
        ],
        rows: [
          for (final time in times)
            DataRow(
              cells: [
                DataCell(Text(time)),
                for (final day in days)
                  DataCell(
                    SizedBox(
                      width: 190,
                      height: 160,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final row in rows.where(
                              (row) =>
                                  '${row['date'] ?? row['requested_date']}'
                                      .startsWith(
                                        day.toIso8601String().substring(0, 10),
                                      ) &&
                                  '${row['startTime'] ?? ''} – ${row['endTime'] ?? ''}' ==
                                      time,
                            ))
                              TextButton(
                                onPressed: () => open(row),
                                child: Text(
                                  '${row['title'] ?? row['termName'] ?? ''}\n${row['branchName'] ?? ''} — ${row['classroom'] ?? ''}',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
        dataRowMinHeight: 72,
        dataRowMaxHeight: 180,
      ),
    );
  }
}
