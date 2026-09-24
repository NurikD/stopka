import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../onboarding/starter_content.dart';
import 'llm_client.dart';
import 'llm_exception.dart';
import 'llm_json.dart';

/// Asks the model for a warm-up list matching the learner's level, interests
/// and current topic — see prompts/personal_words.md. Callers fall back to the
/// offline [starterWords] when this throws.
class PersonalWordsService {
  final LlmClient _client;

  PersonalWordsService(this._client);

  Future<List<StarterWord>> generate({
    required String level,
    required List<String> interests,
    String topic = '',
  }) async {
    final prompt = await rootBundle.loadString('prompts/personal_words.md');
    final message = jsonEncode({
      'level': effectiveLevel(level),
      'interests': interests,
      if (topic.isNotEmpty) 'topic': topic,
    });

    for (var attempt = 0; attempt < 2; attempt++) {
      final raw = await _client.complete(
        systemPrompt: prompt,
        userMessage: attempt == 0
            ? message
            : 'Ответ должен быть строго в формате JSON без markdown-обёрток.\n$message',
      );
      try {
        final words = parse(raw);
        if (words.isEmpty) throw const LlmException('ИИ вернул пустой список.');
        return words;
      } on LlmException {
        if (attempt == 1) rethrow;
      }
    }
    throw const LlmException('Не удалось подобрать слова.');
  }

  static List<StarterWord> parse(String raw) {
    final json = LlmJson.decode(raw);
    final words = json['words'];
    if (words is! List) throw const LlmException('ИИ вернул ответ неожиданной формы.');
    final seen = <String>{};
    final result = <StarterWord>[];
    for (final w in words.whereType<Map<String, dynamic>>()) {
      final term = (w['term'] as String? ?? '').trim();
      final translation = (w['translation'] as String? ?? '').trim();
      if (term.isEmpty || translation.isEmpty) continue;
      if (seen.add(term.toLowerCase())) result.add(StarterWord(term, translation));
    }
    return result;
  }
}
