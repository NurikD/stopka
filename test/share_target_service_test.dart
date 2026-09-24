import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/share/share_target_service.dart';
import 'package:stopka/data/db/app_database.dart';
import 'package:stopka/data/repositories/course_repository_impl.dart';
import 'package:stopka/data/repositories/profile_repository_impl.dart';
import 'package:stopka/data/repositories/unit_repository_impl.dart';
import 'package:stopka/data/repositories/word_set_repository_impl.dart';

void main() {
  late AppDatabase db;
  late DriftCourseRepository courses;
  late DriftUnitRepository units;
  late ShareTargetService service;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final profile = await DriftProfileRepository(db).ensureProfile();
    courses = DriftCourseRepository(db, profile.id);
    units = DriftUnitRepository(db, profile.id);
    service = ShareTargetService(
      courses: courses,
      units: units,
      wordSets: DriftWordSetRepository(db, profile.id),
      now: () => DateTime(2026, 9, 24),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('with nothing yet it makes a course and a dated unit, and reuses them next time', () async {
    final first = await service.resolve();
    expect(first.unit.code, 'Урок 24 сентября');
    expect((await courses.watchCourses().first).single.title, 'Мой курс');

    final second = await service.resolve();
    expect(second.setId, first.setId);
    expect((await courses.watchCourses().first).length, 1);
  });

  test('otherwise the newest unit wins', () async {
    final course = await courses.createCourse(title: 'Headway', level: 'B1');
    await units.createUnit(courseId: course.id, code: '1A', title: '');
    await Future<void>.delayed(const Duration(milliseconds: 1100)); // createdAt has second resolution
    final newer = await units.createUnit(courseId: course.id, code: '1B', title: '');

    final target = await service.resolve();
    expect(target.unit.id, newer.id);
  });
}
