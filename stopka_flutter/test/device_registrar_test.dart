import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/server/app_version_check.dart';
import 'package:stopka/core/server/device_registrar.dart';
import 'package:stopka/core/server/device_token_store.dart';

class _Api implements DeviceApi {
  final String min;
  final Object? registerError;
  int registerCalls = 0;

  _Api({this.min = '1.0.0', this.registerError});

  @override
  Future<String> minAppVersion() async => min;

  @override
  Future<String> register(String appVersion) async {
    registerCalls++;
    if (registerError != null) throw registerError!;
    return 'token-$registerCalls';
  }
}

DeviceTokenStore _store(Map<String, String> memory) =>
    DeviceTokenStore(read: (k) async => memory[k], write: (k, v) async => memory[k] = v);

void main() {
  test('first launch: registers once and keeps the token', () async {
    final memory = <String, String>{};
    final api = _Api();
    final registrar = DeviceRegistrar(api, _store(memory), '1.0.0+1');

    expect((await registrar.check()).status, DeviceStatus.registered);
    expect(memory.values.single, 'token-1');

    expect((await registrar.check()).status, DeviceStatus.registered);
    expect(api.registerCalls, 1, reason: 'a stored token is never requested again');
  });

  test('an app older than the server minimum is told to update, and does not register', () async {
    final api = _Api(min: '1.2.0');
    final result = await DeviceRegistrar(api, _store({}), '1.0.0+1').check();

    expect(result.status, DeviceStatus.updateRequired);
    expect(result.minVersion, '1.2.0');
    expect(api.registerCalls, 0);
  });

  test('the server rejecting the version at registration is also an update prompt', () async {
    final api = _Api(registerError: const ServerRejectedVersion('2.0.0'));
    final result = await DeviceRegistrar(api, _store({}), '1.0.0').check();
    expect(result.status, DeviceStatus.updateRequired);
    expect(result.minVersion, '2.0.0');
  });

  test('no server answer leaves the app working and stores nothing', () async {
    final memory = <String, String>{};
    final result = await DeviceRegistrar(_Api(registerError: const ServerUnavailable()), _store(memory), '1.0.0').check();
    expect(result.status, DeviceStatus.unavailable);
    expect(memory, isEmpty);
  });

  test('version comparison matches the server rules', () {
    expect(isVersionSupported('1.0.0+1', '1.0.0'), isTrue);
    expect(isVersionSupported('1.10.0', '1.9.9'), isTrue);
    expect(isVersionSupported('1.0.0', '1.0.1'), isFalse);
    expect(isVersionSupported('garbage', '1.0.0'), isFalse);
    expect(isVersionSupported('garbage', 'nope'), isTrue);
  });
}
