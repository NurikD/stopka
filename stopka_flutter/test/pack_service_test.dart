import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/llm/llm_client.dart';
import 'package:stopka/core/llm/llm_exception.dart';
import 'package:stopka/core/pack/content_source.dart';
import 'package:stopka/core/pack/pack_content.dart';
import 'package:stopka/core/pack/pack_service.dart';
import 'package:stopka/data/db/app_database.dart';
import 'package:stopka/data/repositories/pack_repository_impl.dart';
import 'package:stopka/domain/models/unit_pack.dart';

import 'pack_fixtures.dart';

class _ScriptedClient implements LlmClient {
  final List<Object> replies; // String = raw answer, LlmException = thrown
  final List<String> systemPrompts = [];
  int calls = 0;

  _ScriptedClient(this.replies);

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userMessage,
    AiRequest? request,
  }) async {
    systemPrompts.add(systemPrompt);
    final reply = replies[calls < replies.length ? calls : replies.length - 1];
    calls++;
    if (reply is LlmException) throw reply;
    return reply as String;
  }

  @override
  Future<String> completeWithImage({
    required String systemPrompt,
    required String userMessage,
    required Uint8List imageBytes,
    required String mimeType,
    AiRequest? request,
  }) => throw UnimplementedError();

  @override
  Future<bool> validateApiKey(String apiKey) => throw UnimplementedError();
}

class _MapSource implements ContentSource {
  final Map<PackPart, List<Object>> scripts;
  final Map<PackPart, int> calls = {};

  _MapSource(this.scripts);

  @override
  Future<Map<String, dynamic>> fetchPart(PackKey key, PackPart part) async {
    final n = calls[part] = (calls[part] ?? 0) + 1;
    final list = scripts[part]!;
    final item = list[(n - 1) < list.length ? n - 1 : list.length - 1];
    if (item is LlmException) throw item;
    return item as Map<String, dynamic>;
  }
}

Future<String> _prompt(String path) async => 'PROMPT $path';

void main() {
  const key = PackKey(
    level: 'B1',
    grammarTopic: 'Present perfect',
    interest: 'games',
  );

  group('GeneratedContentSource', () {
    test(
      'returns the validated part and sends that part\'s own prompt',
      () async {
        final client = _ScriptedClient([asRaw(grammarJson())]);
        final part = await GeneratedContentSource(
          client,
          loadPrompt: _prompt,
        ).fetchPart(key, PackPart.grammar);

        expect(part['title'], 'Present perfect');
        expect(client.systemPrompts.single, 'PROMPT prompts/pack/grammar.md');
      },
    );

    test('one invalid answer is retried, a valid second one is used', () async {
      final client = _ScriptedClient(['not json at all', asRaw(writingJson())]);
      final part = await GeneratedContentSource(
        client,
        loadPrompt: _prompt,
      ).fetchPart(key, PackPart.writing);

      expect(part['task'], startsWith('Write 4-6'));
      expect(client.calls, 2);
    });

    test('two invalid answers end in a plain Russian error, never in stored content', () async {
      final tooShort = asRaw(readingJson(sentences: 3));
      final client = _ScriptedClient([tooShort, tooShort]);

      await expectLater(
        GeneratedContentSource(
          client,
          loadPrompt: _prompt,
        ).fetchPart(key, PackPart.reading),
        throwsA(
          isA<LlmException>().having(
            (e) => e.messageRu,
            'message',
            contains('чтение'),
          ),
        ),
      );
      expect(client.calls, 2);
    });

    test('a transport error is not retried', () async {
      final client = _ScriptedClient([const LlmException('Нет сети.')]);

      await expectLater(
        GeneratedContentSource(
          client,
          loadPrompt: _prompt,
        ).fetchPart(key, PackPart.writing),
        throwsA(isA<LlmException>()),
      );
      expect(client.calls, 1);
    });
  });

  group('PackService', () {
    late AppDatabase db;
    late DriftPackRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = DriftPackRepository(db, 'owner');
    });

    tearDown(() async {
      await db.close();
    });

    Map<PackPart, List<Object>> allGood() => {
      PackPart.reading: [
        validatePart(PackPart.reading, readingJson(), level: 'B1'),
      ],
      PackPart.listening: [
        validatePart(PackPart.listening, listeningJson(), level: 'B1'),
      ],
      PackPart.grammar: [
        validatePart(PackPart.grammar, grammarJson(), level: 'B1'),
      ],
      PackPart.writing: [
        validatePart(PackPart.writing, writingJson(), level: 'B1'),
      ],
    };

    test(
      'generateMissing fills every part, and a second run costs nothing',
      () async {
        final source = _MapSource(allGood());
        final service = PackService(
          repo: repo,
          source: source,
          hasKey: () async => true,
        );
        final pack = await service.open(key);

        await service.generateMissing(pack.id, key);
        final ready = (await repo.getPack(pack.id))!;
        for (final part in PackPart.values) {
          expect(ready.statusOf(part), PartStatus.ready, reason: part.name);
          expect(ready.payloadOf(part), isNotNull);
        }

        await service.generateMissing(pack.id, key);
        expect(
          source.calls.values.every((n) => n == 1),
          isTrue,
          reason: 'cached parts are not requested again',
        );
      },
    );

    test('the same key finds the same pack, so reopening a unit spends no requests', () async {
      final service = PackService(
        repo: repo,
        source: _MapSource(allGood()),
        hasKey: () async => true,
      );
      final first = await service.open(key);
      final second = await service.open(key);
      expect(second.id, first.id);
    });

    test(
      'without a key nothing is requested and nothing is marked failed',
      () async {
        final source = _MapSource(allGood());
        final service = PackService(
          repo: repo,
          source: source,
          hasKey: () async => false,
        );
        final pack = await service.open(key);

        await service.generateMissing(pack.id, key);
        expect(source.calls, isEmpty);
        expect(
          (await repo.getPack(pack.id))!.statusOf(PackPart.reading),
          PartStatus.pending,
        );

        expect(
          await service.generatePart(pack.id, key, PackPart.reading),
          isFalse,
        );
        expect(
          service.lastError[PackService.slot(pack.id, PackPart.reading)],
          contains('связь с сервером'),
        );
      },
    );

    test('a failing part is marked failed with its message, the others still get made', () async {
      final scripts = allGood()
        ..[PackPart.reading] = [const LlmException('Лимит запросов.')];
      final service = PackService(
        repo: repo,
        source: _MapSource(scripts),
        hasKey: () async => true,
      );
      final pack = await service.open(key);

      await service.generateMissing(pack.id, key);
      final result = (await repo.getPack(pack.id))!;
      expect(result.statusOf(PackPart.reading), PartStatus.failed);
      expect(result.statusOf(PackPart.grammar), PartStatus.ready);
      expect(
        service.lastError[PackService.slot(pack.id, PackPart.reading)],
        'Лимит запросов.',
      );

      // A failed part is retried only when asked.
      scripts[PackPart.reading] = [
        validatePart(PackPart.reading, readingJson(), level: 'B1'),
      ];
      expect(
        await service.generatePart(pack.id, key, PackPart.reading),
        isTrue,
      );
      expect(
        (await repo.getPack(pack.id))!.statusOf(PackPart.reading),
        PartStatus.ready,
      );
    });

    test(
      '"Материал плохой" throws the old part away and generates a new one',
      () async {
        final first = validatePart(
          PackPart.writing,
          writingJson(),
          level: 'B1',
        );
        final second = {
          ...first,
          'task': 'Write 4-6 sentences about your favourite level. Use the present perfect.',
        };
        final source = _MapSource({
          ...allGood(),
          PackPart.writing: [first, second],
        });
        final service = PackService(
          repo: repo,
          source: source,
          hasKey: () async => true,
        );
        final pack = await service.open(key);
        await service.generateMissing(pack.id, key);
        expect(
          (await repo.getPack(pack.id))!.payloadOf(PackPart.writing)!['task'],
          first['task'],
        );

        expect(
          await service.flagAndRegenerate(pack.id, key, PackPart.writing),
          isTrue,
        );
        expect(
          (await repo.getPack(pack.id))!.payloadOf(PackPart.writing)!['task'],
          second['task'],
        );
        expect(source.calls[PackPart.writing], 2);
      },
    );

    test(
      'a flagged part whose regeneration fails ends up without content',
      () async {
        final source = _MapSource({
          ...allGood(),
          PackPart.writing: [
            validatePart(PackPart.writing, writingJson(), level: 'B1'),
            const LlmException('Сбой.'),
          ],
        });
        final service = PackService(
          repo: repo,
          source: source,
          hasKey: () async => true,
        );
        final pack = await service.open(key);
        await service.generateMissing(pack.id, key);

        expect(
          await service.flagAndRegenerate(pack.id, key, PackPart.writing),
          isFalse,
        );
        final after = (await repo.getPack(pack.id))!;
        expect(after.statusOf(PackPart.writing), PartStatus.failed);
        expect(after.payloadOf(PackPart.writing), isNull);
      },
    );

    test(
      'progress, attempts and mistakes are stored and survive regeneration',
      () async {
        final service = PackService(
          repo: repo,
          source: _MapSource(allGood()),
          hasKey: () async => true,
        );
        final pack = await service.open(key);
        await service.generateMissing(pack.id, key);

        await repo.logAttempt(
          pack.id,
          PackPart.grammar,
          itemIndex: 0,
          userAnswer: 'has',
          isCorrect: true,
        );
        await repo.saveProgress(pack.id, PackPart.grammar, score: 5, total: 6);
        await repo.addMistakes(pack.id, const [
          MistakeInput(
            skill: 'writing',
            category: 'tense',
            original: 'I play',
            corrected: 'I played',
          ),
        ]);
        await service.flagAndRegenerate(pack.id, key, PackPart.grammar);

        final progress = await repo.watchProgress(pack.id).first;
        expect(progress[PackPart.grammar]!.score, 5);
        expect(progress[PackPart.grammar]!.total, 6);
      },
    );
  });
}
