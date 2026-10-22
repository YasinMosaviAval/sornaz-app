import '../Social/social_api.dart';

String panelScheduleStatus(dynamic value) =>
    const {
      'pending': 'در انتظار تأیید',
      'approved': 'تأیید شده',
      'rejected': 'رد شده',
      'completed': 'پایان یافته',
      'canceled': 'لغو شده',
      'cancelled': 'لغو شده',
      'rescheduled': 'زمان‌بندی مجدد',
      'held': 'برگزار شده',
      'postponed': 'به تعویق افتاده',
      'cancellation_pending': 'لغو در انتظار تأیید',
      'in_progress': 'در حال برگزاری',
      'upcoming': 'در انتظار برگزاری',
    }[value] ??
    '${value ?? '—'}';

bool panelScheduleCanCancel(Json row) =>
    row['canCancel'] == true ||
    row['sessionType'] == 'makeup' &&
        ['none', 'rejected'].contains(row['cancellationStatus'] ?? 'none') &&
        ![
          'canceled',
          'rejected',
          'completed',
          'held',
        ].contains(row['bookingStatus']);

DateTime panelNextSessionDate(DateTime date, String repeat) => switch (repeat) {
  'week' => date.add(const Duration(days: 7)),
  '2-week' => date.add(const Duration(days: 14)),
  '3-week' => date.add(const Duration(days: 21)),
  '4-week' => date.add(const Duration(days: 28)),
  'month' => DateTime(date.year, date.month + 1, date.day),
  'year' => DateTime(date.year + 1, date.month, date.day),
  _ => date.add(const Duration(days: 1)),
};
