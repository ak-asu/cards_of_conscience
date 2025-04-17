import 'package:go_router/go_router.dart';
import '../../features/phase_one/ui/phase_one_screen.dart';
import '../../features/phase_two/ui/phase_two_screen.dart';
import '../../features/reflection/ui/reflection_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/phase1',
    routes: [
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
    ],
  );
}