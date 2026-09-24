import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../onboarding/starter_content.dart';
import '../pack/content_source.dart' show PromptLoader;
import '../pack/pack_content.dart' show countWords;
import 'llm_client.dart';
import 'llm_exception.dart';
import 'llm_json.dart';

const List<String> mistakeCategories = [
  'tense',
  'article',
  'preposition',
  'word_order',
  'vocabulary',
  'spelling',
  'punctuation',
  'agreement',
  'other',
];

const Map<String, String> mistakeCategoryNamesRu = {
  'tense': 'Время глагола',
  'article': 'Артикль',
  'preposition': 'Предлог',
  'word_order': 'Порядок слов',
  'vocabulary': 'Выбор слова',
  'spelling': 'Орфография',
  'punctuation': 'Пунктуация',
  'agreement': 'Согласование',
  'other': 'Другое',
};

class WritingError {
  final String category;
  final String original;
  final String fixed;
  final String explanation;

  const WritingError({
    required this.category,
    required this.original,
    required this.fixed,
    required this.explanation,
  });
}

class WritingFeedback {
  final String corrected;
  final String native;
  final List<WritingError> errors;
  final String summary;

  const WritingFeedback({
    required this.corrected,
    required this.native,
    required this.errors,
    required this.summary,
  });

  factory WritingFeedback.parse(String raw) {
    final json = LlmJson.decode(raw);
    final corrected = (json['corrected'] as String? ?? '').trim();
    if (corrected.isEmpty) throw const LlmException('ИИ вернул ответ неожиданной формы.');

    final errors = <WritingError>[];
    final rawErrors = json['errors'];
    if (rawErrors is List) {
      for (final e in rawErrors.whereType<Map>()) {
        final original = (e['original'] as String? ?? '').trim();
        final fixed = (e['fixed'] as String? ?? '').trim();
        if (original.isEmpty || fixed.isEmpty || original == fixed) continue;
        final category = mistakeCategories.contains(e['category']) ? e['category'] as String : 'other';
        errors.add(WritingError(
          category: category,
          original: original,
          fixed: fixed,
          explanation: (e['explanation'] as String? ?? '').trim(),
        ));
        if (errors.length == 8) break;
      }
    }
    return WritingFeedback(
      corrected: corrected,
      native: (json['native'] as String? ?? '').trim(),
      errors: errors,
      summary: (json['summary'] as String? ?? '').trim(),
    );
  }
}

/// Checks the learner's short text: corrected version, mistakes by category
/// with a Russian explanation, and how a native speaker would say it.
class WritingCheckService {
  static const minWords = 3;
  static const maxChars = 1500;

  final LlmClient _client;
  final PromptLoader _loadPrompt;

  WritingCheckService(this._client, {PromptLoader? loadPrompt}) : _loadPrompt = loadPrompt ?? rootBundle.loadString;

  Future<WritingFeedback> check({required String level, required String task, required String text}) async {
    final trimmed = text.trim();
    if (countWords(trimmed) < minWords) {
      throw const LlmException('Напишите хотя бы пару предложений.');
    }
    if (trimmed.length > maxChars) {
      throw const LlmException('Текст слишком длинный. Сократите его до 4–6 предложений.');
    }

    final prompt = await _loadPrompt('prompts/pack/writing_check.md');
    final message = jsonEncode({'level': effectiveLevel(level), 'task': task, 'text': trimmed});

    for (var attempt = 0; attempt < 2; attempt++) {
      final raw = await _client.complete(
        systemPrompt: prompt,
        userMessage: attempt == 0 ? message : 'Ответ должен быть строго JSON без markdown-обёрток.\n$message',
      );
      try {
        return WritingFeedback.parse(raw);
      } on LlmException {
        if (attempt == 1) throw const LlmException('Не удалось проверить текст. Попробуйте ещё раз.');
      }
    }
    throw const LlmException('Не удалось проверить текст.');
  }
}
