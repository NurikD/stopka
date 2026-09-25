import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/llm/api_key_store.dart';
import 'package:stopka/core/providers/core_providers.dart';
import 'package:stopka/core/theme/app_theme.dart';
import 'package:stopka/domain/models/word_card.dart';
import 'package:stopka/domain/repositories/word_card_repository.dart';
import 'package:stopka/features/courses/add_words/add_words_screen.dart';

class _NoKey extends ApiKeyStore {
  @override
  Future<String?> getApiKey() async => null;
}

class _Cards implements WordCardRepository {
  final List<(String, String)> created = [];

  @override
  Future<WordCard> createCard({
    required String setId,
    required String term,
    required String translation,
    String transcription = '',
    String partOfSpeech = '',
    List<String> examples = const [],
    String note = '',
    String? imageRef,
  }) async {
    created.add((term, translation));
    final now = DateTime(2026, 9, 24);
    return WordCard(
      id: 'id$term',
      setId: setId,
      term: term,
      translation: translation,
      transcription: '',
      partOfSpeech: '',
      examples: const [],
      note: '',
      ownerId: 'o',
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

void main() {
  testWidgets('shared text opens straight on the parsed draft, and saving works without a key', (tester) async {
    final cards = _Cards();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        apiKeyStoreProvider.overrideWithValue(_NoKey()),
        wordCardRepositoryProvider.overrideWithValue(cards),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const AddWordsScreen(
          setId: 's',
          level: '',
          grammarTopic: '',
          vocabTopic: '',
          initialPaste: 'cat - кот\ndog - собака',
        ),
      ),
    ));

    expect(find.text('Проверьте слова'), findsOneWidget);
    expect(find.text('Сохранить 2 слова'), findsOneWidget);

    await tester.tap(find.text('Сохранить 2 слова'));
    await tester.pumpAndSettle();

    expect(cards.created, [('cat', 'кот'), ('dog', 'собака')]);
  });

  testWidgets('shared text with no words in it falls back to the paste box', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const AddWordsScreen(setId: 's', level: '', grammarTopic: '', vocabTopic: '', initialPaste: ' , , '),
      ),
    ));
    expect(find.text('Вставить список'), findsOneWidget);
  });
}
