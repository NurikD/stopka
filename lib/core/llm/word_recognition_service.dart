import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import 'llm_client.dart';
import 'llm_exception.dart';
import 'llm_json.dart';

class RecognizedWord {
  final String term;
  final String translation;

  const RecognizedWord({required this.term, required this.translation});
}

/// Turns a photo of a student's own word list into a draft the user edits
/// before saving — see prompts/word_recognition.md for the exact contract.
class WordRecognitionService {
  final LlmClient _client;

  WordRecognitionService(this._client);

  Future<List<RecognizedWord>> recognize({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    final prompt = await rootBundle.loadString('prompts/word_recognition.md');

    for (var attempt = 0; attempt < 2; attempt++) {
      final raw = await _client.completeWithImage(
        systemPrompt: prompt,
        userMessage: attempt == 0
            ? 'Распознай слова на фото.'
            : 'Ответ должен быть строго в формате JSON без markdown-обёрток. Повтори распознавание.',
        imageBytes: imageBytes,
        mimeType: mimeType,
      );

      try {
        return _parse(raw);
      } on LlmException {
        if (attempt == 1) {
          throw const LlmException(
            'Не удалось распознать слова на фото. Попробуйте другое фото или введите слова вручную.',
          );
        }
      }
    }
    // Unreachable: the loop above always returns or throws.
    throw const LlmException('Не удалось распознать слова на фото.');
  }

  List<RecognizedWord> _parse(String raw) {
    final json = LlmJson.decode(raw);
    final words = json['words'];
    if (words is! List) {
      throw const LlmException('ИИ вернул ответ неожиданной формы.');
    }
    return words
        .whereType<Map<String, dynamic>>()
        .map((w) => RecognizedWord(
              term: (w['term'] as String? ?? '').trim(),
              translation: (w['translation'] as String? ?? '').trim(),
            ))
        .where((w) => w.term.isNotEmpty)
        .toList();
  }
}
