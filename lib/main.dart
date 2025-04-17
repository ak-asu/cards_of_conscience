import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'features/phase_one/providers/policy_selection_provider.dart';
import 'features/phase_two/ai_enhancements/emotion_model_service.dart';
import 'features/phase_two/ai_enhancements/negotiation_provider.dart';
import 'features/phase_two/group_comm/services/chat_service.dart';
import 'features/reflection/models/reflection_data_provider.dart';

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
        ChangeNotifierProvider(create: (_) => EnhancedNegotiationProvider()),
        ChangeNotifierProvider(create: (_) => ReflectionDataProvider()),
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
