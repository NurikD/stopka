import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../logic/server_settings.dart';
import 'ai_input.dart';
import 'ai_service.dart';

/// Every method returns the model's raw JSON text; the app parses it, exactly
/// as it did when it called the model itself. All need a registered device and
/// count against that device's daily limit for their kind.
class AiEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Checks a short English text: corrected version, mistakes, native version.
  Future<String> checkWriting(Session session, String level, String task, String text, bool strict) {
    final s = ServerSettings.load().ai;
    return _guard(() {
      final prompt = AiRuntime.prompts.checkWriting(
        level: requireLevel(level),
        task: requireText('task', task, s.maxTextChars),
        text: requireText('text', text, s.maxTextChars),
        strict: strict,
      );
      return AiService.run(session, 'checkWriting', prompt);
    });
  }

  /// Judges "my answer is also right".
  Future<String> appeal(
    Session session,
    String term,
    String correctAnswer,
    String userAnswer,
    String direction,
    bool strict,
  ) {
    final s = ServerSettings.load().ai;
    return _guard(() {
      final prompt = AiRuntime.prompts.appeal(
        term: requireText('term', term, s.maxTextChars),
        correctAnswer: requireText('correctAnswer', correctAnswer, s.maxTextChars),
        userAnswer: requireText('userAnswer', userAnswer, s.maxTextChars),
        direction: requireText('direction', direction, 60),
        strict: strict,
      );
      return AiService.run(session, 'appeal', prompt);
    });
  }

  /// Six exercises on one weak category, built on the learner's own material.
  Future<String> weakSpotDrill(
    Session session,
    String level,
    String category,
    String categoryRu,
    List<String> interests,
    List<String> words,
    List<MistakeExample> mistakes,
    bool strict,
  ) {
    final s = ServerSettings.load().ai;
    return _guard(() {
      final prompt = AiRuntime.prompts.weakSpotDrill(
        level: requireLevel(level),
        category: requireText('category', category, 80),
        categoryRu: optionalText('categoryRu', categoryRu, 80),
        interests: requireList('interests', interests, maxItems: 5, maxChars: 40),
        words: requireList('words', words, maxItems: 10, maxChars: 60),
        mistakes: [
          for (final m in mistakes.take(4))
            (
              original: optionalText('original', m.original, s.maxTextChars),
              corrected: optionalText('corrected', m.corrected, s.maxTextChars),
            ),
        ],
        strict: strict,
      );
      return AiService.run(session, 'weakSpotDrill', prompt);
    });
  }

  /// Flashcard details (translation, transcription, examples) for words.
  Future<String> enrichCards(
    Session session,
    String level,
    String grammarTopic,
    String vocabTopic,
    List<String> terms,
    bool strict,
  ) {
    return _guard(() {
      final words = requireList('terms', terms, maxItems: 20, maxChars: 80);
      if (words.isEmpty) throw const InvalidInput('terms is empty');
      final prompt = AiRuntime.prompts.enrichCards(
        level: requireLevel(level),
        grammarTopic: optionalText('grammarTopic', grammarTopic, 120),
        vocabTopic: optionalText('vocabTopic', vocabTopic, 120),
        terms: words,
        strict: strict,
      );
      return AiService.run(session, 'enrichCards', prompt);
    });
  }

  /// Reads the words off a photo of the learner's own word list.
  Future<String> recognizeWords(Session session, ByteData image, String mimeType, bool strict) {
    final s = ServerSettings.load().ai;
    return _guard(() {
      final bytes = requireImage(image.buffer.asUint8List(image.offsetInBytes, image.lengthInBytes), mimeType, s.maxImageBytes);
      return AiService.run(
        session,
        'recognizeWords',
        AiRuntime.prompts.recognizeWords(strict: strict),
        image: bytes,
        mimeType: mimeType,
      );
    });
  }

  /// Reads the unit code and topics off a photo of a textbook page.
  Future<String> readUnitPage(Session session, ByteData image, String mimeType, bool strict) {
    final s = ServerSettings.load().ai;
    return _guard(() {
      final bytes = requireImage(image.buffer.asUint8List(image.offsetInBytes, image.lengthInBytes), mimeType, s.maxImageBytes);
      return AiService.run(
        session,
        'readUnitPage',
        AiRuntime.prompts.readUnitPage(strict: strict),
        image: bytes,
        mimeType: mimeType,
      );
    });
  }

  Future<String> _guard(Future<String> Function() body) async {
    try {
      return await body();
    } on InvalidInput catch (e) {
      throw InvalidAiRequest(reason: e.reason);
    }
  }
}
