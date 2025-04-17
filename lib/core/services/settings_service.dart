import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  bool soundEnabled;
  bool notificationsEnabled;
  bool darkModeEnabled;
  bool showScenarios;
  String selectedLanguage;
  double textScale;

  AppSettings({
    this.soundEnabled = true,
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
    this.showScenarios = true,
    this.selectedLanguage = 'en',
    this.textScale = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'soundEnabled': soundEnabled,
      'notificationsEnabled': notificationsEnabled,
      'darkModeEnabled': darkModeEnabled,
      'showScenarios': showScenarios,
      'selectedLanguage': selectedLanguage,
      'textScale': textScale,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      soundEnabled: json['soundEnabled'] ?? true,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      darkModeEnabled: json['darkModeEnabled'] ?? false,
      showScenarios: json['showScenarios'] ?? true,
      selectedLanguage: json['selectedLanguage'] ?? 'en',
      textScale: json['textScale'] ?? 1.0,
    );
  }
}

class SettingsService {
  static const String _settingsKey = 'app_settings';
  static AppSettings? _cachedSettings;

  static Future<AppSettings> getSettings() async {
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }

    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);
    
    if (settingsJson != null) {
      try {
        _cachedSettings = AppSettings.fromJson(json.decode(settingsJson));
        return _cachedSettings!;
      } catch (e) {
        // If there's an error parsing, return default settings
        _cachedSettings = AppSettings();
        return _cachedSettings!;
      }
    } else {
      // No saved settings, return defaults
      _cachedSettings = AppSettings();
      return _cachedSettings!;
    }
  }

  static Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, json.encode(settings.toJson()));
    _cachedSettings = settings;
  }

  static Future<void> updateSetting({
    bool? soundEnabled,
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    bool? showScenarios,
    String? selectedLanguage,
    double? textScale,
  }) async {
    final settings = await getSettings();
    
    if (soundEnabled != null) settings.soundEnabled = soundEnabled;
    if (notificationsEnabled != null) settings.notificationsEnabled = notificationsEnabled;
    if (darkModeEnabled != null) settings.darkModeEnabled = darkModeEnabled;
    if (showScenarios != null) settings.showScenarios = showScenarios;
    if (selectedLanguage != null) settings.selectedLanguage = selectedLanguage;
    if (textScale != null) settings.textScale = textScale;
    
    await saveSettings(settings);
  }
}