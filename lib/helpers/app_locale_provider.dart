import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fa');

  Locale get locale => _locale;

  void setLocale(String langCode) {
    if (_locale.languageCode == langCode) return;
    _locale = Locale(langCode);
    notifyListeners();
  }

  void toggle() {
    setLocale(_locale.languageCode == 'fa' ? 'en' : 'fa');
  }
}
