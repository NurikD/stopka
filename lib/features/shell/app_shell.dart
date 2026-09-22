import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _tabs = [
    (path: '/today', icon: Icons.today_outlined, selectedIcon: Icons.today, label: 'Сегодня'),
    (path: '/courses', icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book, label: 'Курсы'),
    (path: '/practice', icon: Icons.edit_outlined, selectedIcon: Icons.edit, label: 'Практика'),
    (path: '/mistakes', icon: Icons.error_outline, selectedIcon: Icons.error, label: 'Ошибки'),
    (path: '/settings', icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Настройки'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((t) => location.startsWith(t.path));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(_tabs[index].path),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
