import 'package:flutter/material.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'panel_parity.dart';
import 'panel_presentation.dart';
import '../../helpers/app_appearance.dart';
import 'panel_organization_filter.dart';

/// Match the website's academy-only view without treating branch rows as academy data.
Json panelDashboardOrganizationData(Json source, String organization) {
  if (organization != 'academy') return source;
  final result = <String, dynamic>{...source};
  for (final key in [...PanelDashboard.sections.keys, 'unreadMessages']) {
    result[key] = objects(
      source[key] ?? [],
    ).where((row) => panelMatchesOrganization(row, 'academy', source)).toList();
  }
  result['stats'] = {
    ...optionalObject(source['stats']),
    'activeStudents': 0,
    'todayClasses': 0,
    'monthlyIncome': 0,
    'attendanceRate': '0%',
    'pendingPayments': 0,
    'absencesToday': 0,
    'newMessages': objects(result['unreadMessages']).length,
    'urgentAlerts': objects(result['urgentItems']).length,
    'newStudentsWeek': 0,
    'pointsAwarded': 0,
  };
  return result;
}

/// Explicit website sections keep database metadata out of the dashboard UI.
class PanelDashboard extends StatelessWidget {
  const PanelDashboard({super.key, required this.data, this.onOpen});
  final Json data;
  final ValueChanged<String>? onOpen;
  static const destinations = {
    'todayClasses': 'schedules',
    'actionItems': 'waiting-approvals',
    'urgentItems': 'notifications',
    'recentPayments': 'reports',
    'recentDeposits': 'reports',
    'todayAbsences': 'students',
    'recentRegistrations': 'students',
    'upcomingHolidays': 'availability-exceptions',
  };
  static const emptyLabels = {
    'todayClasses': ('کلاسی برای امروز نیست', 'No classes today'),
    'actionItems': ('موردی نیازمند بررسی نیست', 'No items require review'),
    'urgentItems': ('مورد فوری نیست', 'No urgent items'),
    'recentPayments': ('پرداختی ثبت نشده', 'No payments recorded'),
    'recentDeposits': ('واریزی ثبت نشده', 'No deposits recorded'),
    'todayAbsences': ('غیبتی ثبت نشده', 'No absences recorded'),
    'recentRegistrations': ('ثبت‌نام جدیدی نیست', 'No new registrations'),
    'upcomingHolidays': ('موردی نزدیک نیست', 'No upcoming items'),
  };
  static const sections = {
    'todayClasses': (
      'کلاس‌های امروز',
      'Today’s classes',
      ['time', 'student', 'instrument', 'teacher', 'branch'],
    ),
    'actionItems': (
      'اقدامات نیازمند بررسی',
      'Actions requiring review',
      ['studentName', 'termName', 'targetName', 'reason', 'text', 'date'],
    ),
    'urgentItems': ('موارد فوری', 'Urgent items', ['type', 'text']),
    'recentPayments': (
      'آخرین پرداخت‌ها',
      'Recent payments',
      ['name', 'amount', 'time', 'branch'],
    ),
    'recentDeposits': (
      'آخرین واریزها',
      'Recent deposits',
      ['title', 'amount', 'bank', 'time', 'branch'],
    ),
    'todayAbsences': (
      'غیبت‌های امروز',
      'Today’s absences',
      ['student', 'instrument', 'teacher', 'time', 'branch'],
    ),
    'recentRegistrations': (
      'ثبت‌نام‌های اخیر',
      'Recent registrations',
      ['name', 'instrument', 'date', 'branch'],
    ),
    'upcomingHolidays': (
      'تعطیلات و مرخصی‌های نزدیک',
      'Upcoming holidays and leaves',
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
        PanelStatistics(
          stats: {
            for (final key in [
              'activeStudents',
              'monthlyIncome',
              'pendingPayments',
              'newStudentsWeek',
            ])
              key: optionalObject(data['stats'])[key] ?? '—',
          },
        ),
        for (final entry in [
          for (final key in [
            'actionItems',
            'urgentItems',
            'todayClasses',
            'todayAbsences',
            'recentRegistrations',
            'upcomingHolidays',
            'recentPayments',
            'recentDeposits',
          ])
            MapEntry(key, sections[key]!),
        ])
          Card(
            key: ValueKey('dashboard-${entry.key}'),
            margin: const EdgeInsets.only(top: 16),
            shape: RoundedRectangleBorder(borderRadius: appRadius(context)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          socialText(context, entry.value.$1, entry.value.$2),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: onOpen == null
                            ? null
                            : () => onOpen!(destinations[entry.key]!),
                        child: Text(
                          socialText(context, 'مشاهده همه', 'View all'),
                        ),
                      ),
                    ],
                  ),
                  if (entry.key == 'actionItems')
                    Text(
                      socialText(
                        context,
                        'تمام مواردی که به تأیید یا تعیین تاریخ جدید نیاز دارند',
                        'All items requiring approval or a new date',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 12),
                  if (objects(data[entry.key] ?? []).isEmpty)
                    Text(
                      socialText(
                        context,
                        emptyLabels[entry.key]!.$1,
                        emptyLabels[entry.key]!.$2,
                      ),
                    )
                  else
                    for (final row in objects(data[entry.key]))
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          borderRadius: appRadius(context),
                        ),
                        child: entry.key == 'todayClasses'
                            ? Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${row['student'] ?? '—'}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                        Text(
                                          '${row['instrument'] ?? '—'} — ${row['teacher'] ?? '—'}',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${row['time'] ?? '—'}'),
                                      Text(
                                        '${row['branch'] ?? '—'}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final key in entry.value.$3)
                                    if (row[key] != null &&
                                        '${row[key]}'.isNotEmpty)
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
                                            : '${row[key]}',
                                      ),
                                  if (entry.key == 'actionItems' &&
                                      [
                                        'student_waiting',
                                        'student_pending_schedule',
                                      ].contains(row['type']))
                                    TextButton(
                                      onPressed: onOpen == null
                                          ? null
                                          : () => onOpen!(
                                              row['type'] == 'student_waiting'
                                                  ? 'waiting-approvals'
                                                  : 'waiting-schedules',
                                            ),
                                      child: Text(
                                        socialText(
                                          context,
                                          row['type'] == 'student_waiting'
                                              ? 'بررسی درخواست ثبت‌نام'
                                              : 'نهایی‌کردن ثبت‌نام',
                                          row['type'] == 'student_waiting'
                                              ? 'Review registration'
                                              : 'Finalize registration',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
