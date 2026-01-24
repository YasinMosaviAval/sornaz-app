import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'storage_type.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  StorageType _storageType = StorageType.hive;

  StorageType get storageType => _storageType;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.STORAGE_TYPE);
    if (saved != null) {
      _storageType = StorageType.values.firstWhere(
        (e) => e.toString() == saved,
        orElse: () => StorageType.hive,
      );
    }
    notifyListeners();
  }

  Future<void> setStorageType(StorageType type) async {
    if (_storageType == type) return;
    _storageType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.STORAGE_TYPE, type.toString());
    notifyListeners();
  }
}