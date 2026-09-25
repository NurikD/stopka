import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/llm/unit_page_service.dart';
import 'package:stopka/core/onboarding/onboarding_service.dart';
import 'package:stopka/core/onboarding/starter_content.dart';
import 'package:stopka/data/db/app_database.dart';
import 'package:stopka/data/repositories/course_repository_impl.dart';
import 'package:stopka/data/repositories/profile_repository_impl.dart';
import 'package:stopka/data/repositories/unit_repository_impl.dart';
import 'package:stopka/data/repositories/word_card_repository_impl.dart';
import 'package:stopka/data/repositories/word_set_repository_impl.dart';

void main() {
  late AppDatabase db;
  late DriftProfileRepository profiles;
  late DriftUnitRepository units;
  late DriftWordCardRepository cards;
  late DriftCourseRepository courses;
  late DriftWordSetRepository sets;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    profiles = DriftProfileRepository(db);
    final profile = await profiles.ensureProfile();
    courses = DriftCourseRepository(db, profile.id);
    units = DriftUnitRepository(db, profile.id);
    sets = DriftWordSetRepository(db, profile.id);
    cards = DriftWordCardRepository(db, profile.id);
  });

  tearDown(() async {
    await db.close();
  });

  OnboardingService service({PersonalWordsFn? personal}) => OnboardingService(
        profiles: profiles,
        courses: courses,
        units: units,
        wordSets: sets,
        cards: cards,
        personalWords: personal,
        now: () => DateTime(2026, 9, 24),
      );

  test('without a key: profile is saved, course and unit are created, offline words are ready', () async {
    final result = await service().finish(level: 'B1', interestIds: ['travel', 'games']);

    final profile = await profiles.ensureProfile();
    expect(profile.isOnboarded, isTrue);
    expect(profile.level, 'B1');
    expect(profile.interests, ['travel', 'games']);

    final course = await courses.getCourse(result.courseId);
    expect(course!.title, 'Мой курс');
    expect(course.level, 'B1');

    final unit = await units.getUnit(result.unitId);
    expect(unit!.code, 'Урок 24 сентября');

    final saved = await cards.watchCards(result.setId).first;
    expect(saved.length, result.wordCount);
    expect(saved.map((c) => c.term), contains('achieve'));
    expect(saved.map((c) => c.term), contains('luggage'));
    expect(saved.every((c) => c.translation.isNotEmpty), isTrue);
    expect(result.personal, isFalse);
  });

  test('"не знаю" starts from A2 words', () async {
    final result = await service().finish(level: '', interestIds: []);
    final saved = await cards.watchCards(result.setId).first;
    expect(saved.map((c) => c.term), contains('borrow'));
    expect((await courses.getCourse(result.courseId))!.level, 'A2');
  });

  test('a photographed page names the unit and its topics', () async {
    final result = await service().finish(
      level: 'A2',
      interestIds: [],
      page: const UnitPageInfo(code: 'Unit 4B', title: 'Around the world', grammarTopic: 'Present perfect', vocabTopic: 'Travel'),
    );
    final unit = (await units.getUnit(result.unitId))!;
    expect(unit.code, 'Unit 4B');
    expect(unit.title, 'Around the world');
    expect(unit.grammarTopic, 'Present perfect');
    expect(unit.vocabTopic, 'Travel');
  });

  test('with a key the personal words replace the offline ones', () async {
    String? seenTopic;
    final result = await service(personal: ({required level, required interests, required topic}) async {
      seenTopic = topic;
      return const [StarterWord('quest', 'задание'), StarterWord('boss', 'босс')];
    }).finish(level: 'A2', interestIds: ['games'], topic: 'Past simple');

    expect(result.personal, isTrue);
    expect(seenTopic, 'Past simple');
    final saved = await cards.watchCards(result.setId).first;
    expect(saved.map((c) => c.term), unorderedEquals(['quest', 'boss']));
  });

  test('a failing model falls back to the offline words instead of failing onboarding', () async {
    final result = await service(personal: ({required level, required interests, required topic}) async {
      throw Exception('offline');
    }).finish(level: 'A1', interestIds: []);

    expect(result.personal, isFalse);
    final saved = await cards.watchCards(result.setId).first;
    expect(saved.map((c) => c.term), contains('house'));
  });

  test('starter words never repeat and cap interests at three', () {
    final words = starterWords(level: 'A1', interestIds: ['games', 'travel', 'films', 'music']);
    final terms = words.map((w) => w.term).toList();
    expect(terms.toSet().length, terms.length);
    expect(terms, contains('quest'));
    expect(terms, contains('plot'));
    expect(terms, isNot(contains('lyrics')));
  });
}
