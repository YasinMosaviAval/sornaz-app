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
  final minutes = twoDigits(d.inMinutes.remainder(60));
  final seconds = twoDigits(d.inSeconds.remainder(60));
  return '$minutes:$seconds';
}