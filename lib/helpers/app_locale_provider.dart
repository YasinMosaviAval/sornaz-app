import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_constants.dart';

class LocaleProvider extends ChangeNotifier {
  final SharedPreferences? preferences;
  LocaleProvider({this.preferences}) {
    final saved = preferences?.getString('appearance.language');
    if (saved == 'en' || saved == 'fa') _locale = Locale(saved!);
  }
  Locale _locale = const Locale(AppConstants.LOCALIZATION_FA);

  Locale get locale => _locale;

  void setLocale(String langCode) {
    if ((langCode != 'en' && langCode != 'fa') ||
        _locale.languageCode == langCode)
      return;
    _locale = Locale(langCode);
    preferences?.setString('appearance.language', langCode);
    notifyListeners();
  }

  void toggle() {
    setLocale(
      _locale.languageCode == AppConstants.LOCALIZATION_FA
          ? AppConstants.LOCALIZATION_EN
          : AppConstants.LOCALIZATION_FA,
    );
  }
}
