class Unit {
  final String id;
  final String courseId;
  final String code;
  final String title;
  final String grammarTopic;
  final String vocabTopic;
  final int orderIndex;
  final DateTime? studiedAt;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Unit({
    required this.id,
    required this.courseId,
    required this.code,
    required this.title,
    required this.grammarTopic,
    required this.vocabTopic,
    required this.orderIndex,
    this.studiedAt,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Unit copyWith({
    String? code,
    String? title,
    String? grammarTopic,
    String? vocabTopic,
    int? orderIndex,
    DateTime? studiedAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Unit(
      id: id,
      courseId: courseId,
      code: code ?? this.code,
      title: title ?? this.title,
      grammarTopic: grammarTopic ?? this.grammarTopic,
      vocabTopic: vocabTopic ?? this.vocabTopic,
      orderIndex: orderIndex ?? this.orderIndex,
      studiedAt: studiedAt ?? this.studiedAt,
      ownerId: ownerId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
