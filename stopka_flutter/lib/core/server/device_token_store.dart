import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the secret device token from the server. Same injected read/write
/// approach as the other stores, so tests use a map instead of a platform
/// channel.
class DeviceTokenStore {
  static const _key = 'device_token';
  static const _storage = FlutterSecureStorage();

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  DeviceTokenStore({
    Future<String?> Function(String key)? read,
    Future<void> Function(String key, String value)? write,
  })  : _read = read ?? ((key) => _storage.read(key: key)),
        _write = write ?? ((key, value) => _storage.write(key: key, value: value));

  Future<String?> load() async {
    final token = await _read(_key);
    return (token == null || token.isEmpty) ? null : token;
  }

  Future<void> save(String token) => _write(_key, token);

  /// Forgets the token, so the next start registers the device again.
  Future<void> clear() => _write(_key, '');
}
