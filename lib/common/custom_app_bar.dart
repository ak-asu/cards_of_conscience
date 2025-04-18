import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme_notifier.dart';
import 'settings_dialog.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? additionalActions;
  
  const CustomAppBar({
    super.key,
    required this.title,
    this.additionalActions,
  });
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => SettingsDialog(
                onThemeChanged: (isDarkMode) {
                  if (isDarkMode) {
                    themeProvider.setThemeMode(ThemeMode.dark);
                  } else {
                    themeProvider.setThemeMode(ThemeMode.light);
                  }
                },
              ),
            );
          },
        ),
        if (additionalActions != null) ...additionalActions!,
      ],
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}