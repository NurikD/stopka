import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tracks how many LLM requests succeeded today, resetting at local
/// midnight. Reuses the secure-storage-as-settings pattern already used by
/// ApiKeyStore/SrsSettingsStore — this isn't secret, but there's no other
/// local key-value store in the app.
///
/// Storage is injected as plain read/write functions (not a
/// FlutterSecureStorage instance) so tests can swap in an in-memory map
/// without touching a platform channel.
class LlmRequestCounter {
  static const _countKey = 'llm_request_count';
  static const _dateKey = 'llm_request_count_date';

  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  LlmRequestCounter({
    Future<String?> Function(String key)? read,
    Future<void> Function(String key, String value)? write,
  })  : _read = read ?? _defaultRead,
        _write = write ?? _defaultWrite;

  static const _storage = FlutterSecureStorage();
  static Future<String?> _defaultRead(String key) => _storage.read(key: key);
  static Future<void> _defaultWrite(String key, String value) => _storage.write(key: key, value: value);

  Future<int> getTodayCount() async {
    await _resetIfNewDay();
    final raw = await _read(_countKey);
    return int.tryParse(raw ?? '') ?? 0;
  }

  Future<void> increment() async {
    await _resetIfNewDay();
    final current = int.tryParse(await _read(_countKey) ?? '') ?? 0;
    await _write(_countKey, (current + 1).toString());
  }

  Future<void> _resetIfNewDay() async {
    final today = _todayKey();
    final storedDate = await _read(_dateKey);
    if (storedDate != today) {
      await _write(_dateKey, today);
      await _write(_countKey, '0');
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
