import 'app_version_check.dart';
import 'device_token_store.dart';

/// What the server said, reduced to what the app needs to know.
sealed class ServerDeviceError implements Exception {
  const ServerDeviceError();
}

class ServerRejectedVersion extends ServerDeviceError {
  final String minVersion;

  const ServerRejectedVersion(this.minVersion);
}

/// No answer: no network, server down, too many registrations today, ...
class ServerUnavailable extends ServerDeviceError {
  const ServerUnavailable();
}

/// The two calls the app needs at start, behind an interface so the logic
/// below is testable without a network or the generated client.
abstract class DeviceApi {
  Future<String> minAppVersion();

  /// Returns the new device token.
  Future<String> register(String appVersion);
}

enum DeviceStatus {
  /// The app was built without a server address; nothing to do.
  disabled,
  registered,
  updateRequired,

  /// Could not reach the server this time; the app keeps working and tries
  /// again at the next start.
  unavailable,
}

class DeviceCheck {
  final DeviceStatus status;
  final String? minVersion;

  const DeviceCheck(this.status, {this.minVersion});
}

/// At every start: is this app new enough for the server, and does this
/// installation have a device token yet? A token is requested once and kept.
class DeviceRegistrar {
  final DeviceApi _api;
  final DeviceTokenStore _store;
  final String _appVersion;

  DeviceRegistrar(this._api, this._store, this._appVersion);

  Future<DeviceCheck> check() async {
    try {
      final min = await _api.minAppVersion();
      if (!isVersionSupported(_appVersion, min)) {
        return DeviceCheck(DeviceStatus.updateRequired, minVersion: min);
      }
      if (await _store.load() != null) return const DeviceCheck(DeviceStatus.registered);

      final token = await _api.register(_appVersion);
      await _store.save(token);
      return const DeviceCheck(DeviceStatus.registered);
    } on ServerRejectedVersion catch (e) {
      return DeviceCheck(DeviceStatus.updateRequired, minVersion: e.minVersion);
    } on ServerDeviceError {
      return const DeviceCheck(DeviceStatus.unavailable);
    }
  }
}
