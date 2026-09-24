import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/llm/llm_client.dart';
import 'package:stopka/core/llm/llm_exception.dart';
import 'package:stopka/core/llm/writing_check_service.dart';

class _Client implements LlmClient {
  final List<String> replies;
  int calls = 0;
  String? lastMessage;

  _Client(this.replies);

  @override
  Future<String> complete({required String systemPrompt, required String userMessage}) async {
    lastMessage = userMessage;
    return replies[calls++ < replies.length ? calls - 1 : replies.length - 1];
  }

  @override
  Future<String> completeWithImage({
    required String systemPrompt,
    required String userMessage,
    required Uint8List imageBytes,
    required String mimeType,
  }) =>
      throw UnimplementedError();

  @override
  Future<bool> validateApiKey(String apiKey) => throw UnimplementedError();
}

Future<String> _prompt(String path) async => 'PROMPT';

const _good = '''
{
  "corrected": "I played this game yesterday.",
  "native": "I was playing this game all day yesterday.",
  "errors": [
    {"category": "tense", "original": "I play", "fixed": "I played", "explanation": "Вчера — прошедшее время."},
    {"category": "nonsense", "original": "game", "fixed": "games", "explanation": "..."},
    {"category": "spelling", "original": "same", "fixed": "same", "explanation": "no change"},
    {"category": "article", "original": "", "fixed": "the", "explanation": "empty original"}
  ],
  "summary": "Хорошо, что вы использовали слово yesterday."
}
''';

void main() {
  test('parses corrected text, native version and errors, mapping unknown categories to other', () {
    final feedback = WritingFeedback.parse(_good);

    expect(feedback.corrected, 'I played this game yesterday.');
    expect(feedback.native, contains('all day'));
    expect(feedback.errors.map((e) => e.category), ['tense', 'other']);
    expect(feedback.errors.first.explanation, contains('Вчера'));
    expect(feedback.summary, isNotEmpty);
  });

  test('an answer without a corrected text is rejected', () {
    expect(() => WritingFeedback.parse('{"errors": []}'), throwsA(isA<LlmException>()));
  });

  test('at most eight errors are kept', () {
    final many = [
      for (var i = 0; i < 12; i++) '{"category":"tense","original":"a$i","fixed":"b$i","explanation":"x"}',
    ].join(',');
    final feedback = WritingFeedback.parse('{"corrected":"ok","errors":[$many]}');
    expect(feedback.errors, hasLength(8));
  });

  test('too little or too much text is refused before any request', () async {
    final client = _Client([_good]);
    final service = WritingCheckService(client, loadPrompt: _prompt);

    await expectLater(service.check(level: 'A2', task: 't', text: 'Hi'), throwsA(isA<LlmException>()));
    await expectLater(
      service.check(level: 'A2', task: 't', text: 'word ' * 400),
      throwsA(isA<LlmException>()),
    );
    expect(client.calls, 0);
  });

  test('a broken first answer is retried once', () async {
    final client = _Client(['nope', _good]);
    final feedback = await WritingCheckService(client, loadPrompt: _prompt)
        .check(level: 'A2', task: 'Write about games.', text: 'I play this game yesterday and it was fun.');

    expect(feedback.errors, isNotEmpty);
    expect(client.calls, 2);
    expect(client.lastMessage, contains('Write about games.'));
  });

  test('two broken answers end in a Russian error', () async {
    final client = _Client(['nope', 'still nope']);
    await expectLater(
      WritingCheckService(client, loadPrompt: _prompt)
          .check(level: 'A2', task: 't', text: 'I play this game yesterday and it was fun.'),
      throwsA(isA<LlmException>().having((e) => e.messageRu, 'message', contains('проверить'))),
    );
  });
}
