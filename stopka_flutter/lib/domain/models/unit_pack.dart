import '../../core/pack/pack_content.dart';

class UnitPack {
  final String id;
  final String packKey;
  final String level;
  final String grammarTopic;
  final String vocabTopic;
  final String interest;
  final int schemaVersion;

  /// Validated part JSON, only for parts that are ready.
  final Map<PackPart, Map<String, dynamic>> payload;
  final Map<PackPart, PartStatus> statuses;

  const UnitPack({
    required this.id,
    required this.packKey,
    required this.level,
    required this.grammarTopic,
    required this.vocabTopic,
    required this.interest,
    required this.schemaVersion,
    required this.payload,
    required this.statuses,
  });

  PartStatus statusOf(PackPart part) => statuses[part] ?? PartStatus.pending;

  Map<String, dynamic>? payloadOf(PackPart part) => payload[part];
}

class PackProgress {
  final PackPart part;
  final DateTime completedAt;
  final int score;
  final int total;

  const PackProgress({required this.part, required this.completedAt, required this.score, required this.total});
}

class MistakeInput {
  final String skill;
  final String category;
  final String original;
  final String corrected;
  final String explanation;

  const MistakeInput({
    required this.skill,
    required this.category,
    this.original = '',
    this.corrected = '',
    this.explanation = '',
  });
}
