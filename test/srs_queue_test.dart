import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/srs/srs_queue.dart';
import 'package:stopka/core/text/russian_date.dart';

void main() {
  group('reviewQueueSize', () {
    test('caps new cards at the limit but never the due ones', () {
      expect(reviewQueueSize(due: 12, fresh: 45, newCardLimit: 20), 32);
    });

    test('fewer new cards than the limit are all served', () {
      expect(reviewQueueSize(due: 3, fresh: 5, newCardLimit: 20), 8);
    });

    test('nothing due and nothing new is an empty queue', () {
      expect(reviewQueueSize(due: 0, fresh: 0, newCardLimit: 20), 0);
    });

    test('a limit of zero serves only due cards', () {
      expect(reviewQueueSize(due: 4, fresh: 30, newCardLimit: 0), 4);
    });
  });

  group('RussianDate', () {
    // 2026-09-24 is a Thursday.
    final thursday = DateTime(2026, 9, 24);

    test('weekdayTitle is capitalised', () {
      expect(RussianDate.weekdayTitle(thursday), 'Четверг');
    });

    test('dayAndMonth uses the genitive month', () {
      expect(RussianDate.dayAndMonth(thursday), '24 сентября');
    });

    test('longFormat still combines both', () {
      expect(RussianDate.longFormat(thursday), 'Четверг, 24 сентября');
    });
  });
}
