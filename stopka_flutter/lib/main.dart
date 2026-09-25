import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/core_providers.dart';
import 'core/router/app_router.dart';
import 'core/server/device_registrar.dart';
import 'core/share/share_intake.dart';
import 'core/theme/app_theme.dart';
import 'features/server/update_required_screen.dart';

void main() {
  runApp(const ProviderScope(child: BootstrapApp()));
}

/// Ensures the single local [Profile] row exists before any screen that
/// reads [currentOwnerIdProvider] renders, via a loading overlay in
/// [MaterialApp.router]'s builder rather than gating navigation itself.
/// Also forwards text shared from other apps to the router.
class BootstrapApp extends ConsumerStatefulWidget {
  const BootstrapApp({super.key});

  @override
  ConsumerState<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends ConsumerState<BootstrapApp> {
  final ShareIntake _shareIntake = ShareIntake();
  StreamSubscription<String>? _shareSub;

  /// A share that arrived before onboarding finished waits here.
  String? _pendingShare;

  @override
  void initState() {
    super.initState();
    _shareIntake.initialText().then(_handleShare);
    _shareSub = _shareIntake.texts.listen(_handleShare);
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    _shareIntake.dispose();
    super.dispose();
  }

  void _handleShare(String? text) {
    if (text == null || !mounted) return;
    if (ref.read(currentProfileProvider).value?.isOnboarded ?? false) {
      ref.read(routerProvider).push('/share', extra: text);
    } else {
      _pendingShare = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentProfileProvider, (_, next) {
      final pending = _pendingShare;
      if (pending != null && (next.value?.isOnboarded ?? false)) {
        _pendingShare = null;
        ref.read(routerProvider).push('/share', extra: pending);
      }
    });

    final bootstrap = ref.watch(_profileBootstrapProvider);
    final themeMode = ref.watch(themeModeProvider);
    final deviceCheck = ref.watch(deviceCheckProvider).value;

    return MaterialApp.router(
      title: 'Стопка',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        if (deviceCheck?.status == DeviceStatus.updateRequired) {
          return UpdateRequiredScreen(minVersion: deviceCheck?.minVersion);
        }
        return bootstrap.when(
          data: (_) => child ?? const SizedBox.shrink(),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            body: Center(
              child: Text('Не удалось запустить приложение: $error'),
            ),
          ),
        );
      },
    );
  }
}

final _profileBootstrapProvider = FutureProvider((ref) {
  return ref.watch(profileRepositoryProvider).ensureProfile();
});
