import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

class _JalaliPickerDate implements DateTime {
  _JalaliPickerDate(this.gregorian);
  final DateTime gregorian;
  Jalali get jalali => Jalali.fromDateTime(gregorian);
  @override
  int get year => jalali.year;
  @override
  int get month => jalali.month;
  @override
  int get day => jalali.day;
  @override
  int get hour => gregorian.hour;
  @override
  int get minute => gregorian.minute;
  @override
  int get second => gregorian.second;
  @override
  int get millisecond => gregorian.millisecond;
  @override
  int get microsecond => gregorian.microsecond;
  @override
  int get weekday => gregorian.weekday;
  @override
  bool get isUtc => gregorian.isUtc;
  @override
  int get millisecondsSinceEpoch => gregorian.millisecondsSinceEpoch;
  @override
  int get microsecondsSinceEpoch => gregorian.microsecondsSinceEpoch;
  @override
  String get timeZoneName => gregorian.timeZoneName;
  @override
  Duration get timeZoneOffset => gregorian.timeZoneOffset;
  DateTime actual(DateTime other) =>
      other is _JalaliPickerDate ? other.gregorian : other;
  @override
  bool isBefore(DateTime other) => gregorian.isBefore(actual(other));
  @override
  bool isAfter(DateTime other) => gregorian.isAfter(actual(other));
  @override
  bool isAtSameMomentAs(DateTime other) =>
      gregorian.isAtSameMomentAs(actual(other));
  @override
  int compareTo(DateTime other) => gregorian.compareTo(actual(other));
  @override
  Duration difference(DateTime other) => gregorian.difference(actual(other));
  @override
  DateTime add(Duration duration) => _JalaliPickerDate(gregorian.add(duration));
  @override
  DateTime subtract(Duration duration) =>
      _JalaliPickerDate(gregorian.subtract(duration));
  @override
  DateTime toUtc() => _JalaliPickerDate(gregorian.toUtc());
  @override
  DateTime toLocal() => _JalaliPickerDate(gregorian.toLocal());
  @override
  String toIso8601String() => gregorian.toIso8601String();
  @override
  String toString() => '$year/$month/$day';
  @override
  int get hashCode => gregorian.hashCode;
  @override
  bool operator ==(Object other) =>
      other is _JalaliPickerDate && gregorian == other.gregorian;
}

/// Material's existing picker, with Jalali calendar coordinates. Only the
/// picker uses encoded dates; callers and the API keep Gregorian ISO dates.
class JalaliCalendarDelegate extends GregorianCalendarDelegate {
  const JalaliCalendarDelegate();
  static DateTime encode(DateTime date) {
    return _JalaliPickerDate(date);
  }

  static DateTime decode(DateTime date) => date is _JalaliPickerDate
      ? date.gregorian
      : Jalali(date.year, date.month, date.day).toDateTime();
  @override
  DateTime dateOnly(DateTime date) => getDay(date.year, date.month, date.day);
  @override
  int monthDelta(DateTime startDate, DateTime endDate) =>
      (endDate.year - startDate.year) * 12 + endDate.month - startDate.month;
  @override
  DateTime getMonth(int year, int month) => getDay(year, month, 1);
  @override
  DateTime getDay(int year, int month, int day) =>
      encode(Jalali(year, month, day).toDateTime());
  @override
  DateTime addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) {
    final total = monthDate.year * 12 + monthDate.month - 1 + monthsToAdd;
    return getMonth(total ~/ 12, total % 12 + 1);
  }

  @override
  DateTime now() => encode(DateTime.now());
  @override
  DateTime addDaysToDate(DateTime date, int days) =>
      encode(decode(date).add(Duration(days: days)));
  @override
  int getDaysInMonth(int year, int month) => Jalali(year, month).monthLength;
  @override
  int firstDayOffset(
    int year,
    int month,
    MaterialLocalizations localizations,
  ) =>
      (Jalali(year, month).toDateTime().weekday % 7 -
          localizations.firstDayOfWeekIndex +
          7) %
      7;
  @override
  String formatYear(int year, MaterialLocalizations localizations) =>
      localizations.formatDecimal(year);
  String month(DateTime date) =>
      Jalali(date.year, date.month, date.day).formatter.mN;
  @override
  String formatMonthYear(DateTime date, MaterialLocalizations localizations) =>
      '${month(date)} ${formatYear(date.year, localizations)}';
  @override
  String formatShortMonthDay(
    DateTime date,
    MaterialLocalizations localizations,
  ) => '${localizations.formatDecimal(date.day)} ${month(date)}';
  @override
  String formatMediumDate(DateTime date, MaterialLocalizations localizations) =>
      formatShortMonthDay(date, localizations);
  @override
  String formatShortDate(DateTime date, MaterialLocalizations localizations) =>
      '${formatShortMonthDay(date, localizations)} ${formatYear(date.year, localizations)}';
  @override
  String formatFullDate(DateTime date, MaterialLocalizations localizations) =>
      '${Jalali(date.year, date.month, date.day).formatter.wN}، ${formatShortDate(date, localizations)}';
  @override
  String formatCompactDate(
    DateTime date,
    MaterialLocalizations localizations,
  ) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  @override
  String dateHelpText(MaterialLocalizations localizations) => 'yyyy/mm/dd';
  @override
  DateTime? parseCompactDate(
    String? inputString,
    MaterialLocalizations localizations,
  ) {
    var value = inputString ?? '';
    for (var i = 0; i < 10; i++) {
      value = value
          .replaceAll('۰۱۲۳۴۵۶۷۸۹'[i], '$i')
          .replaceAll('٠١٢٣٤٥٦٧٨٩'[i], '$i');
    }
    final match = RegExp(
      r'^(\d{4})[/-](\d{1,2})[/-](\d{1,2})$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    try {
      final j = Jalali(
        int.parse(match[1]!),
        int.parse(match[2]!),
        int.parse(match[3]!),
      );
      return encode(j.toDateTime());
    } catch (_) {
      return null;
    }
  }
}

Future<DateTime?> showSornazDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  final selected = await showDatePicker(
    context: context,
    initialDate: JalaliCalendarDelegate.encode(initialDate),
    firstDate: JalaliCalendarDelegate.encode(firstDate),
    lastDate: JalaliCalendarDelegate.encode(lastDate),
    calendarDelegate: const JalaliCalendarDelegate(),
  );
  return selected == null ? null : JalaliCalendarDelegate.decode(selected);
}
