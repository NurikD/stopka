import 'package:drift/drift.dart';

import '../../domain/models/course.dart';
import '../../domain/repositories/course_repository.dart';
import '../db/app_database.dart';

Course _toDomain(CourseRow row) {
  return Course(
    id: row.id,
    title: row.title,
    level: row.level,
    publisher: row.publisher,
    note: row.note,
    ownerId: row.ownerId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
  );
}

class DriftCourseRepository implements CourseRepository {
  final AppDatabase _db;
  final String _ownerId;

  DriftCourseRepository(this._db, this._ownerId);

  @override
  Stream<List<Course>> watchCourses() {
    final query = _db.select(_db.courses)
      ..where((t) => t.deletedAt.isNull() & t.ownerId.equals(_ownerId))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<Course?> getCourse(String id) async {
    final row = await (_db.select(_db.courses)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<Course> createCourse({
    required String title,
    required String level,
    String publisher = '',
    String note = '',
  }) async {
    final row = await _db.into(_db.courses).insertReturning(
          CoursesCompanion.insert(
            title: title,
            level: level,
            publisher: Value(publisher),
            note: Value(note),
            ownerId: _ownerId,
          ),
        );
    return _toDomain(row);
  }

  @override
  Future<void> updateCourse(Course course) async {
    await (_db.update(_db.courses)..where((t) => t.id.equals(course.id))).write(
      CoursesCompanion(
        title: Value(course.title),
        level: Value(course.level),
        publisher: Value(course.publisher),
        note: Value(course.note),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteCourse(String id) async {
    await (_db.update(_db.courses)..where((t) => t.id.equals(id))).write(
      CoursesCompanion(deletedAt: Value(DateTime.now())),
    );
  }
}
