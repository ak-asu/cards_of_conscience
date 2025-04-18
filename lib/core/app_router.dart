import 'package:go_router/go_router.dart';

import '../features/phase_one/phase_one_screen.dart';
import '../features/phase_one/scenario_intro_screen.dart';
import '../features/phase_three/reflective_feedback/enhanced_reflection_screen.dart';
import '../features/phase_two/ui/phase_two_screen.dart';
import '../features/reflection/reflection_screen.dart';
import '../models/scenario_service.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/scenario',
    routes: [
      GoRoute(
        path: '/scenario',
        name: 'scenario',
        builder: (context, state) {
          // Generate a random scenario if none exists
          if (ScenarioService.currentScenario == null) {
            ScenarioService.generateRandomScenario();
          }
          
          return ScenarioIntroScreen(
            scenario: ScenarioService.currentScenario!,
            onContinue: () => router.go('/phase1'),
          );
        },
      ),
      GoRoute(
        path: '/phase1',
        name: 'phase1',
        builder: (context, state) => const PhaseOneScreen(),
      ),
      GoRoute(
        path: '/phase2',
        name: 'phase2',
        builder: (context, state) => const PhaseTwoScreen(),
      ),
      GoRoute(
        path: '/reflection',
        name: 'reflection',
        builder: (context, state) => const ReflectionScreen(),
      ),
      GoRoute(
        path: '/phase3/reflection',
        name: 'enhanced_reflection',
        builder: (context, state) => const EnhancedReflectionScreen(),
      ),
    ],
  );
}