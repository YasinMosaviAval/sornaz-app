import 'package:shamsi_date/shamsi_date.dart';

String formatJalaliDate(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    final jalali = Jalali.fromDateTime(date);

    final formatter = jalali.formatter;
    final dayName = [
      'شنبه',
      'یکشنبه',
      'دوشنبه',
      'سه‌شنبه',
      'چهارشنبه',
      'پنجشنبه',
      'جمعه',
    ][jalali.weekDay - 1];

    return '$dayName، ${jalali.day} ${formatter.mN} ${jalali.year}';
  } catch (e) {
    return 'تاریخ نامشخص';
  }
}

String formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');

  int hours = d.inHours;
  int minutes = d.inMinutes.remainder(60);
  int seconds = d.inSeconds.remainder(60);

  if (hours > 0) {
    // برای فایل‌های طولانی‌تر از یک ساعت
    return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
  } else {
    // برای فایل‌های معمولی زیر یک ساعت
    return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }
}