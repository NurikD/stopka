import 'package:go_router/go_router.dart';

import '../../features/courses/courses_screen.dart';
import '../../features/mistakes/mistakes_screen.dart';
import '../../features/practice/practice_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/today/today_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/today',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/today', builder: (context, state) => const TodayScreen()),
        GoRoute(path: '/courses', builder: (context, state) => const CoursesScreen()),
        GoRoute(path: '/practice', builder: (context, state) => const PracticeScreen()),
        GoRoute(path: '/mistakes', builder: (context, state) => const MistakesScreen()),
        GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      ],
    ),
  ],
);
