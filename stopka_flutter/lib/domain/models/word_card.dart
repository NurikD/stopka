class WordCard {
  final String id;
  final String setId;
  final String term;
  final String translation;
  final String transcription;
  final String partOfSpeech;
  final List<String> examples;

  /// Russian translations of [examples], same order; may be shorter when a
  /// card was enriched before translations existed.
  final List<String> exampleTranslations;
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
    this.exampleTranslations = const [],
    required this.note,
    this.imageRef,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Examples that have a translation, as (English, Russian) pairs.
  List<(String, String)> get translatedExamples => [
    for (var i = 0; i < examples.length && i < exampleTranslations.length; i++)
      if (examples[i].trim().isNotEmpty && exampleTranslations[i].trim().isNotEmpty)
        (examples[i].trim(), exampleTranslations[i].trim()),
  ];

  WordCard copyWith({
    String? term,
    String? translation,
    String? transcription,
    String? partOfSpeech,
    List<String>? examples,
    List<String>? exampleTranslations,
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
      exampleTranslations: exampleTranslations ?? this.exampleTranslations,
      note: note ?? this.note,
      imageRef: imageRef ?? this.imageRef,
      ownerId: ownerId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
