import 'package:stopka_client/stopka_client.dart';

import 'device_registrar.dart';

/// [DeviceApi] over the generated Serverpod client.
class ServerpodDeviceApi implements DeviceApi {
  final Client _client;

  ServerpodDeviceApi(this._client);

  @override
  Future<String> minAppVersion() async {
    try {
      return await _client.catalog.getMinAppVersion();
    } on Exception {
      throw const ServerUnavailable();
    }
  }

  @override
  Future<String> register(String appVersion) async {
    try {
      final registration = await _client.device.register(appVersion);
      return registration.token;
    } on AppUpdateRequired catch (e) {
      throw ServerRejectedVersion(e.minVersion);
    } on Exception {
      throw const ServerUnavailable();
    }
  }
}
