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
    return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
  } else {
    return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }
}


String formatSeconds(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String formatJalali(DateTime date) {
  final j = Jalali.fromDateTime(date);
  return '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';
}
