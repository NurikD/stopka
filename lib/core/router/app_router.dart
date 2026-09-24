import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/core_providers.dart';

import '../../features/courses/course_detail_screen.dart';
import '../../features/courses/courses_screen.dart';
import '../../features/courses/unit_detail_screen.dart';
import '../../features/dictation/dictation_setup_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/today/today_screen.dart';

/// Until the profile says onboarding is done, every route leads to
/// `/onboarding`; afterwards that route leads back to Today.
String? onboardingRedirect({
  required bool? onboarded,
  required String location,
}) {
  if (onboarded == null) return null; // profile still loading
  final onOnboarding = location == '/onboarding';
  if (!onboarded && !onOnboarding) return '/onboarding';
  if (onboarded && onOnboarding) return '/today';
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(currentProfileProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/today',
    refreshListenable: refresh,
    redirect: (context, state) => onboardingRedirect(
      onboarded: ref.read(currentProfileProvider).value?.isOnboarded,
      location: state.matchedLocation,
    ),
    routes: _routes,
  );
  ref.onDispose(router.dispose);
  return router;
});

final _routes = <RouteBase>[
  ShellRoute(
    builder: (context, state, child) => AppShell(child: child),
    routes: [
      GoRoute(path: '/today', builder: (context, state) => const TodayScreen()),
      GoRoute(
        path: '/courses',
        builder: (context, state) => const CoursesScreen(),
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  ),
  GoRoute(
    path: '/courses/:courseId',
    builder: (context, state) =>
        CourseDetailScreen(courseId: state.pathParameters['courseId']!),
  ),
  GoRoute(
    path: '/courses/:courseId/units/:unitId',
    builder: (context, state) => UnitDetailScreen(
      courseId: state.pathParameters['courseId']!,
      unitId: state.pathParameters['unitId']!,
    ),
  ),
  GoRoute(
    path: '/onboarding',
    builder: (context, state) => OnboardingScreen(
      onDone: (result) {
        final router = GoRouter.of(context);
        router.go('/today');
        router.push(
          '/dictation/${result.setId}?title=${Uri.encodeComponent('Первые слова')}',
        );
      },
    ),
  ),
  GoRoute(
    path: '/dictation/:setId',
    builder: (context, state) => DictationSetupScreen(
      setId: state.pathParameters['setId']!,
      setTitle: state.uri.queryParameters['title'] ?? 'слова',
    ),
  ),
];
