class Profile {
  final String id;
  final String displayName;
  final String nativeLang;
  final String uiLang;
  final String level;
  final List<String> interests;
  final String currentTopic;
  final DateTime? onboardedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Profile({
    required this.id,
    required this.displayName,
    required this.nativeLang,
    required this.uiLang,
    this.level = '',
    this.interests = const [],
    this.currentTopic = '',
    this.onboardedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isOnboarded => onboardedAt != null;

  Profile copyWith({
    String? displayName,
    String? nativeLang,
    String? uiLang,
    String? level,
    List<String>? interests,
    String? currentTopic,
    DateTime? onboardedAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Profile(
      id: id,
      displayName: displayName ?? this.displayName,
      nativeLang: nativeLang ?? this.nativeLang,
      uiLang: uiLang ?? this.uiLang,
      level: level ?? this.level,
      interests: interests ?? this.interests,
      currentTopic: currentTopic ?? this.currentTopic,
      onboardedAt: onboardedAt ?? this.onboardedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
