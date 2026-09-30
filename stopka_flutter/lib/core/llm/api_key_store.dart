import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Free-tier limits of a personal key (AI Studio, checked 2026-09-30):
/// Flash models 5 requests a minute and 20 a day, Flash-Lite 15 a minute and
/// 500 a day. Quotas are counted per model, so Flash-Lite is the default and
/// the fallbacks below add their own daily quota on top.
/// Model ids: ai.google.dev/gemini-api/docs/models — verify before changing.
const String defaultGeminiModel = 'gemini-3.5-flash-lite';

/// Tried in order, after the chosen model, when a model's daily quota is used
/// up.
const List<String> fallbackGeminiModels = ['gemini-3.5-flash-lite', 'gemini-3.1-flash-lite'];

class ApiKeyStore {
  static const _apiKeyKey = 'gemini_api_key';
  // v2: the first key holds the old Flash default for everyone who pressed
  // "Сохранить" — not a choice, and it ran out after 20 requests a day.
  static const _modelKey = 'gemini_model_v2';

  final FlutterSecureStorage _storage;

  ApiKeyStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getApiKey() => _storage.read(key: _apiKeyKey);

  Future<bool> hasKey() async =>
      (await getApiKey())?.trim().isNotEmpty ?? false;

  Future<void> setApiKey(String value) =>
      _storage.write(key: _apiKeyKey, value: value);

  Future<void> clearApiKey() => _storage.delete(key: _apiKeyKey);

  Future<String> getModel() async {
    return await _storage.read(key: _modelKey) ?? defaultGeminiModel;
  }

  Future<void> setModel(String value) =>
      _storage.write(key: _modelKey, value: value);
}
