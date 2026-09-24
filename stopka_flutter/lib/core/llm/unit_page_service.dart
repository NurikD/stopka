import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import 'llm_client.dart';
import 'llm_exception.dart';
import 'llm_json.dart';

class UnitPageInfo {
  final String code;
  final String title;
  final String grammarTopic;
  final String vocabTopic;

  const UnitPageInfo({
    this.code = '',
    this.title = '',
    this.grammarTopic = '',
    this.vocabTopic = '',
  });

  bool get isEmpty => code.isEmpty && title.isEmpty && grammarTopic.isEmpty && vocabTopic.isEmpty;

  factory UnitPageInfo.parse(String raw) {
    final json = LlmJson.decode(raw);
    String read(String key) => (json[key] as String? ?? '').trim();
    return UnitPageInfo(
      code: read('code'),
      title: read('title'),
      grammarTopic: read('grammarTopic'),
      vocabTopic: read('vocabTopic'),
    );
  }
}

/// Reads the unit code and topics off a photographed textbook page — see
/// prompts/unit_page.md. Only what is printed on the page is reported.
class UnitPageService {
  final LlmClient _client;

  UnitPageService(this._client);

  Future<UnitPageInfo> read({required Uint8List imageBytes, required String mimeType}) async {
    final prompt = await rootBundle.loadString('prompts/unit_page.md');

    for (var attempt = 0; attempt < 2; attempt++) {
      final raw = await _client.completeWithImage(
        systemPrompt: prompt,
        userMessage: attempt == 0
            ? 'Определи юнит и темы по фото страницы.'
            : 'Ответ должен быть строго в формате JSON без markdown-обёрток. Повтори.',
        imageBytes: imageBytes,
        mimeType: mimeType,
      );
      try {
        final info = UnitPageInfo.parse(raw);
        if (info.isEmpty) {
          throw const LlmException('На фото не нашлось ни юнита, ни темы.');
        }
        return info;
      } on LlmException {
        if (attempt == 1) {
          throw const LlmException('Не удалось понять страницу по фото. Введите тему вручную.');
        }
      }
    }
    throw const LlmException('Не удалось понять страницу по фото.');
  }
}
