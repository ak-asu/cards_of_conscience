import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/phase_one/phase_one_screen.dart';
import '../features/phase_one/scenario_intro_screen.dart';
import '../features/phase_three/reflective_feedback/enhanced_reflection_screen.dart';
import '../features/phase_two/phase_two_screen.dart';
import '../features/reflection/reflection_screen.dart';
import '../services/scenario_service.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/scenario',
    routes: [
      GoRoute(
        path: '/scenario',
        name: 'scenario',
        builder: (context, state) {
          // Use FutureBuilder to handle the async scenario generation
          return FutureBuilder(
            future: _ensureScenarioLoaded(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Error loading scenario: ${snapshot.error}'));
              }
              
              return ScenarioIntroScreen(
                scenario: ScenarioService.currentScenario!,
                onContinue: () => router.go('/phase1'),
              );
            }
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
  
  // Helper method to ensure a scenario is loaded
  static Future<void> _ensureScenarioLoaded() async {
    if (ScenarioService.currentScenario == null) {
      await ScenarioService.generateRandomScenario();
    }
  }
}