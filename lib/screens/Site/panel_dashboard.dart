import 'package:flutter/material.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_parity.dart';
import 'panel_presentation.dart';

/// Explicit website sections keep database metadata out of the dashboard UI.
class PanelDashboard extends StatelessWidget {
  const PanelDashboard({super.key, required this.data});
  final Json data;
  static const sections = {
    'todayClasses': (
      'کلاس‌های امروز',
      'Today’s classes',
      ['time', 'student', 'instrument', 'teacher', 'branch'],
    ),
    'actionItems': (
      'نیازمند اقدام',
      'Action required',
      ['studentName', 'termName', 'targetName', 'reason', 'text', 'date'],
    ),
    'urgentItems': ('هشدارها', 'Alerts', ['type', 'text']),
    'recentPayments': (
      'پرداخت‌های اخیر',
      'Recent payments',
      ['name', 'amount', 'time', 'branch'],
    ),
    'recentDeposits': (
      'واریزی‌های اخیر',
      'Recent deposits',
      ['title', 'amount', 'bank', 'time', 'branch'],
    ),
    'todayAbsences': (
      'غیبت‌های امروز',
      'Today’s absences',
      ['student', 'instrument', 'teacher', 'time', 'branch'],
    ),
    'unreadMessages': (
      'پیام‌های خوانده‌نشده',
      'Unread messages',
      ['from', 'preview', 'time', 'branch'],
    ),
    'recentRegistrations': (
      'ثبت‌نام‌های اخیر',
      'Recent registrations',
      ['name', 'instrument', 'date', 'branch'],
    ),
    'upcomingHolidays': (
      'تعطیلات پیش رو',
      'Upcoming holidays',
      ['person', 'title', 'type', 'date', 'branch'],
    ),
  };
  static const labels = {
    'time': ('زمان', 'Time'),
    'student': ('هنرجو', 'Student'),
    'instrument': ('درس', 'Lesson'),
    'teacher': ('مدرس', 'Teacher'),
    'branch': ('شعبه', 'Branch'),
    'name': ('نام', 'Name'),
    'amount': ('مبلغ', 'Amount'),
    'title': ('عنوان', 'Title'),
    'bank': ('روش پرداخت', 'Payment method'),
    'type': ('نوع', 'Type'),
    'text': ('توضیحات', 'Description'),
    'from': ('فرستنده', 'Sender'),
    'preview': ('پیام', 'Message'),
    'person': ('شخص', 'Person'),
    'date': ('تاریخ', 'Date'),
    'studentName': ('هنرجو', 'Student'),
    'termName': ('ترم', 'Term'),
    'targetName': ('حساب مقصد', 'Target account'),
    'reason': ('دلیل', 'Reason'),
  };
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PanelStatistics(stats: optionalObject(data['stats'])),
        for (final entry in sections.entries) ...[
          const SizedBox(height: 16),
          Text(
            socialText(context, entry.value.$1, entry.value.$2),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (objects(data[entry.key] ?? []).isEmpty)
            Text(
              socialText(
                context,
                'موردی برای نمایش وجود ندارد.',
                'No records to display.',
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  for (final key in entry.value.$3)
                    DataColumn(
                      label: Text(
                        socialText(context, labels[key]!.$1, labels[key]!.$2),
                      ),
                    ),
                ],
                rows: [
                  for (final row in objects(data[entry.key]))
                    DataRow(
                      cells: [
                        for (final key in entry.value.$3)
                          DataCell(
                            Text(
                              key == 'date'
                                  ? panelDate(
                                      row[key],
                                      fa:
                                          Localizations.localeOf(
                                            context,
                                          ).languageCode ==
                                          'fa',
                                    )
                                  : '${row[key] ?? '—'}',
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ],
    ),
  );
}
