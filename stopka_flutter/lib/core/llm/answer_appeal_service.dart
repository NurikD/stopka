import 'package:flutter/services.dart' show rootBundle;

import 'llm_client.dart';
import 'llm_exception.dart';
import 'llm_json.dart';

class AnswerAppealResult {
  final bool accepted;
  final String explanationRu;

  const AnswerAppealResult({required this.accepted, required this.explanationRu});
}

/// One-off adjudication for "я считаю, мой вариант тоже верный" — the only
/// place the dictation mode calls the AI, since everything else is checked
/// locally to stay fast and free. See prompts/answer_appeal.md.
class AnswerAppealService {
  final LlmClient _client;

  AnswerAppealService(this._client);

  Future<AnswerAppealResult> appeal({
    required String term,
    required String correctAnswer,
    required String userAnswer,
    required String direction,
  }) async {
    final template = await rootBundle.loadString('prompts/answer_appeal.md');
    final prompt = template
        .replaceAll('{{term}}', term)
        .replaceAll('{{correctAnswer}}', correctAnswer)
        .replaceAll('{{userAnswer}}', userAnswer)
        .replaceAll('{{direction}}', direction);

    for (var attempt = 0; attempt < 2; attempt++) {
      final raw = await _client.complete(
        systemPrompt: prompt,
        userMessage: attempt == 0 ? 'Оцени ответ.' : 'Ответ должен быть строго в формате JSON без markdown-обёрток.',
      );
      try {
        final json = LlmJson.decode(raw);
        return AnswerAppealResult(
          accepted: json['accepted'] == true,
          explanationRu: (json['explanationRu'] as String? ?? '').trim(),
        );
      } on LlmException {
        if (attempt == 1) {
          throw const LlmException('Не удалось проверить апелляцию. Попробуйте ещё раз.');
        }
      }
    }
    throw const LlmException('Не удалось проверить апелляцию.');
  }
}
