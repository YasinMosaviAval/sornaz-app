import 'package:logger/logger.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:sornaz/helpers/app_constants.dart';

String formatJalaliDate(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    final jalali = Jalali.fromDateTime(date);

    final formatter = jalali.formatter;
    final dayName = [
      AppConstants.SATURDAY,
      AppConstants.SUNDAY,
      AppConstants.MONDAY,
      AppConstants.TUESDAY,
      AppConstants.WEDNESDAY,
      AppConstants.THURSDAY,
      AppConstants.FRIDAY
    ][jalali.weekDay - 1];

    return '$dayName، ${jalali.day} ${formatter.mN} ${jalali.year}';
  } catch (e) {
    return AppConstants.UNKNOWN_DATE;
  }
}

String formatJalali(DateTime date) {
  final j = Jalali.fromDateTime(date);
  return '${j.year}/${j.month.toString().padLeft(2, AppConstants.NUMBER_0)}/${j.day.toString().padLeft(2, AppConstants.NUMBER_0)}';
}



String formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, AppConstants.NUMBER_0);

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
  return '${m.toString().padLeft(2, AppConstants.NUMBER_0)}:${s.toString().padLeft(2, AppConstants.NUMBER_0)}';
}



void loggingSornaz(String message) {
  final logger = Logger();
  logger.i("${AppConstants.LOGGING_SORNAZ} ======= $message");
}