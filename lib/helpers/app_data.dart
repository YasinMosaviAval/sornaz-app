import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_typography.dart';

class AppData extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  void toggleDarkMode(bool value) {
    _isDark = value;
    notifyListeners();
  }

  String _fontFamily = AppTypography.default_font_family;
  String get fontFamily => _fontFamily;

  void updateFontFamily(String font) {
    _fontFamily = font;
    notifyListeners();
  }

  double textSize = 0;

  Future<void> updateTextSize(double value) async {
    textSize = value;
    notifyListeners();
  }

  int _bottomNavIndex = 0;
  int get bottomNavIndex => _bottomNavIndex;

  void setBottomNavIndex(int index) {
    _bottomNavIndex = index;
    notifyListeners();
  }
}

// ==