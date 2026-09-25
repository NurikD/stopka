import '../models/course.dart';

abstract class CourseRepository {
  Stream<List<Course>> watchCourses();

  Future<Course?> getCourse(String id);

  Future<Course> createCourse({
    required String title,
    required String level,
    String publisher = '',
    String note = '',
  });

  Future<void> updateCourse(Course course);

  /// Soft delete: sets deletedAt, never removes the row.
  Future<void> deleteCourse(String id);
}
