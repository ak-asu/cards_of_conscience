import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/app_router.dart';
import 'core/app_theme.dart';
import 'core/theme_notifier.dart';
import 'models/enhanced_reflection_data.dart';
import 'providers/enhanced_negotiation_provider.dart';
import 'providers/enhanced_reflection_provider.dart';
import 'providers/policy_selection_provider.dart';
import 'services/chat_service.dart';
import 'services/emotion_model_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
 
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PolicyDomainsProvider()),
        ChangeNotifierProvider(create: (_) => AgentsProvider()),
        ChangeNotifierProvider(create: (_) => PolicySelectionProvider()),
        ChangeNotifierProxyProvider2<PolicyDomainsProvider, AgentsProvider, AISelectionsProvider>(
          create: (context) => AISelectionsProvider(
            Provider.of<PolicyDomainsProvider>(context, listen: false),
            Provider.of<AgentsProvider>(context, listen: false)
          ),
          update: (context, policyDomainsProvider, agentsProvider, previous) => 
            previous ?? AISelectionsProvider(policyDomainsProvider, agentsProvider),
        ),
        ChangeNotifierProvider(create: (_) => EmotionModelService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProxyProvider<ChatService, EnhancedReflectionProvider>(
          create: (context) => EnhancedReflectionProvider(
            chatService: Provider.of<ChatService>(context, listen: false),
          ),
          update: (context, chatService, previous) => 
            previous ?? EnhancedReflectionProvider(chatService: chatService),
        ),
        ChangeNotifierProvider(create: (_) => EnhancedReflectionData()),
        ChangeNotifierProvider(create: (_) => EnhancedNegotiationProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Cards of Conscience',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
