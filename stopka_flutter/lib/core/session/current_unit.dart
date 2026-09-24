import '../../domain/models/unit.dart';
import '../../domain/repositories/course_repository.dart';
import '../../domain/repositories/unit_repository.dart';

/// The unit the learner is working on: the newest one across all courses.
Future<Unit?> findNewestUnit(CourseRepository courses, UnitRepository units) async {
  Unit? newest;
  for (final course in await courses.watchCourses().first) {
    for (final unit in await units.watchUnits(course.id).first) {
      if (newest == null || unit.createdAt.isAfter(newest.createdAt)) newest = unit;
    }
  }
  return newest;
}
