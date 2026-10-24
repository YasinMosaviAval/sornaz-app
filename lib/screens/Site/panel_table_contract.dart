import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_appearance.dart';
import '../Social/social_api.dart';
import 'panel_api.dart';
import 'panel_web_contracts.dart';
import 'panel_form_contract.dart';
import 'panel_parity.dart';
import 'panel_caption.dart';
import 'panel_finance.dart';
import 'panel_schedule_contract.dart';

String panelCellText(BuildContext context, Json row, Json column) {
  final value = panelTableValue(row, '${column['key']}');
  final fa = Localizations.localeOf(context).languageCode == 'fa';
  if (value is num ||
      [
            'amount',
            'cost',
            'price',
            'points',
            'capacity',
            'student_capacity',
            'teacher_capacity',
          ].contains(column['key']) &&
          num.tryParse('$value') != null)
    return panelNumber(value, fa: fa);
  if (value is String && RegExp(r'^\d{4}-\d{2}-\d{2}([T ]|$)').hasMatch(value))
    return panelDate(value, fa: fa);
  return panelTableText(value);
}

/// Presentation is separate from API capabilities: an available endpoint does
/// not imply that the website exposes a button or column for it.
Json panelTableContract(Json section) {
  final incoming = optionalObject(section['presentation']);
  final bundled = section['key'] == 'my-point-rules'
      ? optionalObject(
          optionalObject(
            optionalObject(panelWebPresentation['my-points'])['views'],
          )['rules'],
        )
      : optionalObject(panelWebPresentation[section['key']]);
  final selected = incoming['version'] == 2 || bundled.isEmpty
      ? incoming
      : bundled;
  final contract = {
    ...selected,
    if (selected['guidance'] == null && bundled['guidance'] is Map)
      'guidance': bundled['guidance'],
  };
  if (section['key'] == 'lessons') {
    return {
      ...contract,
      'rowActions': ['details', 'usage', 'update', 'delete'],
    };
  }
  if (section['key'] == 'terms') {
    return {
      ...contract,
      'rowActions': <String>{
        ...(contract['rowActions'] as List? ??
                [
                  'details',
                  ...optionalObject(
                    section['actions'],
                  ).keys.where((key) => key != 'status'),
                ])
            .map((key) => '$key'),
        'attendance',
      }.toList(),
    };
  }
  if (section['key'] == 'schedules') {
    return {
      ...contract,
      'rowActions': [
        ...((contract['rowActions'] as List?) ?? ['details', 'attendance']),
        'cancel',
      ].toSet().toList(),
    };
  }
  if (['course-levels', 'my-lesson-levels'].contains(section['key'])) {
    return {
      ...contract,
      'columns': [
        {'key': 'name', 'label': 'عنوان'},
        {'key': 'summary', 'label': 'خلاصه'},
      ],
      'rowActions': ['details'],
      'detailTitle': 'جزئیات سطح درس',
      'detailFields': [
        {'key': 'name', 'label': 'عنوان'},
        {'key': 'summary', 'label': 'خلاصه'},
        {'key': 'description', 'label': 'توضیحات'},
      ],
    };
  }
  return contract;
}

List<Json> panelRecordDetailFields(Json section) {
  final contract = panelTableContract(section);
  final finance = ['finance', 'my-finance'].contains(section['key']);
  var statusShown = false;
  return objects(contract['detailFields'] ?? section['fields'] ?? [])
      .map(
        (field) =>
            finance &&
                [
                  'statusCode',
                  'status_code',
                  'statusLabel',
                ].contains(field['key'])
            ? <String, dynamic>{...field, 'key': 'status', 'label': 'وضعیت'}
            : field,
      )
      .where(
        (field) =>
            field['label'] is String &&
            field['label'] != field['key'] &&
            !['password', 'csrf_token', 'token'].contains(field['key']),
      )
      .where((field) {
        if (!finance || field['key'] != 'status') return true;
        if (statusShown) return false;
        statusShown = true;
        return true;
      })
      .toList();
}

List<Json> panelTableColumns(Json contract, Json data) =>
    objects(contract['columns'] ?? []).where((column) {
      final permission = column['permission'];
      return (permission == null ||
              optionalObject(data['permissions'])[permission] == true) &&
          (column['dataPermission'] == null ||
              panelValue(data, '${column['dataPermission']}') == true);
    }).toList();

dynamic panelTableValue(Json row, String key) {
  final aliases = <String, List<String>>{
    'name': ['name', 'title'],
    'title': ['title', 'name', 'lesson'],
    'status': ['status_code', 'statusCode', 'statusValue', 'status'],
    'levelTitle': ['levelTitle', 'levelName', 'level'],
    'branchName': ['branchName', 'branch', 'organizationName'],
    'timeLabel': ['timeLabel', 'time'],
    'dueDate': ['dueDate', 'due_date'],
    'number': ['number', 'installment_number', 'id'],
  };
  for (final path in aliases[key] ?? [key]) {
    final value = panelValue(row, path);
    if (value != null) return value;
  }
  return null;
}

String panelTableText(dynamic value) {
  if (value == null || value == '') return '—';
  if (value is bool) return value ? 'بله' : 'خیر';
  if (value is List) return value.map(panelTableText).join('، ');
  if (value is Map) {
    return '${value['label'] ?? value['title'] ?? value['name'] ?? '—'}';
  }
  return '$value';
}

Json panelDisplayRow(String section, Json row, Json data) {
  final result = {...row};
  if (section == 'schedules') {
    final label =
        row['status'] ??
        panelScheduleStatus(row['statusCode'] ?? row['status_code']);
    for (final key in ['status', 'statusCode', 'status_code', 'statusValue']) {
      result[key] = panelScheduleStatus(label);
    }
  }
  if (['finance', 'my-finance'].contains(section)) {
    final code = row['statusCode'] ?? row['status_code'] ?? row['status'];
    final label = panelInvoiceStatuses[code] ?? row['status'] ?? '—';
    for (final key in ['status', 'statusCode', 'status_code', 'statusLabel']) {
      result[key] = label;
    }
  }
  if (section == 'term-discounts') {
    result['typeLabel'] = row['type'] == 'percentage' ? 'درصدی' : 'مبلغ ثابت';
    result['valueLabel'] =
        '${row['value']}${row['type'] == 'percentage' ? '%' : ''}';
  }
  if (['points', 'my-point-rules', 'my-points'].contains(section)) {
    result['type'] =
        const {
          'general': 'عمومی',
          'professional': 'حرفه‌ای',
          'specialized': 'تخصصی',
        }[row['type']] ??
        row['type'];
    result['category'] =
        const {
          'attendance': 'حضور',
          'academic': 'آموزشی',
          'event': 'رویداد',
          'social': 'اجتماعی',
          'financial': 'مالی',
          'profile': 'پروفایل',
          'achievement': 'دستاورد',
          'engagement': 'تعامل',
          'management': 'مدیریت',
        }[row['category']] ??
        row['category'];
    final repeat =
        const {
          'event': 'هر رویداد یکتا',
          'daily': 'دارای سقف روزانه',
          'once': 'فقط یک‌بار',
        }[row['repeatMode']] ??
        row['repeatMode'];
    result['repeatMode'] =
        '$repeat${(num.tryParse('${row['dailyCap']}') ?? 0) > 0 ? ' · سقف ${row['dailyCap']}' : ''}${(num.tryParse('${row['cooldownMinutes']}') ?? 0) > 0 ? ' · فاصله ${row['cooldownMinutes']} دقیقه' : ''}';
    result['source'] =
        '${const {'database': 'رویداد قطعی دیتابیس', 'tracking': 'رفتار کاربر', 'manual': 'اعطای دستی'}[row['source']] ?? row['source'] ?? ''}\n${row['action'] ?? ''}';
  }
  if (['lessons', 'my-lessons'].contains(section)) {
    final level = objects(data['levels'] ?? [])
        .where(
          (level) =>
              '${level['id'] ?? level['level_id']}' == '${row['level_id']}',
        )
        .firstOrNull;
    if (level != null) {
      result['levelTitle'] = level['title'] ?? level['name'];
      result['level'] = result['levelTitle'];
    }
  }
  if (section == 'roles' || section == 'permissions') {
    result['scope'] =
        const {
          'platform': 'پلتفرم',
          'website': 'سایت',
          'academy': 'آموزشگاه',
          'branch': 'شعبه',
          'self': 'شخصی',
        }[row['scope']] ??
        row['scope'];
    result['title'] =
        '${panelValue(row, 'translations.fa.title') ?? row['title'] ?? row['name'] ?? ''}\n${row['name'] ?? ''}';
    result['panelVisible'] = row['panelVisible'] == true ? 'نمایش' : 'مخفی';
    if (section == 'roles') {
      result['permissionIds'] = (row['permissionIds'] as List? ?? []).length;
      final parent = objects(
        data['roles'] ?? [],
      ).where((role) => '${role['id']}' == '${row['parentId']}').firstOrNull;
      result['parent'] = parent == null
          ? null
          : panelValue(parent, 'translations.fa.title') ?? parent['name'];
    }
  }
  if (section == 'users') {
    final inherited = row['rolePermissionIds'] as List? ?? [];
    final permissions = objects(row['permissions'] ?? []);
    result['directPermissions'] = permissions
        .where((p) => !inherited.contains(p['id']))
        .toList();
    result['rolePermissions'] = objects(
      data['permissions'] ?? [],
    ).where((p) => inherited.contains(p['id'])).toList();
  }
  if (section == 'schedules') {
    result['time'] = '${row['startTime'] ?? ''} – ${row['endTime'] ?? ''}';
  }
  if (section == 'finance') {
    result['title'] =
        '#${row['id']} — ${row['termName'] ?? row['title'] ?? ''}';
    result['date'] = row['date'] ?? row['dueDate'];
  }
  for (final key in ['is_primary', 'is_peer_reviewed']) {
    if (result[key] is num) result[key] = result[key] == 1;
  }
  if (section == 'terms') {
    final sessions = objects(row['sessions'] ?? []);
    const days = [
      'دوشنبه',
      'سه‌شنبه',
      'چهارشنبه',
      'پنجشنبه',
      'جمعه',
      'شنبه',
      'یکشنبه',
    ];
    result['days'] = sessions
        .map((session) => DateTime.tryParse('${session['date']}'))
        .whereType<DateTime>()
        .map((date) => days[date.weekday - 1])
        .toSet()
        .join('، ');
    result['timeLabel'] = sessions
        .where((session) => session['startTime'] != null)
        .map(
          (session) => '${session['startTime']} – ${session['endTime'] ?? ''}',
        )
        .toSet()
        .join('، ');
  }
  if (section == 'my-schedule') {
    final ranges = objects(row['ranges'] ?? []);
    for (final key in ['start', 'end', 'status']) {
      result[key] = ranges.map((range) => range[key]).toList();
    }
  }
  return result;
}

class PanelStatusCell extends StatelessWidget {
  const PanelStatusCell({
    super.key,
    required this.row,
    required this.column,
    required this.section,
    this.onPressed,
  });
  final Json row, column;
  final String section;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final approval = column['type'] == 'approval';
    final rawValue = approval
        ? (row['approved_at'] != null && row['approved_at'] != ''
              ? 'approved'
              : 'pending')
        : '${panelTableValue(row, '${column['key']}') ?? ''}';
    final value =
        const {
          'فعال': 'active',
          'غیرفعال': 'inactive',
          'در دسترس': 'available',
          'خارج از دسترس': 'unavailable',
          'تأیید شده': 'approved',
          'تأییدشده': 'approved',
          'در انتظار تأیید': 'pending',
          'در انتظار تایید': 'pending',
          'رد شده': 'rejected',
          'باز': 'open',
          'در حال برگزاری': 'ongoing',
          'پایان یافته': 'finished',
          'پیش‌نویس': 'draft',
          'صادرشده': 'issued',
          'پرداخت جزئی': 'partially_paid',
          'پرداخت‌شده': 'paid',
          'لغوشده': 'canceled',
          'در انتظار پرداخت': 'pending_payment',
        }[rawValue] ??
        rawValue;
    final states = <String, (String, Color, Color)>{
      'active': ('فعال', const Color(0xffdcfce7), const Color(0xff15803d)),
      'approved': (
        'تأیید شده',
        const Color(0xffdcfce7),
        const Color(0xff15803d),
      ),
      'available': ('فعال', const Color(0xffdcfce7), const Color(0xff15803d)),
      'open': ('باز', const Color(0xffdcfce7), const Color(0xff15803d)),
      'pending': (
        'در انتظار تأیید',
        const Color(0xfffef9c3),
        const Color(0xffa16207),
      ),
      'inactive': ('غیرفعال', const Color(0xfffee2e2), const Color(0xffb91c1c)),
      'unavailable': (
        'غیرفعال',
        const Color(0xfffee2e2),
        const Color(0xffb91c1c),
      ),
      'rejected': ('رد شده', const Color(0xfffee2e2), const Color(0xffb91c1c)),
      'finished': (
        'پایان یافته',
        const Color(0xfffee2e2),
        const Color(0xffb91c1c),
      ),
      'ongoing': (
        'در حال برگزاری',
        const Color(0xfff3f4f6),
        const Color(0xff374151),
      ),
      'removed': ('حذف شده', const Color(0xffe5e7eb), const Color(0xff374151)),
      'draft': ('پیش‌نویس', const Color(0xfff3f4f6), const Color(0xff4b5563)),
      'issued': ('صادرشده', const Color(0xffdbeafe), const Color(0xff1d4ed8)),
      'partially_paid': (
        'پرداخت جزئی',
        const Color(0xfffef9c3),
        const Color(0xffa16207),
      ),
      'paid': ('پرداخت‌شده', const Color(0xffdcfce7), const Color(0xff15803d)),
      'free': (
        'ماه اول رایگان',
        const Color(0xffe0e7ff),
        const Color(0xff4338ca),
      ),
      'آماده': ('آماده', const Color(0xffdcfce7), const Color(0xff15803d)),
      'در حال تهیه': (
        'در حال تهیه',
        const Color(0xfffef9c3),
        const Color(0xffa16207),
      ),
      'canceled': ('لغوشده', const Color(0xfffee2e2), const Color(0xffb91c1c)),
      'expired': (
        'منقضی‌شده',
        const Color(0xfffee2e2),
        const Color(0xffb91c1c),
      ),
      'pending_payment': (
        'در انتظار پرداخت',
        const Color(0xfffef9c3),
        const Color(0xffa16207),
      ),
      'منتشر شده': (
        'منتشر شده',
        const Color(0xffdcfce7),
        const Color(0xff15803d),
      ),
      'در انتظار': (
        'در انتظار',
        const Color(0xfffef9c3),
        const Color(0xffa16207),
      ),
      'خصوصی': ('خصوصی', const Color(0xfff3e8ff), const Color(0xff7e22ce)),
      'زباله‌دان': (
        'زباله‌دان',
        const Color(0xffe2e8f0),
        const Color(0xff475569),
      ),
      'خوانده‌شده': (
        'خوانده‌شده',
        const Color(0xffdcfce7),
        const Color(0xff15803d),
      ),
      'خوانده‌نشده': (
        'خوانده‌نشده',
        const Color(0xfffee2e2),
        const Color(0xffb91c1c),
      ),
    };
    var state =
        states[value] ??
        (
          panelTableText(value),
          const Color(0xfff3f4f6),
          const Color(0xff374151),
        );
    if (value == 'pending' &&
        (approval || ['classrooms', 'classroom-types'].contains(section))) {
      state = (
        'در انتظار تأیید',
        const Color(0xfffef3c7),
        const Color(0xffb45309),
      );
    }
    if (approval && value == 'approved') {
      state = ('تأییدشده', const Color(0xffd1fae5), const Color(0xff047857));
    }
    if (section == 'members' && value == 'rejected') {
      state = ('رد شده', Colors.black, Colors.white);
    }
    if (section == 'classrooms' && value == 'available') {
      state = ('در دسترس', state.$2, state.$3);
    }
    if (section == 'classrooms' && value == 'unavailable') {
      state = ('خارج از دسترس', state.$2, state.$3);
    }
    if (section == 'national-holidays' && value == 'inactive') {
      state = ('غیرفعال', const Color(0xfff3f4f6), const Color(0xff6b7280));
    }
    final label = approval
        ? state.$1
        : column['key'] != 'status'
        ? state.$1
        : '${row['statusLabel'] ?? (row['status_code'] != null ? row['status'] : null) ?? state.$1}';
    return Material(
      color: state.$2,
      borderRadius: appRadius(context),
      child: InkWell(
        onTap: onPressed,
        borderRadius: appRadius(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: state.$3),
          ),
        ),
      ),
    );
  }
}

class PanelRecordFields extends StatelessWidget {
  const PanelRecordFields({
    super.key,
    required this.fields,
    required this.row,
    this.data = const {},
  });
  final List<Json> fields;
  final Json row;
  final Json data;

  Widget fieldValue(BuildContext context, Json field) {
    final value = panelTableValue(row, '${field['key']}');
    if (field['key'] == 'status' || field['type'] == 'approval') {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: PanelStatusCell(
          row: row,
          column: field,
          section: '${data['_section'] ?? ''}',
        ),
      );
    }
    if (field['key'] == 'currencyId') {
      final currency = objects(
        data['currencies'] ?? [],
      ).where((c) => '${c['id']}' == '$value').firstOrNull;
      if (currency != null) return SelectableText(panelTableText(currency));
    }
    final labels = switch (field['key']) {
      'gender' => const {'male': 'مرد', 'female': 'زن', 'other': 'سایر'},
      'profileVisibility' => const {'private': 'خصوصی', 'public': 'عمومی'},
      'deliveryMode' => const {'online': 'آنلاین', 'in_person': 'حضوری'},
      'repeatType' => const {
        'week': 'هفتگی',
        '2-week': 'دو هفته یک‌بار',
        '3-week': 'سه هفته یک‌بار',
        '4-week': 'چهار هفته یک‌بار',
        'month': 'ماهانه',
        'year': 'سالانه',
        'no-period': 'بدون تکرار',
      },
      _ => const <String, String>{},
    };
    if (labels.containsKey('$value')) return SelectableText(labels['$value']!);
    final options = field['type'] == 'select' || field['type'] == 'multi'
        ? panelSelectOptions(field, {...data, '_form': row})
        : <String, String>{};
    final nested = field['options'] is List
        ? objects(field['options'])
        : <Json>[];
    if (nested.isNotEmpty && (value is Map || value is List)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item
              in value is List ? objects(value) : [optionalObject(value)])
            PanelRecordFields(fields: nested, row: item, data: data),
        ],
      );
    }
    final text = value is List
        ? value
              .map(
                (v) =>
                    options['${v is Map ? v['id'] : v}'] ?? panelTableText(v),
              )
              .join('، ')
        : options['$value'] ?? panelCellText(context, row, field);
    return SelectableText(text);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final field in fields)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                panelCaption(context, field),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              fieldValue(context, field),
            ],
          ),
        ),
    ],
  );
}
