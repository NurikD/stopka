import 'dart:typed_data';

import 'package:stopka_server/src/ai/ai_input.dart';
import 'package:stopka_server/src/ai/ai_limits.dart';
import 'package:stopka_server/src/ai/ai_prompts.dart';
import 'package:stopka_server/src/logic/server_settings.dart';
import 'package:test/test.dart';

void main() {
  group('limits', () {
    LimitVerdict decide({
      bool enabled = true,
      int mine = 0,
      int limit = 5,
      int all = 0,
      int budget = 100,
    }) =>
        decideRequest(
          enabled: enabled,
          usedByDeviceForKind: mine,
          deviceLimitForKind: limit,
          usedByAllToday: all,
          globalDailyRequests: budget,
        );

    test('a request under every limit is allowed', () {
      expect(decide(), LimitVerdict.allowed);
      expect(decide(mine: 4, limit: 5, all: 99, budget: 100), LimitVerdict.allowed);
    });

    test('the device limit stops the device at exactly its allowance', () {
      expect(decide(mine: 5, limit: 5), LimitVerdict.deviceLimit);
    });

    test('the global budget stops everyone, even a device far below its own limit', () {
      expect(decide(all: 100, budget: 100), LimitVerdict.budgetExhausted);
    });

    test('the master switch beats everything, and the budget beats the device limit', () {
      expect(decide(enabled: false, mine: 99, all: 999), LimitVerdict.disabled);
      expect(decide(mine: 5, limit: 5, all: 100, budget: 100), LimitVerdict.budgetExhausted);
    });

    test('a kind with a zero limit is closed', () {
      expect(decide(limit: 0), LimitVerdict.deviceLimit);
    });

    test('the day key and the reset are in UTC', () {
      final late = DateTime.utc(2026, 9, 25, 23, 59);
      expect(dayKey(late), '2026-09-25');
      expect(dayKey(late.add(const Duration(minutes: 2))), '2026-09-26');
      expect(nextResetUtc(late), DateTime.utc(2026, 9, 26));
      expect(nextResetUtc(DateTime.utc(2026, 12, 31, 12)), DateTime.utc(2027, 1, 1));
    });
  });

  group('input checks', () {
    test('levels are a closed list, empty allowed', () {
      expect(requireLevel('B1'), 'B1');
      expect(requireLevel(''), '');
      expect(() => requireLevel('C2'), throwsA(isA<InvalidInput>()));
    });

    test('required text must be non-blank and short enough', () {
      expect(requireText('t', '  hi  ', 10), 'hi');
      expect(() => requireText('t', '   ', 10), throwsA(isA<InvalidInput>()));
      expect(() => requireText('t', 'x' * 11, 10), throwsA(isA<InvalidInput>()));
    });

    test('lists are capped and blanks dropped', () {
      expect(requireList('l', ['a', ' ', 'b'], maxItems: 3, maxChars: 5), ['a', 'b']);
      expect(() => requireList('l', ['a', 'b', 'c'], maxItems: 2, maxChars: 5), throwsA(isA<InvalidInput>()));
    });

    test('images: only jpeg, png, webp, non-empty and within the size cap', () {
      final ok = Uint8List.fromList([1, 2, 3]);
      expect(requireImage(ok, 'image/png', 10), ok);
      expect(() => requireImage(ok, 'application/pdf', 10), throwsA(isA<InvalidInput>()));
      expect(() => requireImage(Uint8List(0), 'image/png', 10), throwsA(isA<InvalidInput>()));
      expect(() => requireImage(Uint8List(11), 'image/png', 10), throwsA(isA<InvalidInput>()));
    });
  });

  group('prompts', () {
    final prompts = AiPrompts(
      (name) => 'PROMPT $name {{term}}|{{correctAnswer}}|{{userAnswer}}|{{direction}}|{{words}}|{{level}}',
    );

    test('the writing check sends the task and text as JSON, and a stricter reminder on retry', () {
      final first = prompts.checkWriting(level: 'B1', task: 'Write.', text: 'I played.');
      expect(first.system, startsWith('PROMPT writing_check.md'));
      expect(first.user, contains('"text":"I played."'));
      expect(first.user, contains('"level":"B1"'));

      final retry = prompts.checkWriting(level: 'B1', task: 'Write.', text: 'I played.', strict: true);
      expect(retry.user, contains('строго в формате JSON'));
      expect(first.user, isNot(contains('строго')));
    });

    test('an empty level becomes A2', () {
      expect(prompts.checkWriting(level: '', task: 't', text: 'x').user, contains('"level":"A2"'));
    });

    test('the appeal fills its template placeholders', () {
      final p = prompts.appeal(term: 'go', correctAnswer: 'идти', userAnswer: 'ехать', direction: 'EN -> RU');
      expect(p.system, contains('go|идти|ехать|EN -> RU'));
    });

    test('card enrichment lists the words', () {
      final p = prompts.enrichCards(level: 'A2', grammarTopic: '', vocabTopic: '', terms: ['cat', 'dog']);
      expect(p.system, contains('- cat\n- dog'));
    });
  });

  group('settings', () {
    test('the ai section is read, unknown kinds are kept, bad values ignored', () {
      final s = ServerSettings.parse(
        'ai:\n'
        '  enabled: false\n'
        '  model: some-model\n'
        '  globalDailyRequests: 7\n'
        '  dailyLimits:\n'
        '    appeal: 2\n'
        '    checkWriting: -1\n'
        '    newKind: 3\n',
      ).ai;
      expect(s.enabled, isFalse);
      expect(s.model, 'some-model');
      expect(s.globalDailyRequests, 7);
      expect(s.limitFor('appeal'), 2);
      expect(s.limitFor('checkWriting'), 20, reason: 'a negative value is ignored, the default stays');
      expect(s.limitFor('newKind'), 3);
      expect(s.limitFor('unknown'), 0);
    });

    test('without the section the defaults apply', () {
      final s = ServerSettings.parse('minAppVersion: 1.0.0').ai;
      expect(s.enabled, isTrue);
      expect(s.globalDailyRequests, greaterThan(0));
      expect(s.dailyLimits.keys, containsAll(aiKinds));
    });

    test('the checked-in config has a limit for every kind', () {
      final s = ServerSettings.load().ai;
      for (final kind in aiKinds) {
        expect(s.limitFor(kind), greaterThan(0), reason: kind);
      }
    });
  });
}
