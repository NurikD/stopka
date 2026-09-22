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
