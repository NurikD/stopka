import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/data/db/app_database.dart';
import 'package:stopka/data/repositories/card_state_repository_impl.dart';
import 'package:stopka/data/repositories/session_stats_repository_impl.dart';
import 'package:stopka/data/repositories/word_card_repository_impl.dart';
import 'package:stopka/data/repositories/word_set_repository_impl.dart';
import 'package:stopka/domain/models/dictation_session.dart';
import 'package:stopka/domain/models/word_set.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a word heard by ear still counts as not dictated in writing', () async {
    final set = await DriftWordSetRepository(db, 'o').createWordSet(title: '4B', source: WordSetSource.manual);
    final cards = DriftWordCardRepository(db, 'o');
    final achieve = await cards.createCard(setId: set.id, term: 'achieve', translation: 'достигать');
    final goal = await cards.createCard(setId: set.id, term: 'goal', translation: 'цель');
    await cards.createCard(setId: set.id, term: 'effort', translation: 'усилие');

    final states = DriftCardStateRepository(db, 'o');
    await states.ensureState(achieve.id, DictationDirection.ruEn);
    await states.ensureState(goal.id, DictationDirection.listen);

    expect(await DriftSessionStatsRepository(db, 'o').unlearnedCardCount(set.id), 2);
  });
}
