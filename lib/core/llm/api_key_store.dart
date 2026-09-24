import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Default model kept in sync with the current fast Gemini model
/// (see ai.google.dev/gemini-api/docs/models — verify before changing).
const String defaultGeminiModel = 'gemini-3.8-flash';

class ApiKeyStore {
  static const _apiKeyKey = 'gemini_api_key';
  static const _modelKey = 'gemini_model';

  final FlutterSecureStorage _storage;

  ApiKeyStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getApiKey() => _storage.read(key: _apiKeyKey);

  Future<bool> hasKey() async => (await getApiKey())?.trim().isNotEmpty ?? false;

  Future<void> setApiKey(String value) => _storage.write(key: _apiKeyKey, value: value);

  Future<void> clearApiKey() => _storage.delete(key: _apiKeyKey);

  Future<String> getModel() async {
    return await _storage.read(key: _modelKey) ?? defaultGeminiModel;
  }

  Future<void> setModel(String value) => _storage.write(key: _modelKey, value: value);
}
