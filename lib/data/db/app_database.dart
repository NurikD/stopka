import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
// Used by the generated code below: drift_dev copies the SyncColumns.id
// clientDefault closure's source text into app_database.g.dart (a part of
// this library), which resolves `Uuid` against this file's imports.
import 'package:uuid/uuid.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Profiles, Courses, Units, WordSets, Cards])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
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
