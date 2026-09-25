import 'package:stopka_server/src/generated/protocol.dart';
import 'package:stopka_server/src/logic/device_token.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given the device and catalog endpoints', (sessionBuilder, endpoints) {
    test('registering returns a token and stores only its hash', () async {
      final registration = await endpoints.device.register(sessionBuilder, '1.0.0+1');

      expect(registration.token, isNotEmpty);
      final stored = await Device.db.findById(sessionBuilder.build(), registration.deviceId);
      expect(stored, isNotNull);
      expect(stored!.tokenHash, hashToken(registration.token));
      expect(stored.tokenHash, isNot(registration.token));
      expect(stored.blocked, isFalse);
      expect(stored.appVersion, '1.0.0+1');
    });

    test('two registrations are two different devices', () async {
      final a = await endpoints.device.register(sessionBuilder, '1.0.0');
      final b = await endpoints.device.register(sessionBuilder, '1.0.0');
      expect(a.deviceId, isNot(b.deviceId));
      expect(a.token, isNot(b.token));
    });

    test('an app older than the minimum is told to update', () async {
      await expectLater(
        endpoints.device.register(sessionBuilder, '0.0.1'),
        throwsA(isA<AppUpdateRequired>().having((e) => e.minVersion, 'minVersion', isNotEmpty)),
      );
    });

    test('the minimum app version is available without registering', () async {
      final min = await endpoints.catalog.getMinAppVersion(sessionBuilder);
      expect(min, matches(RegExp(r'^\d+\.\d+\.\d+')));
    });
  });
}
