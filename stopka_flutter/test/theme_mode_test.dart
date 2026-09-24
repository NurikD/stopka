import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/providers/core_providers.dart';
import 'package:stopka/core/theme/theme_mode_store.dart';

ThemeModeStore _inMemory(Map<String, String> data) {
  return ThemeModeStore(
    read: (key) async => data[key],
    write: (key, value) async => data[key] = value,
  );
}

void main() {
  group('ThemeModeStore', () {
    test('defaults to following the system when nothing is saved', () async {
      expect(await _inMemory({}).load(), ThemeMode.system);
    });

    test('round-trips every mode', () async {
      final data = <String, String>{};
      final store = _inMemory(data);
      for (final mode in ThemeMode.values) {
        await store.save(mode);
        expect(await store.load(), mode);
      }
    });

    test('an unknown stored value falls back to the system theme', () async {
      expect(await _inMemory({'theme_mode': 'sepia'}).load(), ThemeMode.system);
    });
  });

  group('themeModeProvider', () {
    test('picks up the saved choice after start', () async {
      final container = ProviderContainer(
        overrides: [themeModeStoreProvider.overrideWithValue(_inMemory({'theme_mode': 'dark'}))],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system); // until loaded
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('set updates the state and persists it', () async {
      final data = <String, String>{};
      final container = ProviderContainer(overrides: [themeModeStoreProvider.overrideWithValue(_inMemory(data))]);
      addTearDown(container.dispose);

      await container.read(themeModeProvider.notifier).set(ThemeMode.light);

      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(data['theme_mode'], 'light');
    });
  });
}
