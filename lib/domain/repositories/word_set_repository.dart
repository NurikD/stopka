import '../models/word_set.dart';

abstract class WordSetRepository {
  Stream<List<WordSet>> watchWordSets({String? unitId});

  Future<WordSet?> getWordSet(String id);

  Future<WordSet> createWordSet({
    String? unitId,
    required String title,
    required WordSetSource source,
  });

  Future<void> updateWordSet(WordSet wordSet);

  Future<void> deleteWordSet(String id);
}
