import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/llm/api_key_store.dart';
import 'package:stopka/core/llm/llm_client.dart';
import 'package:stopka/core/llm/llm_exception.dart';
import 'package:stopka/core/llm/writing_check_service.dart';
import 'package:stopka/core/pack/content_source.dart';
import 'package:stopka/core/pack/pack_content.dart';
import 'package:stopka/core/pack/pack_service.dart';
import 'package:stopka/core/providers/core_providers.dart';
import 'package:stopka/core/theme/app_theme.dart';
import 'package:stopka/core/tts/tts_service.dart';
import 'package:stopka/data/db/app_database.dart';
import 'package:stopka/data/repositories/pack_repository_impl.dart';
import 'package:stopka/data/repositories/word_card_repository_impl.dart';
import 'package:stopka/data/repositories/word_set_repository_impl.dart';
import 'package:stopka/features/pack/exercise_flow.dart';
import 'package:stopka/features/pack/grammar_screen.dart';
import 'package:stopka/features/pack/listening_screen.dart';
import 'package:stopka/features/pack/pack_context.dart';
import 'package:stopka/features/pack/pack_screen.dart';
import 'package:stopka/features/pack/reading_screen.dart';
import 'package:stopka/features/pack/writing_screen.dart';

import 'pack_fixtures.dart';

class _Key extends ApiKeyStore {
  final bool present;
  _Key(this.present);

  @override
  Future<String?> getApiKey() async => present ? 'key' : null;
}

class _FakeTts extends TtsService {
  final List<double> speeds = [];
  bool stopped = false;

  _FakeTts() : super(read: _none, write: _noWrite);

  static Future<String?> _none(String key) async => null;
  static Future<void> _noWrite(String key, String value) async {}

  @override
  Future<void> speakDialogue(
    List<({int speaker, String text})> lines, {
    double speed = 0.5,
  }) async {
    speeds.add(speed);
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }
}

class _Client implements LlmClient {
  final List<String> replies;
  int calls = 0;

  _Client(this.replies);

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userMessage,
  }) async {
    final reply = replies[calls < replies.length ? calls : replies.length - 1];
    calls++;
    return reply;
  }

  @override
  Future<String> completeWithImage({
    required String systemPrompt,
    required String userMessage,
    required Uint8List imageBytes,
    required String mimeType,
  }) => throw UnimplementedError();

  @override
  Future<bool> validateApiKey(String apiKey) => throw UnimplementedError();
}

class _Source implements ContentSource {
  final Map<PackPart, List<Object>> scripts;
  final Map<PackPart, int> calls = {};

  _Source(this.scripts);

  @override
  Future<Map<String, dynamic>> fetchPart(PackKey key, PackPart part) async {
    final n = calls[part] = (calls[part] ?? 0) + 1;
    final list = scripts[part]!;
    final item = list[n - 1 < list.length ? n - 1 : list.length - 1];
    if (item is LlmException) throw item;
    return item as Map<String, dynamic>;
  }
}

const _key = PackKey(
  level: 'B1',
  grammarTopic: 'Present perfect',
  interest: 'games',
);

Map<PackPart, Object> _good() => {
  PackPart.reading: validatePart(PackPart.reading, readingJson(), level: 'B1'),
  PackPart.listening: validatePart(
    PackPart.listening,
    listeningJson(),
    level: 'B1',
  ),
  PackPart.grammar: validatePart(PackPart.grammar, grammarJson(), level: 'B1'),
  PackPart.writing: validatePart(PackPart.writing, writingJson(), level: 'B1'),
};

class _Env {
  final AppDatabase db;
  final DriftPackRepository packs;
  final PackService service;
  final _FakeTts tts;
  final _Client llm;
  final PackContext pack;
  final Widget Function(Widget home) wrap;

  _Env(
    this.db,
    this.packs,
    this.service,
    this.tts,
    this.llm,
    this.pack,
    this.wrap,
  );
}

Future<_Env> _env({
  bool hasKey = true,
  Set<PackPart> ready = const {
    PackPart.reading,
    PackPart.listening,
    PackPart.grammar,
    PackPart.writing,
  },
  Map<PackPart, List<Object>>? scripts,
  List<String> llmReplies = const ['{}'],
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final packs = DriftPackRepository(db, 'o');
  final stored = await packs.getOrCreate(_key);
  final good = _good();
  for (final part in ready) {
    await packs.setPart(
      stored.id,
      part,
      payload: good[part]! as Map<String, dynamic>,
      status: PartStatus.ready,
    );
  }
  final source = _Source(
    scripts ??
        {
          for (final e in good.entries) e.key: [e.value],
        },
  );
  final service = PackService(
    repo: packs,
    source: source,
    hasKey: () async => hasKey,
  );
  final tts = _FakeTts();
  final llm = _Client(llmReplies);
  final sets = DriftWordSetRepository(db, 'o');
  final cards = DriftWordCardRepository(db, 'o');

  Widget wrap(Widget home) => ProviderScope(
    key: UniqueKey(),
    overrides: [
      packRepositoryProvider.overrideWithValue(packs),
      packServiceProvider.overrideWithValue(service),
      apiKeyStoreProvider.overrideWithValue(_Key(hasKey)),
      ttsServiceProvider.overrideWithValue(tts),
      wordSetRepositoryProvider.overrideWithValue(sets),
      wordCardRepositoryProvider.overrideWithValue(cards),
      writingCheckServiceProvider.overrideWithValue(
        WritingCheckService(llm, loadPrompt: (_) async => 'PROMPT'),
      ),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: home),
  );

  return _Env(
    db,
    packs,
    service,
    tts,
    llm,
    PackContext(packId: stored.id, key: _key, unitId: 'u1'),
    wrap,
  );
}

/// Database calls finish on the real event loop, which the fake clock of
/// testWidgets does not run: give it a moment, then settle the frames.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  await tester.pumpAndSettle();
}

/// Streams need real timers too, so anything that awaits one runs outside
/// the fake clock.
Future<T> _real<T>(WidgetTester tester, Future<T> Function() body) async =>
    (await tester.runAsync(body)) as T;

/// A tall screen so that long lists are fully built.
void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Unmount so nothing keeps listening. The in-memory database is left to be
/// collected: closing it waits on stream timers that never fire under the
/// fake clock.
Future<void> _dispose(WidgetTester tester, _Env env) async {
  await tester.pumpWidget(const SizedBox());
  // Let the stream-cancel timers of the unmounted providers fire.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pump();
  await tester.tap(find.text(text));
  await _settle(tester);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('ExerciseFlow', () {
    Future<List<(int, String, bool)>> run(
      WidgetTester tester,
      List<Exercise> items,
      List<String> answers, {
      List<(int, int)>? finished,
    }) async {
      final log = <(int, String, bool)>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExerciseFlow(
                items: items,
                onAnswer: (i, a, c) async => log.add((i, a, c)),
                onFinished: (s, t) async => finished?.add((s, t)),
              ),
            ),
          ),
        ),
      );
      return log;
    }

    testWidgets(
      'a wrong choice shows the right answer and why, then goes on; the score is reported',
      (tester) async {
        final finished = <(int, int)>[];
        final items = [
          const Exercise(
            kind: ExerciseKind.choice,
            prompt: 'I ___ it.',
            options: ['see', 'have seen'],
            answer: 'have seen',
            why: 'Опыт до сейчас.',
          ),
          const Exercise(
            kind: ExerciseKind.choice,
            prompt: 'She ___.',
            options: ['is', 'are'],
            answer: 'is',
          ),
        ];
        final log = await run(tester, items, [], finished: finished);

        await _tap(tester, 'see');
        expect(find.text('Неверно'), findsOneWidget);
        expect(
          find.text('have seen'),
          findsNWidgets(2),
        ); // the option and the answer line
        expect(find.text('Опыт до сейчас.'), findsOneWidget);
        await _tap(tester, 'Дальше');

        await _tap(tester, 'is');
        expect(find.text('Верно'), findsOneWidget);
        await _tap(tester, 'Завершить');

        expect(log, [(0, 'see', false), (1, 'is', true)]);
        expect(finished, [(1, 2)]);
        expect(find.text('1 из 2'), findsOneWidget);
      },
    );

    testWidgets('a typed gap accepts the exact form only', (tester) async {
      final log = await run(tester, [
        const Exercise(
          kind: ExerciseKind.gap,
          prompt: 'She ___ played.',
          answer: 'has',
        ),
        const Exercise(
          kind: ExerciseKind.gap,
          prompt: 'He ___ played.',
          answer: 'has',
        ),
      ], []);

      await tester.enterText(find.byType(TextField), 'Has');
      await _tap(tester, 'Проверить');
      expect(find.text('Верно'), findsOneWidget);
      await _tap(tester, 'Дальше');

      await tester.enterText(find.byType(TextField), 'have');
      await _tap(tester, 'Проверить');
      expect(find.text('Неверно'), findsOneWidget);
      expect(
        find.text('Засчитать'),
        findsNothing,
      ); // only translations can be overruled
      await _tap(tester, 'Завершить');

      expect(log.map((e) => e.$3), [true, false]);
    });

    testWidgets('a wrong translation can only be flipped by the AI, once', (
      tester,
    ) async {
      final finished = <(int, int)>[];
      final asked = <String>[];
      final log = <(int, String, bool)>[];
      const items = [
        Exercise(
          kind: ExerciseKind.translate,
          prompt: 'Я поел.',
          answer: 'I have eaten.',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExerciseFlow(
                items: items,
                onAnswer: (i, a, c) async => log.add((i, a, c)),
                onFinished: (s, t) async => finished.add((s, t)),
                onAppeal: (exercise, given) async {
                  asked.add(given);
                  return const AppealOutcome(
                    accepted: false,
                    note: 'Здесь нужно Present Perfect.',
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'I ate');
      await _tap(tester, 'Проверить');
      expect(find.text('Неверно'), findsOneWidget);
      expect(find.text('Засчитать'), findsNothing); // no way to grade yourself

      await _tap(tester, 'Мой ответ тоже верный?');
      expect(asked, ['I ate']);
      expect(find.text('Здесь нужно Present Perfect.'), findsOneWidget);
      expect(find.text('Неверно'), findsOneWidget); // the AI said no
      expect(
        find.text('Мой ответ тоже верный?'),
        findsNothing,
      ); // one appeal per answer

      await _tap(tester, 'Завершить');
      expect(log.single.$3, isFalse);
      expect(finished, [(0, 1)]);
    });

    testWidgets('when the AI agrees the answer counts', (tester) async {
      final finished = <(int, int)>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExerciseFlow(
                items: const [
                  Exercise(
                    kind: ExerciseKind.translate,
                    prompt: 'Я поел.',
                    answer: 'I have eaten.',
                  ),
                ],
                onAnswer: (i, a, c) async {},
                onFinished: (s, t) async => finished.add((s, t)),
                onAppeal: (e, g) async =>
                    const AppealOutcome(accepted: true, note: 'Тоже верно.'),
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'I have just eaten');
      await _tap(tester, 'Проверить');
      await _tap(tester, 'Мой ответ тоже верный?');
      expect(find.text('Засчитано ИИ'), findsOneWidget);
      await _tap(tester, 'Завершить');
      expect(finished, [(1, 1)]);
    });

    testWidgets('an AI failure leaves the answer wrong and shows why', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExerciseFlow(
                items: const [
                  Exercise(
                    kind: ExerciseKind.translate,
                    prompt: 'Я поел.',
                    answer: 'I have eaten.',
                  ),
                ],
                onAnswer: (i, a, c) async {},
                onFinished: (s, t) async {},
                onAppeal: (e, g) async => throw const LlmException(
                  'Сервис ИИ сейчас перегружен (код 503).',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'I ate');
      await _tap(tester, 'Проверить');
      await _tap(tester, 'Мой ответ тоже верный?');
      expect(find.textContaining('перегружен'), findsOneWidget);
      expect(find.text('Неверно'), findsOneWidget);
    });
  });

  group('reading', () {
    testWidgets('a tapped word shows its translation and goes to the deck', (
      tester,
    ) async {
      _tall(tester);
      final env = await _env();
      await tester.pumpWidget(env.wrap(ReadingScreen(pack: env.pack)));
      await _settle(tester);

      expect(find.text('My game'), findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().startsWith('I have played this game'),
        ),
      );
      // "game" sits at characters 19..23 of the first sentence.
      final box = paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 19, extentOffset: 23),
          )
          .first;
      await tester.tapAt(paragraph.localToGlobal(box.toRect().center));
      await _settle(tester);

      expect(find.text('игра'), findsOneWidget);
      await _tap(tester, 'В колоду');
      expect(find.textContaining('добавлено в колоду'), findsOneWidget);

      final sets = await _real(
        tester,
        () => DriftWordSetRepository(
          env.db,
          'o',
        ).watchWordSets(unitId: 'u1').first,
      );
      final cards = await _real(
        tester,
        () => DriftWordCardRepository(
          env.db,
          'o',
        ).watchCards(sets.single.id).first,
      );
      expect(cards.single.term, 'game');
      expect(cards.single.translation, 'игра');
      await _dispose(tester, env);
    });

    testWidgets('questions are answered in place and the result is stored', (
      tester,
    ) async {
      _tall(tester);
      final env = await _env();
      await tester.pumpWidget(env.wrap(ReadingScreen(pack: env.pack)));
      await _settle(tester);

      for (var i = 0; i < 5; i++) {
        await _tap(tester, 'Games');
        await _tap(tester, i < 4 ? 'Дальше' : 'Завершить');
      }

      final progress = await _real(
        tester,
        () => env.packs.watchProgress(env.pack.packId).first,
      );
      expect(progress[PackPart.reading]!.score, 5);
      expect(progress[PackPart.reading]!.total, 5);
      await _dispose(tester, env);
    });
  });

  group('listening', () {
    testWidgets('the text stays hidden until the questions are answered', (
      tester,
    ) async {
      _tall(tester);
      final env = await _env();
      await tester.pumpWidget(env.wrap(ListeningScreen(pack: env.pack)));
      await _settle(tester);

      expect(find.textContaining('play a game with you'), findsNothing);
      for (var i = 0; i < 3; i++) {
        await _tap(tester, 'Games');
        await _tap(tester, i < 2 ? 'Дальше' : 'Завершить');
      }
      expect(find.textContaining('play a game with you'), findsWidgets);
      expect(find.textContaining('Anna', findRichText: true), findsWidgets);
      await _dispose(tester, env);
    });

    testWidgets('the speed switch changes the rate the dialogue is read at', (
      tester,
    ) async {
      final env = await _env();
      await tester.pumpWidget(env.wrap(ListeningScreen(pack: env.pack)));
      await _settle(tester);

      await _tap(tester, 'Слушать');
      await _tap(tester, '0.75×');
      await _tap(tester, 'Слушать');

      expect(env.tts.speeds, [normalSpeechRate, slowSpeechRate]);
      expect(slowSpeechRate, closeTo(normalSpeechRate * 0.75, 0.0001));
      await _dispose(tester, env);
    });
  });

  group('grammar', () {
    testWidgets(
      'a wrong exercise is stored as a mistake with the topic as its category',
      (tester) async {
        _tall(tester);
        final env = await _env();
        await tester.pumpWidget(env.wrap(GrammarScreen(pack: env.pack)));
        await _settle(tester);

        expect(find.text('Present perfect'), findsWidgets);
        expect(find.textContaining('уже случилось'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'have');
        await _tap(tester, 'Проверить');
        await tester.pumpAndSettle();

        final rows = await env.db.select(env.db.mistakes).get();
        // Written when the learner moves on.
        expect(rows, isEmpty);
        await _tap(tester, 'Дальше');

        final after = await env.db.select(env.db.mistakes).get();
        expect(after.single.skill, 'grammar');
        expect(after.single.category, 'Present perfect');
        expect(after.single.original, 'have');
        expect(after.single.corrected, 'has');
        await _dispose(tester, env);
      },
    );
  });

  group('writing', () {
    const feedback = '''
{"corrected":"I played this game yesterday.","native":"I played it all day yesterday.",
 "errors":[{"category":"tense","original":"I play","fixed":"I played","explanation":"Вчера — прошедшее время."}],
 "summary":"Хорошо, что вы использовали yesterday."}
''';

    testWidgets('without a key the text stays and nothing is requested', (
      tester,
    ) async {
      final env = await _env(hasKey: false, llmReplies: [feedback]);
      await tester.pumpWidget(env.wrap(WritingScreen(pack: env.pack)));
      await _settle(tester);

      await tester.enterText(
        find.byType(TextField),
        'I play this game yesterday and it was fun.',
      );
      await _tap(tester, 'Проверить');

      expect(find.textContaining('нужен'), findsNothing);
      expect(find.textContaining('ключ'), findsOneWidget);
      expect(
        find.text('I play this game yesterday and it was fun.'),
        findsOneWidget,
      );
      expect(env.llm.calls, 0);
      await _dispose(tester, env);
    });

    testWidgets(
      'a checked text shows errors by category, the fix and the native version, and saves them',
      (tester) async {
        _tall(tester);
        final env = await _env(llmReplies: [feedback]);
        await tester.pumpWidget(env.wrap(WritingScreen(pack: env.pack)));
        await _settle(tester);

        await tester.enterText(
          find.byType(TextField),
          'I play this game yesterday and it was fun.',
        );
        await _tap(tester, 'Проверить');

        expect(find.text('1 ошибка'), findsOneWidget);
        expect(find.text('Время глагола'), findsOneWidget);
        expect(find.text('Вчера — прошедшее время.'), findsOneWidget);
        expect(find.text('Исправленный текст'), findsOneWidget);
        expect(find.text('Как сказал бы носитель'), findsOneWidget);

        final mistakes = await env.db.select(env.db.mistakes).get();
        expect(mistakes.single.skill, 'writing');
        expect(mistakes.single.category, 'tense');
        final attempts = await env.db.select(env.db.writingAttempts).get();
        expect(attempts.single.correctedText, 'I played this game yesterday.');
        final progress = await _real(
          tester,
          () => env.packs.watchProgress(env.pack.packId).first,
        );
        expect(progress.containsKey(PackPart.writing), isTrue);
        await _dispose(tester, env);
      },
    );
  });

  group('pack overview', () {
    testWidgets('without a key it says so, and ready parts still open', (
      tester,
    ) async {
      final env = await _env(hasKey: false, ready: {PackPart.grammar});
      await tester.pumpWidget(env.wrap(PackScreen(pack: env.pack)));
      await _settle(tester);

      expect(find.textContaining('нужен ключ Gemini'), findsOneWidget);
      expect(find.text('Нужен ключ Gemini'), findsNWidgets(3));
      expect(find.text('Готово'), findsOneWidget);

      await _tap(tester, 'Грамматика');
      expect(find.text('Упражнения'), findsOneWidget);
      await _dispose(tester, env);
    });

    testWidgets('a failed part shows its message and retries when tapped', (
      tester,
    ) async {
      final env = await _env(
        ready: {PackPart.reading, PackPart.listening, PackPart.grammar},
        scripts: {
          PackPart.writing: [
            const LlmException('Лимит запросов.'),
            _good()[PackPart.writing]!,
          ],
        },
      );
      await tester.pumpWidget(env.wrap(PackScreen(pack: env.pack)));
      await _settle(tester);

      await _tap(tester, 'Письмо'); // generates, fails
      expect(find.textContaining('Лимит запросов.'), findsOneWidget);
      await _tap(tester, 'Письмо'); // retries, succeeds
      expect(find.text('Готово'), findsNWidgets(4));
      await _dispose(tester, env);
    });
  });
}
