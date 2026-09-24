import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../db/app_database.dart';

const _uuid = Uuid();

Profile _toDomain(ProfileRow row) {
  return Profile(
    id: row.id,
    displayName: row.displayName,
    nativeLang: row.nativeLang,
    uiLang: row.uiLang,
    level: row.level,
    interests: row.interests.isEmpty ? const [] : row.interests.split(','),
    currentTopic: row.currentTopic,
    onboardedAt: row.onboardedAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  );
}

class DriftProfileRepository implements ProfileRepository {
  final AppDatabase _db;

  DriftProfileRepository(this._db);

  Selectable<ProfileRow> get _activeRow {
    final query = _db.select(_db.profiles)..where((t) => t.deletedAt.isNull());
    query.limit(1);
    return query;
  }

  @override
  Stream<Profile?> watchProfile() {
    return _activeRow.watchSingleOrNull().map((row) => row == null ? null : _toDomain(row));
  }

  @override
  Future<Profile> ensureProfile({
    String displayName = 'Я',
    String nativeLang = 'ru',
    String uiLang = 'ru',
  }) async {
    final existing = await _activeRow.getSingleOrNull();
    if (existing != null) return _toDomain(existing);

    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.into(_db.profiles).insert(
          ProfilesCompanion.insert(
            id: Value(id),
            displayName: displayName,
            nativeLang: nativeLang,
            uiLang: uiLang,
            ownerId: id,
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    final row = await (_db.select(_db.profiles)..where((t) => t.id.equals(id))).getSingle();
    return _toDomain(row);
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    await (_db.update(_db.profiles)..where((t) => t.id.equals(profile.id))).write(
      ProfilesCompanion(
        displayName: Value(profile.displayName),
        nativeLang: Value(profile.nativeLang),
        uiLang: Value(profile.uiLang),
        level: Value(profile.level),
        interests: Value(profile.interests.join(',')),
        currentTopic: Value(profile.currentTopic),
        onboardedAt: Value(profile.onboardedAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
