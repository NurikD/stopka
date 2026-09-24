import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the manual theme choice (light / dark / follow the system).
/// Same injected read/write approach as LlmRequestCounter so tests can use
/// an in-memory map instead of a platform channel.
class ThemeModeStore {
  static const _key = 'theme_mode';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  ThemeModeStore({
    Future<String?> Function(String key)? read,
    Future<void> Function(String key, String value)? write,
  })  : _read = read ?? _defaultRead,
        _write = write ?? _defaultWrite;

  static const _storage = FlutterSecureStorage();
  static Future<String?> _defaultRead(String key) => _storage.read(key: key);
  static Future<void> _defaultWrite(String key, String value) => _storage.write(key: key, value: value);

  Future<ThemeMode> load() async {
    final raw = await _read(_key);
    return ThemeMode.values.where((m) => m.name == raw).firstOrNull ?? ThemeMode.system;
  }

  Future<void> save(ThemeMode mode) => _write(_key, mode.name);
}
