import '../models/profile.dart';

abstract class ProfileRepository {
  /// The single local profile, created on first launch if missing.
  Stream<Profile?> watchProfile();

  Future<Profile> ensureProfile({
    String displayName = 'Я',
    String nativeLang = 'ru',
    String uiLang = 'ru',
  });

  Future<void> updateProfile(Profile profile);
}
