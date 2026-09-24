import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/card_state_repository_impl.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../data/repositories/dictation_repository_impl.dart';
import '../../data/repositories/llm_cache_repository_impl.dart';
import '../../data/repositories/pack_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/unit_repository_impl.dart';
import '../../data/repositories/word_card_repository_impl.dart';
import '../../data/repositories/word_set_repository_impl.dart';
import '../../domain/models/profile.dart';
import '../../domain/repositories/card_state_repository.dart';
import '../../domain/repositories/course_repository.dart';
import '../../domain/repositories/dictation_repository.dart';
import '../../domain/repositories/llm_cache_repository.dart';
import '../../domain/repositories/pack_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/unit_repository.dart';
import '../../domain/repositories/word_card_repository.dart';
import '../../domain/repositories/word_set_repository.dart';
import '../analytics/event_logger.dart';
import '../llm/answer_appeal_service.dart';
import '../llm/api_key_store.dart';
import '../llm/card_enrichment_service.dart';
import '../llm/gemini_llm_client.dart';
import '../llm/llm_client.dart';
import '../llm/llm_request_counter.dart';
import '../llm/throttled_llm_client.dart';
import '../llm/personal_words_service.dart';
import '../llm/unit_page_service.dart';
import '../llm/writing_check_service.dart';
import '../llm/word_recognition_service.dart';
import '../onboarding/onboarding_service.dart';
import '../pack/content_source.dart';
import '../pack/pack_service.dart';
import '../srs/srs_engine.dart';
import '../srs/srs_settings_store.dart';
import '../theme/theme_mode_store.dart';
import '../tts/tts_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return DriftProfileRepository(ref.watch(appDatabaseProvider));
});

/// The local profile stream. Everything below reads [currentOwnerIdProvider]
/// instead of hardcoding an id, so wiring in real accounts later only means
/// changing how the profile is created, not every call site.
final currentProfileProvider = StreamProvider<Profile?>((ref) {
  return ref.watch(profileRepositoryProvider).watchProfile();
});

final currentOwnerIdProvider = Provider<String?>((ref) {
  return ref.watch(currentProfileProvider).value?.id;
});

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider) ?? '';
  return DriftCourseRepository(ref.watch(appDatabaseProvider), ownerId);
});

final unitRepositoryProvider = Provider<UnitRepository>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider) ?? '';
  return DriftUnitRepository(ref.watch(appDatabaseProvider), ownerId);
});

final wordSetRepositoryProvider = Provider<WordSetRepository>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider) ?? '';
  return DriftWordSetRepository(ref.watch(appDatabaseProvider), ownerId);
});

final wordCardRepositoryProvider = Provider<WordCardRepository>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider) ?? '';
  return DriftWordCardRepository(ref.watch(appDatabaseProvider), ownerId);
});

final llmCacheRepositoryProvider = Provider<LlmCacheRepository>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider) ?? '';
  return DriftLlmCacheRepository(ref.watch(appDatabaseProvider), ownerId);
});

final apiKeyStoreProvider = Provider<ApiKeyStore>((ref) => ApiKeyStore());

final llmRequestCounterProvider = Provider<LlmRequestCounter>((ref) => LlmRequestCounter());

final llmClientProvider = Provider<LlmClient>((ref) {
  final gemini = GeminiLlmClient(ref.watch(apiKeyStoreProvider));
  return ThrottledLlmClient(gemini, ref.watch(llmRequestCounterProvider));
});

final eventLoggerProvider = Provider<EventLogger>((ref) => NoopEventLogger());

final wordRecognitionServiceProvider = Provider<WordRecognitionService>((ref) {
  return WordRecognitionService(ref.watch(llmClientProvider));
});

final cardEnrichmentServiceProvider = Provider<CardEnrichmentService>((ref) {
  return CardEnrichmentService(ref.watch(llmClientProvider), ref.watch(llmCacheRepositoryProvider));
});

final unitPageServiceProvider = Provider<UnitPageService>((ref) {
  return UnitPageService(ref.watch(llmClientProvider));
});

final personalWordsServiceProvider = Provider<PersonalWordsService>((ref) {
  return PersonalWordsService(ref.watch(llmClientProvider));
});

/// Whether a Gemini key is stored. Nothing is blocked without one; AI
/// features read this to say honestly that they need a key.
final hasApiKeyProvider = FutureProvider.autoDispose<bool>((ref) async {
  final key = await ref.watch(apiKeyStoreProvider).getApiKey();
  return key != null && key.trim().isNotEmpty;
});

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final personal = ref.watch(personalWordsServiceProvider);
  return OnboardingService(
    profiles: ref.watch(profileRepositoryProvider),
    courses: ref.watch(courseRepositoryProvider),
    units: ref.watch(unitRepositoryProvider),
    wordSets: ref.watch(wordSetRepositoryProvider),
    cards: ref.watch(wordCardRepositoryProvider),
    personalWords: ({required level, required interests, required topic}) async {
      // Without a key the personal list is impossible; the service then
      // falls back to the offline words.
      if (!await ref.read(apiKeyStoreProvider).hasKey()) throw StateError('no key');
      // A slow model must not hold the first minute hostage.
      return personal
          .generate(level: level, interests: interests, topic: topic)
          .timeout(const Duration(seconds: 20));
    },
  );
});

final packRepositoryProvider = Provider<PackRepository>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider) ?? '';
  return DriftPackRepository(ref.watch(appDatabaseProvider), ownerId);
});

final contentSourceProvider = Provider<ContentSource>((ref) {
  return GeneratedContentSource(ref.watch(llmClientProvider));
});

/// Kept alive for the whole run, so a pack keeps generating while the
/// learner moves between screens.
final packServiceProvider = Provider<PackService>((ref) {
  final store = ref.watch(apiKeyStoreProvider);
  return PackService(
    repo: ref.watch(packRepositoryProvider),
    source: ref.watch(contentSourceProvider),
    hasKey: store.hasKey,
  );
});

final writingCheckServiceProvider = Provider<WritingCheckService>((ref) {
  return WritingCheckService(ref.watch(llmClientProvider));
});

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());

final dictationRepositoryProvider = Provider<DictationRepository>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider) ?? '';
  return DriftDictationRepository(ref.watch(appDatabaseProvider), ownerId);
});

final answerAppealServiceProvider = Provider<AnswerAppealService>((ref) {
  return AnswerAppealService(ref.watch(llmClientProvider));
});

final cardStateRepositoryProvider = Provider<CardStateRepository>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider) ?? '';
  return DriftCardStateRepository(ref.watch(appDatabaseProvider), ownerId);
});

final srsEngineProvider = Provider<SrsEngine>((ref) => SrsEngine());

final srsSettingsStoreProvider = Provider<SrsSettingsStore>((ref) => SrsSettingsStore());

final themeModeStoreProvider = Provider<ThemeModeStore>((ref) => ThemeModeStore());

/// The user's manual theme choice. Starts as "follow the system" and swaps
/// to the saved value as soon as it has been read.
class ThemeModeController extends Notifier<ThemeMode> {
  bool _chosenByUser = false;

  @override
  ThemeMode build() {
    _chosenByUser = false;
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final saved = await ref.read(themeModeStoreProvider).load();
    // A choice made while the saved value was still loading wins.
    if (ref.mounted && !_chosenByUser) state = saved;
  }

  Future<void> set(ThemeMode mode) async {
    _chosenByUser = true;
    state = mode;
    await ref.read(themeModeStoreProvider).save(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Both are cheap reads that go stale when a review finishes; the screens
/// that show them invalidate after returning from a session.
final newCardLimitProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(srsSettingsStoreProvider).getNewCardLimit();
});

final streakDaysProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(cardStateRepositoryProvider).getStreakDays();
});

/// Graded reviews since local midnight — the "done" half of today's words.
final reviewsTodayProvider = FutureProvider.autoDispose<int>((ref) {
  final now = DateTime.now();
  return ref.watch(cardStateRepositoryProvider).countReviewsSince(DateTime(now.year, now.month, now.day));
});
