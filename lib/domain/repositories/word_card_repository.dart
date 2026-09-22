import '../models/word_card.dart';

abstract class WordCardRepository {
  Stream<List<WordCard>> watchCards(String setId);

  Future<WordCard?> getCard(String id);

  Future<WordCard> createCard({
    required String setId,
    required String term,
    required String translation,
    String transcription = '',
    String partOfSpeech = '',
    List<String> examples = const [],
    String note = '',
    String? imageRef,
  });

  Future<void> updateCard(WordCard card);

  Future<void> deleteCard(String id);
}
