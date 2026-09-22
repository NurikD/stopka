import 'package:drift/drift.dart';

import '../../domain/repositories/llm_cache_repository.dart';
import '../db/app_database.dart';

class DriftLlmCacheRepository implements LlmCacheRepository {
  final AppDatabase _db;
  final String _ownerId;

  DriftLlmCacheRepository(this._db, this._ownerId);

  @override
  Future<String?> get(String requestHash) async {
    final row = await (_db.select(_db.llmCaches)
          ..where((t) => t.requestHash.equals(requestHash) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row?.responseJson;
  }

  @override
  Future<void> put(String requestHash, String responseJson) async {
    final existing = await (_db.select(_db.llmCaches)..where((t) => t.requestHash.equals(requestHash)))
        .getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.llmCaches)..where((t) => t.id.equals(existing.id))).write(
        LlmCachesCompanion(
          responseJson: Value(responseJson),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return;
    }
    await _db.into(_db.llmCaches).insert(
          LlmCachesCompanion.insert(
            requestHash: requestHash,
            responseJson: responseJson,
            ownerId: _ownerId,
          ),
        );
  }
}
