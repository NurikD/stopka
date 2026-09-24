import 'package:flutter_test/flutter_test.dart';

import 'package:stopka/core/flags/feature_flags.dart';
import 'package:stopka/core/theme/app_theme.dart';

void main() {
  test('feature flags for unbuilt functionality default to off', () {
    expect(FeatureFlags.auth, isFalse);
    expect(FeatureFlags.cloudSync, isFalse);
    expect(FeatureFlags.sharedSets, isFalse);
    expect(FeatureFlags.analytics, isFalse);
  });

  test('app theme uses Material 3 in both brightnesses', () {
    expect(AppTheme.light().useMaterial3, isTrue);
    expect(AppTheme.dark().useMaterial3, isTrue);
  });
}
