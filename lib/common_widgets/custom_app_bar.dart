import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme_notifier.dart';

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
          icon: Icon(
            themeProvider.themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
          ),
          onPressed: () => themeProvider.toggleTheme(),
          tooltip: themeProvider.themeMode == ThemeMode.light ? 'Switch to dark mode' : 'Switch to light mode',
        ),
        if (additionalActions != null) ...additionalActions!,
      ],
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}