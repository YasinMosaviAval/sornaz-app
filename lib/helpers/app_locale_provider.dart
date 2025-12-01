import 'package:flutter/material.dart';

// class LocaleProvider extends ChangeNotifier {
//   Locale _locale = const Locale('fa');

//   Locale get locale => _locale;

//   void setLocale(String langCode) {
//     if (!['fa', 'en'].contains(langCode)) return;
//     _locale = Locale(langCode);
//     notifyListeners();
//   }

//   void toggleLanguage() {
//     if (_locale.languageCode == 'fa') {
//       setLocale('en');
//     } else {
//       setLocale('fa');
//     }
//   }
// }

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fa');

  Locale get locale => _locale;

  void setLocale(String langCode) {
    if (_locale.languageCode == langCode) return;
    _locale = Locale(langCode);
    notifyListeners(); // این خط باعث می‌شه MaterialApp دوباره ساخته بشه
  }

  void toggle() {
    setLocale(_locale.languageCode == 'fa' ? 'en' : 'fa');
  }
}
