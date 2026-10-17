import 'package:flutter/widgets.dart';
import '../Social/social_api.dart';

String panelCaption(BuildContext context, Json field) {
  if (Localizations.localeOf(context).languageCode == 'fa') {
    return '${field['label'] ?? 'اطلاعات'}';
  }
  if (field['en'] != null) return '${field['en']}';
  const labels = {
    'عنوان': 'Title',
    'نام': 'Name',
    'خلاصه': 'Summary',
    'توضیحات': 'Description',
    'وضعیت': 'Status',
    'نوع': 'Type',
    'دسته': 'Category',
    'سازمان': 'Organization',
    'شعبه': 'Branch',
    'آموزشگاه': 'Academy',
    'درس': 'Lesson',
    'سطح': 'Level',
    'دوره': 'Course',
    'ترم': 'Term',
    'کلاس': 'Classroom',
    'هنرجو': 'Student',
    'مدرس': 'Teacher',
    'استاد': 'Teacher',
    'مبلغ': 'Amount',
    'تاریخ': 'Date',
    'زمان شروع': 'Start time',
    'زمان پایان': 'End time',
    'تاریخ شروع': 'Start date',
    'تاریخ پایان': 'End date',
    'تاریخ خاتمه': 'End date',
    'ردیف': 'No.',
    'عنوان / نام': 'Title / Name',
    'عنوان / درس': 'Title / Lesson',
    'نام هنرجو': 'Student name',
    'نام دوره': 'Course name',
    'نام کلاس': 'Classroom name',
    'نوع قرارداد': 'Contract type',
    'عنوان قرارداد': 'Contract title',
    'مبلغ قرارداد': 'Contract amount',
    'نوع کلاس': 'Classroom type',
    'ظرفیت': 'Capacity',
    'تجهیزات': 'Equipment',
    'ایجادکننده': 'Created by',
    'دامنه': 'Scope',
    'درجه': 'Level',
    'والد': 'Parent',
    'مجوزها': 'Permissions',
    'نقش‌ها': 'Roles',
    'نمایش در پنل': 'Panel visibility',
    'منبع': 'Source',
    'عملیات': 'Actions',
    'خطر': 'Risk',
    'کاربر': 'User',
    'گیرنده': 'Recipient',
    'فرستنده': 'Sender',
    'شماره تماس': 'Phone',
    'کد ملی': 'National ID',
    'جنسیت': 'Gender',
    'تاریخ تولد': 'Birth date',
    'شماره': 'Number',
    'روز': 'Day',
    'ساعت': 'Time',
    'دوره تکرار': 'Recurrence',
    'منطقه زمانی': 'Time zone',
    'زمان': 'Time',
    'امتیاز': 'Points',
    'کنترل تکرار': 'Repeat control',
    'بازه زمانی': 'Period',
    'تاریخ تولید': 'Generated on',
    'از تاریخ': 'From date',
    'تا تاریخ': 'To date',
    'شاخص‌ها': 'Metrics',
    'شاخص': 'Metric',
    'مقدار': 'Value',
    'خلاصه گزارش': 'Report summary',
    'همه شعبه‌ها': 'All branches',
    'همه وضعیت‌ها': 'All statuses',
    'همه انواع گزارش': 'All report types',
    'همه بازه‌ها': 'All periods',
    'همه نوع قرارداد': 'All contract types',
  };
  final translated = labels[field['label']];
  if (translated != null) return translated;
  final text = '${field['key'] ?? 'Details'}'
      .replaceAll(RegExp(r'(_id|_ids|Id|Ids)$'), '')
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
  return text.isEmpty
      ? 'Details'
      : '${text[0].toUpperCase()}${text.substring(1)}';
}
