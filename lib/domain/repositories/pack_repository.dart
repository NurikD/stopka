import '../../core/pack/pack_content.dart';
import '../models/unit_pack.dart';

abstract class PackRepository {
  Future<UnitPack?> findByKey(PackKey key);

  /// Returns the pack for [key], creating an empty one (all parts pending)
  /// when there is none yet.
  Future<UnitPack> getOrCreate(PackKey key);

  Future<UnitPack?> getPack(String id);

  Stream<UnitPack?> watchPack(String id);

  /// Stores [payload] (when given) and the new [status] for one part. A
  /// non-ready status drops any stored payload of that part.
  Future<void> setPart(String packId, PackPart part, {Map<String, dynamic>? payload, required PartStatus status});

  Future<void> saveProgress(String packId, PackPart part, {required int score, required int total});

  /// Latest progress per part, once.
  Future<Map<PackPart, PackProgress>> getProgress(String packId);

  /// Latest progress per part.
  Stream<Map<PackPart, PackProgress>> watchProgress(String packId);

  Future<void> logAttempt(
    String packId,
    PackPart part, {
    required int itemIndex,
    required String userAnswer,
    required bool isCorrect,
  });

  Future<void> saveWritingAttempt(
    String packId, {
    required String userText,
    required String correctedText,
    required String nativeText,
    required String summary,
  });

  Future<void> addMistakes(String? packId, List<MistakeInput> mistakes);
}
