import 'package:flutter/material.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_theme.dart';

class SettingsDialog extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const SettingsDialog({super.key, required this.onThemeChanged});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late AppSettings settings;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    settings = await SettingsService.getSettings();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(24),
        child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Settings',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSettingsGroup(
                    context,
                    title: 'Display',
                    children: [
                      _buildSwitchSetting(
                        'Dark Mode',
                        settings.darkModeEnabled,
                        (value) async {
                          setState(() => settings.darkModeEnabled = value);
                          await SettingsService.updateSetting(darkModeEnabled: value);
                          widget.onThemeChanged(value);
                        },
                        icon: Icons.dark_mode,
                      ),
                      const SizedBox(height: 8),
                      _buildTextScaleSetting(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsGroup(
                    context,
                    title: 'Game Features',
                    children: [
                      _buildSwitchSetting(
                        'Enable Scenarios',
                        settings.showScenarios,
                        (value) async {
                          setState(() => settings.showScenarios = value);
                          await SettingsService.updateSetting(showScenarios: value);
                        },
                        icon: Icons.crisis_alert,
                      ),
                      const SizedBox(height: 8),
                      _buildSwitchSetting(
                        'Sound Effects',
                        settings.soundEnabled,
                        (value) async {
                          setState(() => settings.soundEnabled = value);
                          await SettingsService.updateSetting(soundEnabled: value);
                        },
                        icon: Icons.volume_up,
                      ),
                      const SizedBox(height: 8),
                      _buildSwitchSetting(
                        'Notifications',
                        settings.notificationsEnabled,
                        (value) async {
                          setState(() => settings.notificationsEnabled = value);
                          await SettingsService.updateSetting(notificationsEnabled: value);
                        },
                        icon: Icons.notifications,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsGroup(
                    context,
                    title: 'Language',
                    children: [
                      _buildLanguageSelector(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: OutlinedButton(
                      onPressed: () {
                        _resetSettings();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Reset to Defaults'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildSwitchSetting(
    String title,
    bool value,
    Function(bool) onChanged, {
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: icon != null ? Icon(icon) : null,
        title: Text(title),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTextScaleSetting() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_fields),
              const SizedBox(width: 16),
              Text(
                'Text Size',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          Slider(
            value: settings.textScale,
            min: 0.8,
            max: 1.4,
            divisions: 6,
            label: '${(settings.textScale * 100).round()}%',
            onChanged: (value) {
              setState(() {
                settings.textScale = value;
              });
            },
            onChangeEnd: (value) async {
              await SettingsService.updateSetting(textScale: value);
            },
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('A', style: TextStyle(fontSize: 14)),
              Text('A', style: TextStyle(fontSize: 14 * 1.4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'es', 'name': 'Español'},
      {'code': 'fr', 'name': 'Français'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.language),
        title: const Text('Language'),
        trailing: DropdownButton<String>(
          value: settings.selectedLanguage,
          onChanged: (String? newValue) async {
            if (newValue != null) {
              setState(() {
                settings.selectedLanguage = newValue;
              });
              await SettingsService.updateSetting(selectedLanguage: newValue);
            }
          },
          items: languages.map<DropdownMenuItem<String>>((language) {
            return DropdownMenuItem<String>(
              value: language['code'],
              child: Text(language['name']!),
            );
          }).toList(),
          underline: Container(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _resetSettings() async {
    final defaultSettings = AppSettings();
    
    setState(() {
      settings = defaultSettings;
    });
    
    await SettingsService.saveSettings(defaultSettings);
    widget.onThemeChanged(defaultSettings.darkModeEnabled);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings reset to defaults')),
      );
    }
  }
}