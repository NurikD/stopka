class WordCard {
  final String id;
  final String setId;
  final String term;
  final String translation;
  final String transcription;
  final String partOfSpeech;
  final List<String> examples;
  final String note;
  final String? imageRef;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const WordCard({
    required this.id,
    required this.setId,
    required this.term,
    required this.translation,
    required this.transcription,
    required this.partOfSpeech,
    required this.examples,
    required this.note,
    this.imageRef,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  WordCard copyWith({
    String? term,
    String? translation,
    String? transcription,
    String? partOfSpeech,
    List<String>? examples,
    String? note,
    String? imageRef,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return WordCard(
      id: id,
      setId: setId,
      term: term ?? this.term,
      translation: translation ?? this.translation,
      transcription: transcription ?? this.transcription,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      examples: examples ?? this.examples,
      note: note ?? this.note,
      imageRef: imageRef ?? this.imageRef,
      ownerId: ownerId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
