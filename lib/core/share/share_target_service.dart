// ignore_for_file: prefer_initializing_formals -- named params stay public while fields are private.
import '../../domain/models/unit.dart';
import '../../domain/models/word_set.dart';
import '../../domain/repositories/course_repository.dart';
import '../../domain/repositories/unit_repository.dart';
import '../../domain/repositories/word_set_repository.dart';
import '../text/russian_date.dart';

class ShareTarget {
  final String setId;
  final Unit unit;

  const ShareTarget({required this.setId, required this.unit});
}

/// Picks where words shared from another app land: the newest unit the
/// learner has, or a fresh "Урок 24 сентября" in "Мой курс" if there is none.
class ShareTargetService {
  final CourseRepository _courses;
  final UnitRepository _units;
  final WordSetRepository _wordSets;
  final DateTime Function() _now;

  ShareTargetService({
    required CourseRepository courses,
    required UnitRepository units,
    required WordSetRepository wordSets,
    DateTime Function()? now,
  })  : _courses = courses,
        _units = units,
        _wordSets = wordSets,
        _now = now ?? DateTime.now;

  Future<ShareTarget> resolve() async {
    final courses = await _courses.watchCourses().first;

    Unit? newest;
    for (final course in courses) {
      for (final unit in await _units.watchUnits(course.id).first) {
        if (newest == null || unit.createdAt.isAfter(newest.createdAt)) newest = unit;
      }
    }

    if (newest == null) {
      final course = courses.isNotEmpty
          ? courses.first
          : await _courses.createCourse(title: 'Мой курс', level: 'A2');
      newest = await _units.createUnit(courseId: course.id, code: 'Урок ${RussianDate.dayAndMonth(_now())}', title: '');
    }

    final sets = await _wordSets.watchWordSets(unitId: newest.id).first;
    final wordSet = sets.isNotEmpty
        ? sets.first
        : await _wordSets.createWordSet(unitId: newest.id, title: newest.code, source: WordSetSource.paste);
    return ShareTarget(setId: wordSet.id, unit: newest);
  }
}
