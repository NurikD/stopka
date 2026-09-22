import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/word_card.dart';
import '../../domain/repositories/word_card_repository.dart';
import '../db/app_database.dart';

WordCard _toDomain(CardRow row) {
  return WordCard(
    id: row.id,
    setId: row.setId,
    term: row.term,
    translation: row.translation,
    transcription: row.transcription,
    partOfSpeech: row.partOfSpeech,
    examples: (jsonDecode(row.examples) as List).cast<String>(),
    note: row.note,
    imageRef: row.imageRef,
    ownerId: row.ownerId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  );
}

class DriftWordCardRepository implements WordCardRepository {
  final AppDatabase _db;
  final String _ownerId;

  DriftWordCardRepository(this._db, this._ownerId);

  @override
  Stream<List<WordCard>> watchCards(String setId) {
    final query = _db.select(_db.cards)
      ..where((t) => t.deletedAt.isNull() & t.setId.equals(setId))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<WordCard?> getCard(String id) async {
    final row = await (_db.select(_db.cards)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

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
    final row = await _db.into(_db.cards).insertReturning(
          CardsCompanion.insert(
            setId: setId,
            term: term,
            translation: translation,
            transcription: Value(transcription),
            partOfSpeech: Value(partOfSpeech),
            examples: Value(jsonEncode(examples)),
            note: Value(note),
            imageRef: Value(imageRef),
            ownerId: _ownerId,
          ),
        );
    return _toDomain(row);
  }

  @override
  Future<void> updateCard(WordCard card) async {
    await (_db.update(_db.cards)..where((t) => t.id.equals(card.id))).write(
      CardsCompanion(
        term: Value(card.term),
        translation: Value(card.translation),
        transcription: Value(card.transcription),
        partOfSpeech: Value(card.partOfSpeech),
        examples: Value(jsonEncode(card.examples)),
        note: Value(card.note),
        imageRef: Value(card.imageRef),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteCard(String id) async {
    await (_db.update(_db.cards)..where((t) => t.id.equals(id))).write(
      CardsCompanion(deletedAt: Value(DateTime.now())),
    );
  }
}
