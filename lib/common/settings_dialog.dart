import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../core/settings_service.dart';
import '../core/snackbar_service.dart';
import '../services/gemini_chat_service.dart';

class SettingsDialog extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const SettingsDialog({super.key, required this.onThemeChanged});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late AppSettings settings;
  bool isLoading = true;
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isApiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      isLoading = true;
    });    
    settings = await SettingsService.getSettings();
    try {
      final geminiService = GeminiChatService();
      if (await geminiService.hasApiKey()) {
        final apiKey = await geminiService.getStoredApiKey();
        _apiKeyController.text = apiKey;
      }
    } catch (e) {
      debugPrint('Error loading API key: $e');
    }    
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveApiKey(String apiKey) async {
    if (apiKey.isEmpty) {
      if (mounted) {
        SnackBarService.showErrorSnackBar(
          context, 
          'API key cannot be empty'
        );
      }
      return;
    }
    try {      
      final geminiService = GeminiChatService();
      await geminiService.updateApiKey(apiKey);
      if (mounted) {
        SnackBarService.showSuccessSnackBar(
          context, 
          'API key saved successfully'
        );
      }
    } catch (e) {
      debugPrint('Error saving API key: $e');
      if (mounted) {
        SnackBarService.showErrorSnackBar(
          context, 
          'Failed to save API key: ${e.toString().replaceAll('Exception: ', '')}'
        );
      }
    }
  }

  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Get key values to preserve
      final themeMode = settings.darkModeEnabled;
      final language = settings.selectedLanguage;
      final textScale = settings.textScale;
      // Save Gemini API key before clearing
      String? apiKey;
      try {
        final geminiService = GeminiChatService();
        if (await geminiService.hasApiKey()) {
          apiKey = await geminiService.getStoredApiKey();
        }
      } catch (e) {
        debugPrint('Error preserving API key: $e');
      }
      // Clear shared preferences
      await prefs.clear();
      await SettingsService.updateSetting(
        darkModeEnabled: themeMode,
        selectedLanguage: language,
        textScale: textScale,
      );      
      // Restore API key if it existed
      if (apiKey != null && apiKey.isNotEmpty) {
        final geminiService = GeminiChatService();
        await geminiService.updateApiKey(apiKey);
      }      
      if (mounted) {
        SnackBarService.showSuccessSnackBar(
          context,
          'User data cleared successfully'
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showErrorSnackBar(
          context,
          'Failed to clear user data: $e'
        );
      }
    }
  }
  
  Future<void> _launchGeminiApiUrl() async {
    final Uri url = Uri.parse('https://aistudio.google.com/app/apikey');
    try {
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showErrorSnackBar(
          context,
          'Could not open URL: $e'
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 600,
        ),
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildSettingsGroup(
                            context,
                            title: 'AI Settings',
                            children: [
                              _buildApiKeyField(),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                              const SizedBox(height: 8),
                              _buildDiscussionToneSelector(),
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
                          _buildSettingsGroup(
                            context,
                            title: 'Data Management',
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Clear User Data'),
                                      content: const Text(
                                        'This will delete all your conversation history, saved selections, and game progress. This action cannot be undone. Your theme and language preferences will be preserved.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            _clearUserData();
                                            Navigator.of(context).pop();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Clear Data'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                label: const Text('Clear User Data', style: TextStyle(color: Colors.red)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () {
                                  _resetSettings();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                child: const Text('Reset to Defaults'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildApiKeyField() {
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
              const Icon(Icons.key),
              const SizedBox(width: 16),
              Text(
                'Gemini API Key',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              hintText: 'Enter your Gemini API key',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(_isApiKeyVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _isApiKeyVisible = !_isApiKeyVisible;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () {
                      if (_apiKeyController.text.isNotEmpty) {
                        _saveApiKey(_apiKeyController.text);
                      }
                    },
                  ),
                ],
              ),
            ),
            obscureText: !_isApiKeyVisible,
            enableSuggestions: false,
            autocorrect: false,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _launchGeminiApiUrl,
            icon: const Icon(Icons.launch, size: 16),
            label: const Text('Get API key from Google AI Studio'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
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

  Widget _buildDiscussionToneSelector() {
    final toneLabels = {
      DiscussionTone.collaborative: 'Collaborative',
      DiscussionTone.confrontational: 'Confrontational',
      DiscussionTone.informative: 'Informative',
      DiscussionTone.persuasive: 'Persuasive',
      DiscussionTone.inquisitive: 'Inquisitive',
    };

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.forum),
        title: const Text('Discussion Tone'),
        trailing: DropdownButton<DiscussionTone>(
          value: settings.discussionTone,
          onChanged: (DiscussionTone? newValue) async {
            if (newValue != null) {
              setState(() {
                settings.discussionTone = newValue;
              });
              await SettingsService.updateSetting(discussionTone: newValue);
            }
          },
          items: DiscussionTone.values.map<DropdownMenuItem<DiscussionTone>>((tone) {
            return DropdownMenuItem<DiscussionTone>(
              value: tone,
              child: Text(toneLabels[tone] ?? tone.name),
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
      SnackBarService.showSuccessSnackBar(
        context,
        'Settings reset to defaults'
      );
    }
  }
}