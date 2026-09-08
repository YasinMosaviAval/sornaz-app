import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_constants.dart';

class AppLocalizations {
  static final Map<String, Map<String, String>> _localizedValues = {
    AppConstants.LOCALIZATION_FA: AppStrings.fa,
    AppConstants.LOCALIZATION_EN: AppStrings.en,
  };

  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return AppLocalizations(
      Provider.of<LocaleProvider?>(context, listen: false)?.locale ??
          Localizations.localeOf(context),
    );
  }

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues[AppConstants.LOCALIZATION_EN]![key] ??
        key;
  }
}

extension Translate on String {
  String translate(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return loc?.translate(this) ?? this;
  }
}
