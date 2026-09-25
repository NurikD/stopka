import 'dart:math';

import 'package:stopka_server/src/logic/device_token.dart';
import 'package:stopka_server/src/logic/registration_guard.dart';
import 'package:stopka_server/src/logic/server_settings.dart';
import 'package:test/test.dart';

void main() {
  test('tokens are long, URL-safe and different every time', () {
    final a = generateDeviceToken();
    final b = generateDeviceToken();
    expect(a, isNot(b));
    expect(a.length, greaterThanOrEqualTo(43));
    expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(a), isTrue);
  });

  test('a seeded generator is repeatable, so the token logic itself can be tested', () {
    expect(generateDeviceToken(Random(1)), generateDeviceToken(Random(1)));
  });

  test('the stored hash is stable, does not contain the token, and differs per token', () {
    final token = generateDeviceToken();
    expect(hashToken(token), hashToken(token));
    expect(hashToken(token), isNot(contains(token)));
    expect(hashToken(token), isNot(hashToken('$token!')));
    expect(hashToken(token).length, 64);
  });

  test('the address hash depends on the salt', () {
    expect(hashIp('1.2.3.4', 'a'), hashIp('1.2.3.4', 'a'));
    expect(hashIp('1.2.3.4', 'a'), isNot(hashIp('1.2.3.4', 'b')));
    expect(hashIp('1.2.3.4', 'a'), isNot(hashIp('1.2.3.5', 'a')));
  });

  test('registration is allowed until the daily cap is reached', () {
    expect(registrationAllowed(recentRegistrations: 9, maxPerDay: 10), isTrue);
    expect(registrationAllowed(recentRegistrations: 10, maxPerDay: 10), isFalse);
    expect(registrationAllowed(recentRegistrations: 0, maxPerDay: 0), isFalse);
  });

  group('server settings', () {
    test('are read from yaml', () {
      final s = ServerSettings.parse('''
minAppVersion: 1.2.0
registration:
  maxPerIpPerDay: 3
  trustForwardedFor: true
''');
      expect(s.minAppVersion, '1.2.0');
      expect(s.maxRegistrationsPerIpPerDay, 3);
      expect(s.trustForwardedFor, isTrue);
    });

    test('fall back to safe defaults', () {
      final s = ServerSettings.parse('');
      expect(s.minAppVersion, '1.0.0');
      expect(s.maxRegistrationsPerIpPerDay, 10);
      expect(s.trustForwardedFor, isFalse); // never trust the header by default
    });

    test('the checked-in file parses', () {
      final s = ServerSettings.load();
      expect(s.minAppVersion, isNotEmpty);
    });
  });
}
