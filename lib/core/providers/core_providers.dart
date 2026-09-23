import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/card_state_repository_impl.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../data/repositories/dictation_repository_impl.dart';
import '../../data/repositories/llm_cache_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/unit_repository_impl.dart';
import '../../data/repositories/word_card_repository_impl.dart';
import '../../data/repositories/word_set_repository_impl.dart';
import '../../domain/models/profile.dart';
import '../../domain/repositories/card_state_repository.dart';
import '../../domain/repositories/course_repository.dart';
import '../../domain/repositories/dictation_repository.dart';
import '../../domain/repositories/llm_cache_repository.dart';
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
import '../llm/word_recognition_service.dart';
import '../srs/srs_engine.dart';
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

final llmClientProvider = Provider<LlmClient>((ref) {
  return GeminiLlmClient(ref.watch(apiKeyStoreProvider));
});

final eventLoggerProvider = Provider<EventLogger>((ref) => NoopEventLogger());

final wordRecognitionServiceProvider = Provider<WordRecognitionService>((ref) {
  return WordRecognitionService(ref.watch(llmClientProvider));
});

final cardEnrichmentServiceProvider = Provider<CardEnrichmentService>((ref) {
  return CardEnrichmentService(ref.watch(llmClientProvider), ref.watch(llmCacheRepositoryProvider));
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
