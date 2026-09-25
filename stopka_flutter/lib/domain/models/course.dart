class Course {
  final String id;
  final String title;
  final String level;
  final String publisher;
  final String note;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Course({
    required this.id,
    required this.title,
    required this.level,
    required this.publisher,
    required this.note,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Course copyWith({
    String? title,
    String? level,
    String? publisher,
    String? note,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Course(
      id: id,
      title: title ?? this.title,
      level: level ?? this.level,
      publisher: publisher ?? this.publisher,
      note: note ?? this.note,
      ownerId: ownerId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

/// Common CEFR levels shown as picker options. The field itself is free
/// text in storage, since the plan allows any level string.
const List<String> cefrLevels = ['A1', 'A2', 'B1', 'B2', 'C1'];
