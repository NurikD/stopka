import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/text/russian_date.dart';

void main() {
  test('formats a Tuesday correctly', () {
    // 2026-09-22 is a Tuesday.
    expect(RussianDate.longFormat(DateTime(2026, 9, 22)), 'Вторник, 22 сентября');
  });

  test('formats a Sunday correctly', () {
    // 2026-09-27 is a Sunday.
    expect(RussianDate.longFormat(DateTime(2026, 9, 27)), 'Воскресенье, 27 сентября');
  });

  test('formats January correctly', () {
    expect(RussianDate.longFormat(DateTime(2026, 1, 1)), 'Четверг, 1 января');
  });
}
