import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_bottom_nav.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _tabs = [
    (path: '/today', item: AppBottomNavItem(icon: Icons.today_outlined, label: 'Сегодня')),
    (path: '/courses', item: AppBottomNavItem(icon: Icons.menu_book_outlined, label: 'Курсы')),
    (path: '/practice', item: AppBottomNavItem(icon: Icons.edit_outlined, label: 'Практика')),
    (path: '/mistakes', item: AppBottomNavItem(icon: Icons.error_outline, label: 'Ошибки')),
    (path: '/settings', item: AppBottomNavItem(icon: Icons.settings_outlined, label: 'Настройки')),
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
