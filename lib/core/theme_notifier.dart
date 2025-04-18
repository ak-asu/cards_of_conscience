import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'settings_service.dart';

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
      // First check if we have settings in the new settings service
      final settings = await SettingsService.getSettings();
      final isDarkMode = settings.darkModeEnabled;
      
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
      
      // Optional: sync with the legacy storage
      try {
        final box = await Hive.openBox(_themeBoxKey);
        await box.put(_themeModeKey, _themeMode.index);
      } catch (_) {
        // Ignore legacy storage errors
      }
    } catch (e) {
      // Fall back to legacy storage if settings service fails
      try {
        final box = await Hive.openBox(_themeBoxKey);
        final savedThemeMode = box.get(_themeModeKey);
        
        if (savedThemeMode != null) {
          _themeMode = ThemeMode.values[savedThemeMode];
        } else {
          _themeMode = ThemeMode.light;
        }
      } catch (_) {
        _themeMode = ThemeMode.light;
      }
      
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    final newThemeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newThemeMode);
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    
    try {
      // Update in settings service
      final isDarkMode = mode == ThemeMode.dark;
      await SettingsService.updateSetting(darkModeEnabled: isDarkMode);
      
      // Optional: sync with legacy storage
      try {
        final box = await Hive.openBox(_themeBoxKey);
        await box.put(_themeModeKey, _themeMode.index);
      } catch (_) {
        // Ignore legacy storage errors
      }
    } catch (e) {
      // If settings service fails, at least we updated the in-memory value
    }
    
    notifyListeners();
  }
}