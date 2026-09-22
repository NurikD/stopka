import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/text/word_paste_parser.dart';

void main() {
  group('WordPasteParser.parse', () {
    test('parses newline-separated bare words', () {
      final result = WordPasteParser.parse('achieve\ngoal\nrun');
      expect(result.map((w) => w.term), ['achieve', 'goal', 'run']);
      expect(result.every((w) => w.translation.isEmpty), isTrue);
    });

    test('parses comma-separated bare words when there is no newline', () {
      final result = WordPasteParser.parse('achieve, goal, run');
      expect(result.map((w) => w.term), ['achieve', 'goal', 'run']);
    });

    test('parses "word - перевод" format', () {
      final result = WordPasteParser.parse('achieve - достигать\ngoal - цель');
      expect(result[0].term, 'achieve');
      expect(result[0].translation, 'достигать');
      expect(result[1].term, 'goal');
      expect(result[1].translation, 'цель');
    });

    test('parses "word — перевод" with an em dash', () {
      final result = WordPasteParser.parse('achieve — достигать');
      expect(result[0].term, 'achieve');
      expect(result[0].translation, 'достигать');
    });

    test('skips blank lines', () {
      final result = WordPasteParser.parse('achieve\n\n\ngoal\n');
      expect(result, hasLength(2));
    });

    test('trims whitespace around term and translation', () {
      final result = WordPasteParser.parse('  achieve   -   достигать  ');
      expect(result[0].term, 'achieve');
      expect(result[0].translation, 'достигать');
    });

    test('does not split on a hyphen inside a word', () {
      final result = WordPasteParser.parse('long-term');
      expect(result, hasLength(1));
      expect(result[0].term, 'long-term');
      expect(result[0].translation, '');
    });

    test('returns an empty list for blank input', () {
      expect(WordPasteParser.parse(''), isEmpty);
      expect(WordPasteParser.parse('   \n  \n'), isEmpty);
    });
  });
}
