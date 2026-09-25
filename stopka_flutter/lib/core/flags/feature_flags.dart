/// Static switches for functionality that doesn't exist yet locally but is
/// planned (accounts, cloud sync, shared sets, analytics). Screens for these
/// aren't built, but navigation/branch points are reserved for them.
class FeatureFlags {
  static const bool auth = false;
  static const bool cloudSync = false;
  static const bool sharedSets = false;
  static const bool analytics = false;

  /// Developer switch: talk to Gemini directly with a personal key instead of
  /// the server. `flutter run --dart-define=STOPKA_DIRECT_GEMINI=true`.
  static const bool directGemini = bool.fromEnvironment('STOPKA_DIRECT_GEMINI');
}
