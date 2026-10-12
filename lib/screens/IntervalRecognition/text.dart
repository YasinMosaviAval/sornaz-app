import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_translations.dart';

class IntervalText {
  IntervalText(BuildContext context)
    : locale =
          context.watch<LocaleProvider?>()?.locale ??
          Localizations.localeOf(context);
  final Locale locale;
  TextDirection get direction =>
      locale.languageCode == 'fa' ? TextDirection.rtl : TextDirection.ltr;
  String number(int value) {
    final text = value.toString();
    if (locale.languageCode != 'fa') return text;
    return text.split('').map((c) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(c)]).join();
  }

  String call(String key, [Map<String, String> arguments = const {}]) {
    var value = AppLocalizations(locale).translate(key);
    for (final entry in arguments.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }
}
