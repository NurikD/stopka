import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_bottom_nav.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  // The "Словарь" tab hosts courses, units and their words.
  static const _tabs = [
    (path: '/today', item: AppBottomNavItem(icon: Icons.home_outlined, label: 'Сегодня')),
    (path: '/courses', item: AppBottomNavItem(icon: Icons.menu_book_outlined, label: 'Словарь')),
    (path: '/progress', item: AppBottomNavItem(icon: Icons.bar_chart, label: 'Прогресс')),
    (path: '/profile', item: AppBottomNavItem(icon: Icons.person_outline, label: 'Профиль')),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((t) => location.startsWith(t.path));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNav(
        items: [for (final tab in _tabs) tab.item],
        currentIndex: _currentIndex(context),
        onSelected: (index) => context.go(_tabs[index].path),
      ),
    );
  }
}
