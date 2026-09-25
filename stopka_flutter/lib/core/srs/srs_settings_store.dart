import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const int defaultNewCardLimit = 20;

/// Reuses the same secure-storage-as-simple-settings pattern as
/// ApiKeyStore — this value isn't secret, but there's no other local
/// settings store in the app yet and adding one just for one int isn't
/// worth a new package.
class SrsSettingsStore {
  static const _newCardLimitKey = 'srs_new_card_limit';

  final FlutterSecureStorage _storage;

  SrsSettingsStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  Future<int> getNewCardLimit() async {
    final raw = await _storage.read(key: _newCardLimitKey);
    return int.tryParse(raw ?? '') ?? defaultNewCardLimit;
  }

  Future<void> setNewCardLimit(int value) => _storage.write(key: _newCardLimitKey, value: value.toString());
}
