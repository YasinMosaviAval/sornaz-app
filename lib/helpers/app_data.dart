import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_typography.dart';

class AppData extends ChangeNotifier {
  final SharedPreferences? preferences;
  AppData({this.preferences}) {
    _isDark = preferences?.getBool('appearance.dark') ?? false;
    _fontFamily =
        preferences?.getString('appearance.font') ??
        AppTypography.default_font_family;
    fontSize = (preferences?.getDouble('appearance.size') ?? 0).clamp(-2, 2);
    fontWeight = (preferences?.getDouble('appearance.weight') ?? 0).clamp(0, 5);
  }
  bool _isDark = false;
  bool get isDark => _isDark;

  void toggleDarkMode(bool value) {
    _isDark = value;
    preferences?.setBool('appearance.dark', value);
    notifyListeners();
  }

  String _fontFamily = AppTypography.default_font_family;
  String get fontFamily => _fontFamily;

  void updateFontFamily(String font) {
    _fontFamily = font;
    preferences?.setString('appearance.font', font);
    notifyListeners();
  }

  double fontSize = 0;

  Future<void> updateFontSize(double value) async {
    fontSize = value.clamp(-2, 2);
    await preferences?.setDouble('appearance.size', fontSize);
    notifyListeners();
  }

  double fontWeight = 0;

  Future<void> updateFontWeight(double value) async {
    fontWeight = value.clamp(0, 5);
    await preferences?.setDouble('appearance.weight', fontWeight);
    notifyListeners();
  }

  int _bottomNavIndex = 0;
  int get bottomNavIndex => _bottomNavIndex;

  void setBottomNavIndex(int index) {
    _bottomNavIndex = index;
    notifyListeners();
  }
}
