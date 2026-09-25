import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../onboarding/starter_content.dart';
import '../pack/content_source.dart' show PromptLoader;
import '../pack/pack_content.dart';
import 'llm_client.dart';
import 'llm_exception.dart';
import 'llm_json.dart';

class MistakeExample {
  final String original;
  final String corrected;

  const MistakeExample(this.original, this.corrected);
}

/// Makes a short practice set on one weak category, built on the learner's
/// own words, interests and real mistakes — see prompts/pack/weak_practice.md.
class WeakPracticeService {
  final LlmClient _client;
  final PromptLoader _loadPrompt;

  WeakPracticeService(this._client, {PromptLoader? loadPrompt})
    : _loadPrompt = loadPrompt ?? rootBundle.loadString;

  Future<List<Exercise>> generate({
    required String level,
    required String category,
    required String categoryRu,
    List<String> interests = const [],
    List<String> words = const [],
    List<MistakeExample> examples = const [],
  }) async {
    final prompt = await _loadPrompt('prompts/pack/weak_practice.md');
    final message = jsonEncode({
      'level': effectiveLevel(level),
      'category': category,
      'categoryRu': categoryRu,
      'interests': interests,
      'words': words.take(10).toList(),
      'mistakes': [
        for (final e in examples.take(4))
          {'original': e.original, 'corrected': e.corrected},
      ],
    });

    for (var attempt = 0; attempt < 2; attempt++) {
      final raw = await _client.complete(
        systemPrompt: prompt,
        userMessage: attempt == 0
            ? message
            : 'Ответ должен быть строго JSON без markdown-обёрток.\n$message',
        request: AiRequest(AiKind.weakSpotDrill, {
          'level': aiLevel(level),
          'category': category,
          'categoryRu': categoryRu,
          'interests': interests,
          'words': words.take(10).toList(),
          'mistakes': [
            for (final e in examples.take(4))
              {'original': e.original, 'corrected': e.corrected},
          ],
        }, strict: attempt > 0),
      );
      try {
        return parse(raw);
      } on PackFormatException {
        // retry once
      } on LlmException {
        // not JSON: retry once
      }
    }
    throw const LlmException(
      'Не удалось подготовить тренировку. Попробуйте позже.',
    );
  }

  static List<Exercise> parse(String raw) {
    final json = LlmJson.decode(raw);
    final list = json['exercises'];
    if (list is! List) throw const PackFormatException('no exercises');
    final exercises = list.map(Exercise.fromJson).toList();
    if (exercises.length < 4 || exercises.length > 8) {
      throw PackFormatException('${exercises.length} exercises');
    }
    return exercises;
  }
}
