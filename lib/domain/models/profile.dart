class Profile {
  final String id;
  final String displayName;
  final String nativeLang;
  final String uiLang;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Profile({
    required this.id,
    required this.displayName,
    required this.nativeLang,
    required this.uiLang,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Profile copyWith({
    String? displayName,
    String? nativeLang,
    String? uiLang,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Profile(
      id: id,
      displayName: displayName ?? this.displayName,
      nativeLang: nativeLang ?? this.nativeLang,
      uiLang: uiLang ?? this.uiLang,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
