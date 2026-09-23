import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Sync-related columns every table carries so a future backend can sync
/// without a schema rewrite: soft delete via [deletedAt], ownership via
/// [ownerId], and [syncedAt] left null until a sync implementation exists.
///
/// The default must be a self-contained expression (no reference to a
/// private top-level variable): drift_dev copies clientDefault closures
/// into the generated app_database.g.dart, which lives in a different
/// library and can't see this file's private members.
mixin SyncColumns on Table {
  late final id = text().clientDefault(() => const Uuid().v4())();
  late final createdAt = dateTime().withDefault(currentDateAndTime)();
  late final updatedAt = dateTime().withDefault(currentDateAndTime)();
  late final deletedAt = dateTime().nullable()();
  late final ownerId = text()();
  late final syncedAt = dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProfileRow')
class Profiles extends Table with SyncColumns {
  late final displayName = text()();
  late final nativeLang = text()();
  late final uiLang = text()();
}

@DataClassName('CourseRow')
class Courses extends Table with SyncColumns {
  late final title = text()();
  late final level = text()();
  late final publisher = text().withDefault(const Constant(''))();
  late final note = text().withDefault(const Constant(''))();
}

@DataClassName('UnitRow')
class Units extends Table with SyncColumns {
  late final courseId = text().references(Courses, #id)();
  late final code = text()();
  late final title = text()();
  late final grammarTopic = text().withDefault(const Constant(''))();
  late final vocabTopic = text().withDefault(const Constant(''))();
  late final orderIndex = integer().withDefault(const Constant(0))();
  late final studiedAt = dateTime().nullable()();
}

enum WordSetSource { manual, paste, photo }

@DataClassName('WordSetRow')
class WordSets extends Table with SyncColumns {
  late final unitId = text().nullable().references(Units, #id)();
  late final title = text()();
  late final source = textEnum<WordSetSource>()();
  late final formatVersion = integer().withDefault(const Constant(1))();
}

@DataClassName('CardRow')
class Cards extends Table with SyncColumns {
  late final setId = text().references(WordSets, #id)();
  late final term = text()();
  late final translation = text()();
  late final transcription = text().withDefault(const Constant(''))();
  late final partOfSpeech = text().withDefault(const Constant(''))();
  /// JSON-encoded list of example sentence strings.
  late final examples = text().withDefault(const Constant('[]'))();
  late final note = text().withDefault(const Constant(''))();
  late final imageRef = text().nullable()();
}

/// Caches LLM responses by request hash so the same word/batch is never
/// re-sent to Gemini twice — required to stay inside the free tier's limits.
@DataClassName('LlmCacheRow')
class LlmCaches extends Table with SyncColumns {
  late final requestHash = text()();
  late final responseJson = text()();
}

@DataClassName('DictationSessionRow')
class DictationSessions extends Table with SyncColumns {
  late final setId = text().references(WordSets, #id)();
  late final direction = textEnum<DictationDirection>()();
  late final startedAt = dateTime().withDefault(currentDateAndTime)();
  late final finishedAt = dateTime().nullable()();
  late final roundsCount = integer().withDefault(const Constant(0))();
  late final totalWords = integer().withDefault(const Constant(0))();
  /// Not in PLAN.md's data model, but required to correctly replay
  /// DictationEngine.resume() — without the original stack size and
  /// streak requirement, a resumed session's round math would diverge
  /// from what actually happened.
  late final stackSize = integer().withDefault(const Constant(12))();
  late final requiredStreak = integer().withDefault(const Constant(1))();
}

enum DictationDirection { ruEn, enRu }

enum DictationVerdictColumn { correct, typo, wrong, skipped }

enum DictationCheckedBy { local, llm }

@DataClassName('DictationAnswerRow')
class DictationAnswers extends Table with SyncColumns {
  late final sessionId = text().references(DictationSessions, #id)();
  late final cardId = text().references(Cards, #id)();
  late final roundIndex = integer()();
  late final userInput = text()();
  late final verdict = textEnum<DictationVerdictColumn>()();
  late final checkedBy = textEnum<DictationCheckedBy>().withDefault(const Constant('local'))();
}

enum SrsCardStateColumn { learning, review, relearning }

/// SRS scheduling state, one row per (card, direction) — a card can be due
/// for RU→EN before it's due for EN→RU. [step] isn't in PLAN.md's data
/// model but is required to correctly resume package:fsrs's learning-step
/// position across app restarts; [reps]/[lapses] are tracked by the app,
/// since the fsrs package itself doesn't expose them.
@DataClassName('CardStateRow')
class CardStates extends Table with SyncColumns {
  late final cardId = text().references(Cards, #id)();
  late final direction = textEnum<DictationDirection>()();
  late final due = dateTime()();
  late final stability = real().nullable()();
  late final difficulty = real().nullable()();
  late final step = integer().nullable()();
  late final reps = integer().withDefault(const Constant(0))();
  late final lapses = integer().withDefault(const Constant(0))();
  late final state = textEnum<SrsCardStateColumn>().withDefault(const Constant('learning'))();
  late final lastReview = dateTime().nullable()();
}
