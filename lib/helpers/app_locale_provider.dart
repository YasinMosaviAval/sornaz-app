import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_constants.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale(AppConstants.LOCALIZATION_FA);

  Locale get locale => _locale;

  void setLocale(String langCode) {
    if (_locale.languageCode == langCode) return;
    _locale = Locale(langCode);
    notifyListeners();
  }

  void toggle() {
    setLocale(_locale.languageCode == AppConstants.LOCALIZATION_FA ? AppConstants.LOCALIZATION_EN : AppConstants.LOCALIZATION_FA);
  }
}
