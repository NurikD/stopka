import 'dart:convert';

import 'llm_exception.dart';

/// Every LLM call in the app asks for strict JSON with no markdown
/// wrapping, but models don't always comply. This strips ```/```json
/// fences before decoding and throws a Russian-language [LlmException] on
/// anything that still isn't valid JSON.
class LlmJson {
  static Map<String, dynamic> decode(String raw) {
    final cleaned = _stripCodeFences(raw).trim();
    Object? decoded;
    try {
      decoded = jsonDecode(cleaned);
    } on FormatException {
      throw const LlmException('ИИ вернул ответ не в формате JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const LlmException('ИИ вернул ответ неожиданной формы.');
    }
    return decoded;
  }

  static String _stripCodeFences(String raw) {
    final fenceMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(raw);
    return fenceMatch != null ? fenceMatch.group(1)! : raw;
  }
}
