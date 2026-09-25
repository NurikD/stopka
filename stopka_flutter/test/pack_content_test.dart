import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/pack/content_source.dart';
import 'package:stopka/core/pack/pack_content.dart';

import 'pack_fixtures.dart';

void main() {
  group('PackKey', () {
    test('the same inputs give the same hash, whatever the spacing and case', () {
      const a = PackKey(level: 'B1', grammarTopic: 'Present Perfect', interest: 'games');
      const b = PackKey(level: 'B1', grammarTopic: '  present   perfect ', interest: 'Games');
      expect(a.hash, b.hash);
    });

    test('a different topic, interest, level or schema version is a different pack', () {
      const base = PackKey(level: 'B1', grammarTopic: 'Present perfect', interest: 'games');
      expect(const PackKey(level: 'B2', grammarTopic: 'Present perfect', interest: 'games').hash, isNot(base.hash));
      expect(const PackKey(level: 'B1', grammarTopic: 'Past simple', interest: 'games').hash, isNot(base.hash));
      expect(const PackKey(level: 'B1', grammarTopic: 'Present perfect', interest: 'music').hash, isNot(base.hash));
      expect(
        const PackKey(level: 'B1', grammarTopic: 'Present perfect', interest: 'games', schemaVersion: 2).hash,
        isNot(base.hash),
      );
    });
  });

  group('reading', () {
    test('a good text is accepted and its grammar marks are found', () {
      final reading = ReadingContent.fromJson(readingJson(), level: 'A2');
      expect(reading.questions, hasLength(5));
      expect(reading.marks, isNotEmpty);
      final m = reading.marks.first;
      expect(reading.text.substring(m.start, m.end), 'have played');
      expect(reading.translate('Game'), 'игра');
      expect(reading.translate('nothing'), isNull);
    });

    test('a text that is too short is refused', () {
      expect(() => ReadingContent.fromJson(readingJson(sentences: 5), level: 'A2'), throwsA(isA<PackFormatException>()));
    });

    test('a target phrase that is not in the text is refused', () {
      expect(
        () => ReadingContent.fromJson(readingJson(phrases: ['has been going']), level: 'A2'),
        throwsA(isA<PackFormatException>()),
      );
    });

    test('sentences too long for the level are refused, but fit a higher one', () {
      final long = readingJson()
        ..['text'] = List.generate(6, (i) => 'I have played this game with my best friend from school for ${i + 2} years and we still love it very much').join('. ');
      expect(() => ReadingContent.fromJson(long, level: 'A1'), throwsA(isA<PackFormatException>()));
      expect(() => ReadingContent.fromJson(long, level: 'A2'), throwsA(isA<PackFormatException>()));
      expect(ReadingContent.fromJson(long, level: 'B2').title, 'My game');
    });

    test('a question whose answer index is out of range is refused', () {
      final bad = readingJson()..['questions'] = List.generate(5, (_) => question(7));
      expect(() => ReadingContent.fromJson(bad, level: 'A2'), throwsA(isA<PackFormatException>()));
    });

    test('a round trip through JSON keeps the content', () {
      final reading = ReadingContent.fromJson(readingJson(), level: 'A2');
      final again = ReadingContent.fromJson(reading.toJson(), level: 'A2');
      expect(again.text, reading.text);
      expect(again.glossary.length, reading.glossary.length);
    });
  });

  group('listening', () {
    test('two speakers map to two voices', () {
      final listening = ListeningContent.fromJson(listeningJson(), level: 'B1');
      expect(listening.lines.map((l) => l.speaker).toSet(), {0, 1});
      expect(listening.lines.first.name, 'Anna');
    });

    test('a third speaker is refused', () {
      final bad = listeningJson();
      (bad['lines'] as List)[2] = {'speaker': 'Sam', 'text': 'Hello there my friend.'};
      expect(() => ListeningContent.fromJson(bad, level: 'B1'), throwsA(isA<PackFormatException>()));
    });

    test('too few words are refused', () {
      final bad = listeningJson()..['lines'] = [{'speaker': 'A', 'text': 'Hi.'}, {'speaker': 'B', 'text': 'Hello.'}];
      expect(() => ListeningContent.fromJson(bad, level: 'B1'), throwsA(isA<PackFormatException>()));
    });
  });

  group('grammar', () {
    test('a good part is accepted', () {
      final grammar = GrammarContent.fromJson(grammarJson());
      expect(grammar.exercises.map((e) => e.kind).toSet(), {ExerciseKind.gap, ExerciseKind.choice, ExerciseKind.translate});
    });

    test('a gap without ___ and a choice whose answer is not an option are refused', () {
      final noGap = grammarJson();
      (noGap['exercises'] as List)[0] = {'kind': 'gap', 'prompt': 'She has never played.', 'answer': 'has'};
      expect(() => GrammarContent.fromJson(noGap), throwsA(isA<PackFormatException>()));

      final noOption = grammarJson();
      (noOption['exercises'] as List)[1] = {
        'kind': 'choice',
        'prompt': 'I ___ it.',
        'options': ['see', 'saw'],
        'answer': 'have seen',
      };
      expect(() => GrammarContent.fromJson(noOption), throwsA(isA<PackFormatException>()));
    });
  });

  group('writing', () {
    test('a good task is accepted, an empty one is refused', () {
      expect(WritingContent.fromJson(writingJson()).hints, hasLength(2));
      expect(() => WritingContent.fromJson({'task': 'Write.', 'hints': []}), throwsA(isA<PackFormatException>()));
    });
  });

  test('validatePart normalises what it stores', () {
    final stored = validatePart(PackPart.grammar, grammarJson(), level: 'B1');
    expect(stored['title'], 'Present perfect');
    expect((stored['exercises'] as List), hasLength(6));
  });
}
