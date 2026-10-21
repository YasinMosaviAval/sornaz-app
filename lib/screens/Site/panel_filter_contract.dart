import '../Social/social_api.dart';
import 'panel_table_contract.dart';
import 'panel_form_contract.dart';
import 'panel_organization_filter.dart';

/// Web filters are local unless a query key explicitly delegates pagination and
/// filtering to the same server endpoint used by the website.
List<Json> panelWebFilters(Json section, Json data, List<Json> rows) {
  if (section['key'] == 'dashboard') return const [];
  if (section['key'] == 'tracking') {
    return [
      {
        'key': 'days',
        'queryKey': 'days',
        'label': 'بازه زمانی',
        'type': 'select',
        'options': {
          '1': '۲۴ ساعت',
          '7': '۷ روز',
          '30': '۳۰ روز',
          '90': '۹۰ روز',
          'all': 'همه',
        },
      },
      {
        'key': 'user',
        'queryKey': 'user',
        'label': 'کاربر',
        'type': 'select',
        'options': {
          for (final user in objects(data['userOptions'] ?? []))
            '${user['id']}': '${user['name']}',
        },
      },
    ];
  }
  final contract = panelTableContract(section);
  final definitions = panelTableColumns({
    'columns':
        contract['filters'] ??
        [
          for (final field in objects(section['filters'] ?? []))
            {...field, 'queryKey': field['key']},
        ],
  }, data);
  return [
    for (final field in definitions)
      if (!panelFixedBranchScope(data) ||
          !RegExp(
            r'branch|academy|organization',
            caseSensitive: false,
          ).hasMatch(
            '${field['key']} ${field['rowPath']} ${field['queryKey']}',
          ))
        {
          ...field,
          'options': {
            if (optionalObject(field['options'])['source'] == null)
              ...optionalObject(field['options'])
            else
              ...panelSelectOptions(field, data),
            if (field['distinct'] == true)
              for (final row in rows)
                for (final value in _values(
                  panelFilterValue(row, '${field['rowPath']}'),
                ))
                  if (value != null && '$value'.isNotEmpty)
                    (section['key'] == 'my-points' && field['rowPath'] == 'type'
                            ? panelFilterToken(value)
                            : '$value'):
                        section['key'] == 'my-points' &&
                            field['rowPath'] == 'type'
                        ? const {
                                'general': 'عمومی',
                                'professional': 'حرفه‌ای',
                                'specialized': 'حرفه‌ای',
                              }['$value'] ??
                              panelTableText(value)
                        : panelTableText(value),
            if (field['optionSource'] is Map)
              ...panelSelectOptions({
                'options': {
                  ...optionalObject(field['optionSource']),
                  'includeReadOnly': true,
                },
              }, data),
            if (['timeFrom', 'timeTo'].contains(field['rowPath']))
              ..._timeOptions(rows),
            if (field['key'] == 'mediaMonth')
              for (final month in objects(data['months'] ?? []))
                '${month['value']}': '${month['value']} (${month['total']})',
          },
        },
  ];
}

Map<String, String> _timeOptions(List<Json> rows) {
  int? minutes(dynamic value) {
    final parts = '$value'.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]), m = int.tryParse(parts[1]);
    return h == null || m == null ? null : h * 60 + m;
  }

  final times =
      rows
          .expand((row) => [minutes(row['startTime']), minutes(row['endTime'])])
          .whereType<int>()
          .toList()
        ..sort();
  if (times.isEmpty) return {};
  return {
    for (
      var minute = times.first ~/ 5 * 5;
      minute <= (times.last / 5).ceil() * 5;
      minute += 5
    )
      '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}':
          '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}',
  };
}

Iterable<dynamic> _values(dynamic value) =>
    value is List ? value.expand(_values) : [value];

String panelFilterToken(dynamic value) {
  final text = '$value'
      .replaceAll('\u200c', '')
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک')
      .trim();
  return const {
        'specialized': 'professional',
        'عمومی': 'general',
        'حرفهای': 'professional',
        'حرفه‌ای': 'professional',
        'تخصصی': 'professional',
        'حضور': 'attendance',
        'آموزشی': 'academic',
        'رویداد': 'event',
        'اجتماعی': 'social',
        'مالی': 'financial',
        'پروفایل': 'profile',
        'دستاورد': 'achievement',
        'تعامل': 'engagement',
        'مدیریت': 'management',
        'فعال': 'active',
        'غیرفعال': 'inactive',
        'در انتظار': 'pending',
        'در انتظار تأیید': 'pending',
        'در انتظار تایید': 'pending',
        'تأیید شده': 'approved',
        'تأییدشده': 'approved',
        'رد شده': 'rejected',
        'حذف شده': 'removed',
        'باز': 'open',
        'در حال برگزاری': 'ongoing',
        'پایانیافته': 'finished',
        'پایان یافته': 'finished',
        'در دسترس': 'available',
        'خارج از دسترس': 'unavailable',
        'پیشنويس': 'draft',
        'پیشنویس': 'draft',
        'صادرشده': 'issued',
        'پرداختشده': 'paid',
        'پرداخت جزئی': 'partially_paid',
        'لغوشده': 'canceled',
      }[text] ??
      text;
}

dynamic panelFilterValue(Json row, String path) {
  if (path == 'status' && row['invoiceKind'] == 'subscription')
    return row['status'];
  if (path == 'type' &&
      row['type'] == null &&
      row['termName'] != null &&
      row['amount'] != null)
    return 'فاکتور ترم';
  if (path == 'equipment')
    return row['equipment'] is List
        ? (row['equipment'] as List)
              .map((e) => e is Map ? e['name'] : e)
              .toList()
        : row['equipment'];
  if (path == '_weekday')
    return objects(row['sessions'] ?? [])
        .map((s) => DateTime.tryParse('${s['date']}')?.weekday)
        .whereType<int>()
        .map((d) => d % 7)
        .toList();
  if (path == '_ageGroup') {
    final date = DateTime.tryParse('${row['birthDate'] ?? row['birth_date']}');
    if (date == null) return row['ageGroup'];
    final now = DateTime.now();
    final age =
        now.year -
        date.year -
        ((now.month < date.month ||
                now.month == date.month && now.day < date.day)
            ? 1
            : 0);
    return age < 18 ? 'child' : 'adult';
  }
  if (path == 'month')
    return '${row['createdAt'] ?? ''}'.split('-').take(2).join('-');
  return panelTableValue(row, path);
}

bool panelMatchesFilters(
  Json row,
  List<Json> definitions,
  Json values, {
  DateTime? now,
}) {
  for (final field in definitions) {
    if (!panelFieldVisible(field, {'_form': values})) continue;
    final selected = values[field['key']];
    if (selected == null || '$selected'.isEmpty || field['queryKey'] != null)
      continue;
    final path = '${field['rowPath'] ?? field['key']}';
    if (path == 'range' || path == '_dateFrom' || path == '_dateTo') {
      final date = DateTime.tryParse(
        '${row['dateIso'] ?? row['dueDate'] ?? row['date']}',
      );
      if (date == null) continue;
      final today = now ?? DateTime.now();
      final days = {'weekly': 7, 'monthly': 30, 'yearly': 365}['$selected'];
      if (days != null &&
          date.isBefore(
            DateTime(
              today.year,
              today.month,
              today.day,
            ).subtract(Duration(days: days)),
          ))
        return false;
      final boundary = DateTime.tryParse('$selected');
      if (boundary != null &&
          (path == '_dateFrom'
              ? date.isBefore(boundary)
              : date.isAfter(
                  boundary
                      .add(const Duration(days: 1))
                      .subtract(const Duration(microseconds: 1)),
                )))
        return false;
      continue;
    }
    final actual = panelFilterValue(row, path);
    if (['gte', 'lte'].contains(field['operator'])) {
      final date = DateTime.tryParse('$actual');
      final boundary = DateTime.tryParse('$selected');
      if (date == null ||
          boundary == null ||
          (field['operator'] == 'gte'
              ? date.isBefore(boundary)
              : date.isAfter(
                  boundary
                      .add(const Duration(days: 1))
                      .subtract(const Duration(microseconds: 1)),
                )))
        return false;
      continue;
    }
    if (!_values(
      actual,
    ).any((v) => panelFilterToken(v) == panelFilterToken(selected)))
      return false;
  }
  return true;
}

Map<String, String> panelFilterQuery(
  List<Json> fields,
  Json values,
  String organization,
  String section,
) => {
  for (final field in fields)
    if (field['queryKey'] != null &&
        values[field['key']] != null &&
        '${values[field['key']]}'.isNotEmpty)
      '${field['queryKey']}': '${values[field['key']]}',
  if (['users', 'schedules', 'dashboard'].contains(section)) ...{
    if (organization == 'academy')
      (section == 'users'
              ? 'organization'
              : section == 'dashboard'
              ? 'branchId'
              : 'branch'):
          'academy',
    if (organization.startsWith('branch:'))
      (['users', 'dashboard'].contains(section) ? 'branchId' : 'branch'):
          organization.substring(7),
  },
};
