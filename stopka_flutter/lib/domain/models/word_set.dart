enum WordSetSource { manual, paste, photo }

class WordSet {
  final String id;
  final String? unitId;
  final String title;
  final WordSetSource source;
  final int formatVersion;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const WordSet({
    required this.id,
    this.unitId,
    required this.title,
    required this.source,
    required this.formatVersion,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  WordSet copyWith({
    String? unitId,
    String? title,
    WordSetSource? source,
    int? formatVersion,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return WordSet(
      id: id,
      unitId: unitId ?? this.unitId,
      title: title ?? this.title,
      source: source ?? this.source,
      formatVersion: formatVersion ?? this.formatVersion,
      ownerId: ownerId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
