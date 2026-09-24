/// A hand-rolled formatter for the one date format the app needs
/// ("Вторник, 23 сентября") — not worth pulling in intl for.
class RussianDate {
  static const _weekdays = [
    'понедельник',
    'вторник',
    'среда',
    'четверг',
    'пятница',
    'суббота',
    'воскресенье',
  ];

  static const _months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  static String longFormat(DateTime date) {
    final weekday = _weekdays[date.weekday - 1];
    final capitalized = weekday[0].toUpperCase() + weekday.substring(1);
    return '$capitalized, ${date.day} ${_months[date.month - 1]}';
  }

  /// "Четверг" — the screen title on the main tab.
  static String weekdayTitle(DateTime date) {
    final weekday = _weekdays[date.weekday - 1];
    return weekday[0].toUpperCase() + weekday.substring(1);
  }

  /// "25 сентября".
  static String dayAndMonth(DateTime date) => '${date.day} ${_months[date.month - 1]}';
}
