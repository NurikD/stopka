// ignore_for_file: prefer_initializing_formals -- named params stay public while fields are private.

import '../../domain/models/word_set.dart';
import '../../domain/repositories/course_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/unit_repository.dart';
import '../../domain/repositories/word_card_repository.dart';
import '../../domain/repositories/word_set_repository.dart';
import '../llm/unit_page_service.dart';
import '../text/russian_date.dart';
import 'starter_content.dart';

typedef PersonalWordsFn = Future<List<StarterWord>> Function({
  required String level,
  required List<String> interests,
  required String topic,
});

class OnboardingResult {
  final String courseId;
  final String unitId;
  final String setId;
  final int wordCount;

  /// True when the words came from the model rather than the offline list.
  final bool personal;

  const OnboardingResult({
    required this.courseId,
    required this.unitId,
    required this.setId,
    required this.wordCount,
    required this.personal,
  });
}

/// Turns the onboarding answers into a profile, an automatic course and unit,
/// and a first word set. Never needs a key: when [personalWords] is missing or
/// fails, the offline [starterWords] are used instead.
class OnboardingService {
  final ProfileRepository _profiles;
  final CourseRepository _courses;
  final UnitRepository _units;
  final WordSetRepository _wordSets;
  final WordCardRepository _cards;
  final PersonalWordsFn? _personalWords;
  final DateTime Function() _now;

  OnboardingService({
    required ProfileRepository profiles,
    required CourseRepository courses,
    required UnitRepository units,
    required WordSetRepository wordSets,
    required WordCardRepository cards,
    PersonalWordsFn? personalWords,
    DateTime Function()? now,
  })  : _profiles = profiles,
        _courses = courses,
        _units = units,
        _wordSets = wordSets,
        _cards = cards,
        _personalWords = personalWords,
        _now = now ?? DateTime.now;

  Future<OnboardingResult> finish({
    required String level,
    required List<String> interestIds,
    String topic = '',
    UnitPageInfo? page,
  }) async {
    final topicText = topic.trim();
    final profile = await _profiles.ensureProfile();
    await _profiles.updateProfile(profile.copyWith(
      level: level,
      interests: interestIds,
      currentTopic: topicText,
      onboardedAt: _now(),
    ));

    final course = await _courses.createCourse(title: 'Мой курс', level: effectiveLevel(level));

    final code = (page?.code.isNotEmpty ?? false) ? page!.code : 'Урок ${RussianDate.dayAndMonth(_now())}';
    final vocabTopic = (page?.vocabTopic.isNotEmpty ?? false) ? page!.vocabTopic : topicText;
    final unit = await _units.createUnit(
      courseId: course.id,
      code: code,
      title: page?.title ?? '',
      grammarTopic: page?.grammarTopic ?? '',
      vocabTopic: vocabTopic,
    );

    final wordSet = await _wordSets.createWordSet(unitId: unit.id, title: code, source: WordSetSource.manual);

    var personal = false;
    List<StarterWord> words;
    final generate = _personalWords;
    if (generate != null) {
      try {
        words = await generate(
          level: level,
          interests: interestIds,
          topic: [topicText, vocabTopic].firstWhere((t) => t.isNotEmpty, orElse: () => ''),
        );
        personal = true;
      } catch (_) {
        words = starterWords(level: level, interestIds: interestIds);
      }
    } else {
      words = starterWords(level: level, interestIds: interestIds);
    }

    for (final word in words) {
      await _cards.createCard(setId: wordSet.id, term: word.term, translation: word.translation);
    }

    return OnboardingResult(
      courseId: course.id,
      unitId: unit.id,
      setId: wordSet.id,
      wordCount: words.length,
      personal: personal,
    );
  }
}
