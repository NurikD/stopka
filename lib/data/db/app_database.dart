import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
// Used by the generated code below: drift_dev copies the SyncColumns.id
// clientDefault closure's source text into app_database.g.dart (a part of
// this library), which resolves `Uuid` against this file's imports.
import 'package:uuid/uuid.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Profiles,
    Courses,
    Units,
    WordSets,
    Cards,
    LlmCaches,
    DictationSessions,
    DictationAnswers,
    CardStates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(llmCaches);
        }
        if (from < 3) {
          await m.createTable(dictationSessions);
          await m.createTable(dictationAnswers);
        }
        if (from < 4) {
          await m.createTable(cardStates);
        }
      },
    );
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'stopka',
    native: const DriftNativeOptions(
      databaseDirectory: getApplicationSupportDirectory,
    ),
    // Only used when running on the web (e.g. `flutter run -d chrome` for
    // quick manual checks without an Android device). Android is still the
    // priority platform per the plan; this doesn't affect native builds.
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.dart.js'),
    ),
  );
}
