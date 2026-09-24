import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../llm/llm_client.dart';
import '../llm/llm_exception.dart';
import '../llm/llm_json.dart';
import '../onboarding/starter_content.dart';
import 'pack_content.dart';

/// Where a pack's parts come from. Today that is the model; later a shared
/// library of already generated packs can sit behind the same interface, and
/// nothing above it will notice.
abstract class ContentSource {
  /// The validated JSON of one part for [key]. Throws [LlmException] with a
  /// Russian message when it cannot be produced.
  Future<Map<String, dynamic>> fetchPart(PackKey key, PackPart part);
}

typedef PromptLoader = Future<String> Function(String path);

/// Checks one part against its schema and the level rules, and returns it in
/// normalised form (what gets stored). Throws [PackFormatException].
Map<String, dynamic> validatePart(PackPart part, Object? json, {required String level}) {
  final lvl = effectiveLevel(level);
  return switch (part) {
    PackPart.reading => ReadingContent.fromJson(json, level: lvl).toJson(),
    PackPart.listening => ListeningContent.fromJson(json, level: lvl).toJson(),
    PackPart.grammar => GrammarContent.fromJson(json).toJson(),
    PackPart.writing => WritingContent.fromJson(json).toJson(),
  };
}

const Map<PackPart, String> partNamesRu = {
  PackPart.reading: 'чтение',
  PackPart.listening: 'аудирование',
  PackPart.grammar: 'грамматику',
  PackPart.writing: 'письмо',
};

/// Generates parts with Gemini, one prompt per part, validating before
/// anything is returned; an invalid answer is retried once.
class GeneratedContentSource implements ContentSource {
  final LlmClient _client;
  final PromptLoader _loadPrompt;

  GeneratedContentSource(this._client, {PromptLoader? loadPrompt}) : _loadPrompt = loadPrompt ?? rootBundle.loadString;

  @override
  Future<Map<String, dynamic>> fetchPart(PackKey key, PackPart part) async {
    final prompt = await _loadPrompt('prompts/pack/${part.name}.md');
    final message = jsonEncode({
      'level': effectiveLevel(key.level),
      'grammarTopic': key.grammarTopic,
      'vocabTopic': key.vocabTopic,
      'interest': key.interest,
    });

    for (var attempt = 0; attempt < 2; attempt++) {
      final raw = await _client.complete(
        systemPrompt: prompt,
        userMessage: attempt == 0
            ? message
            : 'Ответ должен быть строго в формате JSON по схеме, без markdown-обёрток, и соответствовать '
                'правилам объёма и уровня. Повтори.\n$message',
      );
      try {
        return validatePart(part, LlmJson.decode(raw), level: key.level);
      } on PackFormatException {
        // Try once more, then give up below.
      } on LlmException {
        // Not JSON at all: same treatment. (Transport errors were thrown by
        // complete() above and are not caught here.)
      }
    }
    throw LlmException('Не удалось подготовить ${partNamesRu[part]}. Попробуйте позже.');
  }
}
