import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/llm/llm_exception.dart';
import 'package:stopka/core/llm/llm_json.dart';

void main() {
  group('LlmJson.decode', () {
    test('parses plain JSON', () {
      final result = LlmJson.decode('{"words": [{"term": "achieve"}]}');
      expect(result['words'], isA<List>());
    });

    test('strips ```json code fences', () {
      final result = LlmJson.decode('```json\n{"a": 1}\n```');
      expect(result['a'], 1);
    });

    test('strips plain ``` code fences', () {
      final result = LlmJson.decode('```\n{"a": 1}\n```');
      expect(result['a'], 1);
    });

    test('trims surrounding whitespace', () {
      final result = LlmJson.decode('  \n{"a": 1}\n  ');
      expect(result['a'], 1);
    });

    test('throws a Russian LlmException on invalid JSON', () {
      expect(
        () => LlmJson.decode('not json at all'),
        throwsA(isA<LlmException>()),
      );
    });

    test('throws on a JSON array instead of an object', () {
      expect(
        () => LlmJson.decode('[1, 2, 3]'),
        throwsA(isA<LlmException>()),
      );
    });

    test('throws on empty string', () {
      expect(
        () => LlmJson.decode(''),
        throwsA(isA<LlmException>()),
      );
    });
  });
}
