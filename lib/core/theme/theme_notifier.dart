import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeBoxKey = 'themeBox';
  static const String _themeModeKey = 'themeMode';
  
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeProvider() {
    _initTheme();
  }
  
  ThemeMode get themeMode => _themeMode;

  Future<void> _initTheme() async {
    try {
      final box = await Hive.openBox(_themeBoxKey);
      final savedThemeMode = box.get(_themeModeKey);
      
      if (savedThemeMode != null) {
        _themeMode = ThemeMode.values[savedThemeMode];
      } else {
        _themeMode = ThemeMode.light;
      }
      notifyListeners();
    } catch (e) {
      _themeMode = ThemeMode.light;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    try {
      final box = await Hive.openBox(_themeBoxKey);
      
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
      
      await box.put(_themeModeKey, _themeMode.index);
      notifyListeners();
    } catch (e) {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }
}