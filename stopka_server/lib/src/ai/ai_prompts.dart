import 'dart:convert';
import 'dart:io';

/// The system prompt and user message of one AI call.
class PromptPair {
  final String system;
  final String user;

  const PromptPair(this.system, this.user);
}

typedef PromptSource = String Function(String name);

/// Reads `prompts/<name>` next to the server's config.
String readPromptFile(String name) => File('prompts/$name').readAsStringSync();

const String _strictNote = 'Ответ должен быть строго в формате JSON без markdown-обёрток.';

String _withStrict(String message, bool strict) => strict ? '$_strictNote\n$message' : message;

/// Builds the prompts of every kind. Prompts live on the server: improving one
/// needs no new app release. [source] is injectable so tests need no files.
class AiPrompts {
  final PromptSource _source;

  AiPrompts([PromptSource? source]) : _source = source ?? readPromptFile;

  PromptPair checkWriting({required String level, required String task, required String text, bool strict = false}) {
    return PromptPair(
      _source('writing_check.md'),
      _withStrict(jsonEncode({'level': level.isEmpty ? 'A2' : level, 'task': task, 'text': text}), strict),
    );
  }

  PromptPair appeal({
    required String term,
    required String correctAnswer,
    required String userAnswer,
    required String direction,
    bool strict = false,
  }) {
    final system = _source('answer_appeal.md')
        .replaceAll('{{term}}', term)
        .replaceAll('{{correctAnswer}}', correctAnswer)
        .replaceAll('{{userAnswer}}', userAnswer)
        .replaceAll('{{direction}}', direction);
    return PromptPair(system, _withStrict('Оцени ответ.', strict));
  }

  PromptPair weakSpotDrill({
    required String level,
    required String category,
    required String categoryRu,
    required List<String> interests,
    required List<String> words,
    required List<({String original, String corrected})> mistakes,
    bool strict = false,
  }) {
    return PromptPair(
      _source('weak_practice.md'),
      _withStrict(
        jsonEncode({
          'level': level.isEmpty ? 'A2' : level,
          'category': category,
          'categoryRu': categoryRu,
          'interests': interests,
          'words': words,
          'mistakes': [
            for (final m in mistakes) {'original': m.original, 'corrected': m.corrected},
          ],
        }),
        strict,
      ),
    );
  }

  PromptPair enrichCards({
    required String level,
    required String grammarTopic,
    required String vocabTopic,
    required List<String> terms,
    bool strict = false,
  }) {
    final system = _source('card_enrichment.md')
        .replaceAll('{{level}}', level)
        .replaceAll('{{grammarTopic}}', grammarTopic)
        .replaceAll('{{vocabTopic}}', vocabTopic)
        .replaceAll('{{words}}', terms.map((t) => '- $t').join('\n'));
    return PromptPair(system, _withStrict('Составь карточки для слов из списка.', strict));
  }

  PromptPair recognizeWords({bool strict = false}) {
    return PromptPair(_source('word_recognition.md'), _withStrict('Распознай слова на фото.', strict));
  }

  PromptPair readUnitPage({bool strict = false}) {
    return PromptPair(_source('unit_page.md'), _withStrict('Определи юнит и темы по фото страницы.', strict));
  }
}
