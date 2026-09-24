import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/core_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: BootstrapApp()));
}

/// Ensures the single local [Profile] row exists before any screen that
/// reads [currentOwnerIdProvider] renders, via a loading overlay in
/// [MaterialApp.router]'s builder rather than gating navigation itself.
class BootstrapApp extends ConsumerWidget {
  const BootstrapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(_profileBootstrapProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Стопка',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        return bootstrap.when(
          data: (_) => child ?? const SizedBox.shrink(),
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            body: Center(child: Text('Не удалось запустить приложение: $error')),
          ),
        );
      },
    );
  }
}

final _profileBootstrapProvider = FutureProvider((ref) {
  return ref.watch(profileRepositoryProvider).ensureProfile();
});
