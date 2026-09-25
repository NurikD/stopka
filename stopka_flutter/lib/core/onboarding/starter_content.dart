/// Offline starting content for onboarding, so the first dictation never
/// depends on a Gemini key. Deliberately generic vocabulary — it is a warm-up
/// by level and interest, not textbook content.
class StarterWord {
  final String term;
  final String translation;

  const StarterWord(this.term, this.translation);
}

class Interest {
  final String id;
  final String label;

  const Interest(this.id, this.label);
}

class LevelChoice {
  /// Empty for "не знаю" — treated as A2 until results say otherwise.
  final String id;
  final String label;

  const LevelChoice(this.id, this.label);
}

const List<LevelChoice> levelChoices = [
  LevelChoice('A1', 'A1'),
  LevelChoice('A2', 'A2'),
  LevelChoice('B1', 'B1'),
  LevelChoice('B2', 'B2'),
  LevelChoice('', 'Не знаю'),
];

const String fallbackLevel = 'A2';

const List<Interest> interests = [
  Interest('games', 'Игры'),
  Interest('travel', 'Путешествия'),
  Interest('films', 'Кино и сериалы'),
  Interest('music', 'Музыка'),
  Interest('tech', 'Технологии'),
  Interest('sport', 'Спорт'),
  Interest('food', 'Еда'),
  Interest('work', 'Работа'),
];

const int maxInterests = 3;

const Map<String, List<StarterWord>> _byLevel = {
  'A1': [
    StarterWord('house', 'дом'),
    StarterWord('water', 'вода'),
    StarterWord('friend', 'друг'),
    StarterWord('happy', 'счастливый'),
    StarterWord('big', 'большой'),
    StarterWord('small', 'маленький'),
    StarterWord('eat', 'есть'),
    StarterWord('drink', 'пить'),
    StarterWord('school', 'школа'),
    StarterWord('family', 'семья'),
    StarterWord('morning', 'утро'),
    StarterWord('read', 'читать'),
  ],
  'A2': [
    StarterWord('borrow', 'брать взаймы'),
    StarterWord('return', 'возвращать'),
    StarterWord('weather', 'погода'),
    StarterWord('holiday', 'отпуск'),
    StarterWord('usually', 'обычно'),
    StarterWord('surprise', 'сюрприз'),
    StarterWord('decide', 'решать'),
    StarterWord('invite', 'приглашать'),
    StarterWord('almost', 'почти'),
    StarterWord('mistake', 'ошибка'),
    StarterWord('expensive', 'дорогой'),
    StarterWord('neighbour', 'сосед'),
  ],
  'B1': [
    StarterWord('achieve', 'достигать'),
    StarterWord('improve', 'улучшать'),
    StarterWord('experience', 'опыт'),
    StarterWord('opportunity', 'возможность'),
    StarterWord('suggest', 'предлагать'),
    StarterWord('reliable', 'надёжный'),
    StarterWord('manage', 'справляться'),
    StarterWord('increase', 'увеличивать'),
    StarterWord('nevertheless', 'тем не менее'),
    StarterWord('purpose', 'цель'),
    StarterWord('afford', 'позволить себе'),
    StarterWord('recommend', 'рекомендовать'),
  ],
  'B2': [
    StarterWord('reluctant', 'неохотный'),
    StarterWord('acknowledge', 'признавать'),
    StarterWord('considerable', 'значительный'),
    StarterWord('compromise', 'компромисс'),
    StarterWord('overcome', 'преодолевать'),
    StarterWord('outcome', 'результат'),
    StarterWord('assume', 'предполагать'),
    StarterWord('whereas', 'тогда как'),
    StarterWord('thoroughly', 'тщательно'),
    StarterWord('obvious', 'очевидный'),
    StarterWord('deadline', 'крайний срок'),
    StarterWord('struggle', 'бороться'),
  ],
};

const Map<String, List<StarterWord>> _byInterest = {
  'games': [
    StarterWord('level up', 'повысить уровень'),
    StarterWord('opponent', 'соперник'),
    StarterWord('quest', 'задание'),
    StarterWord('achievement', 'достижение'),
  ],
  'travel': [
    StarterWord('luggage', 'багаж'),
    StarterWord('departure', 'вылет'),
    StarterWord('sightseeing', 'осмотр достопримечательностей'),
    StarterWord('passport', 'паспорт'),
  ],
  'films': [
    StarterWord('plot', 'сюжет'),
    StarterWord('cast', 'актёрский состав'),
    StarterWord('subtitles', 'субтитры'),
    StarterWord('sequel', 'продолжение'),
  ],
  'music': [
    StarterWord('lyrics', 'текст песни'),
    StarterWord('concert', 'концерт'),
    StarterWord('playlist', 'плейлист'),
    StarterWord('catchy', 'запоминающийся'),
  ],
  'tech': [
    StarterWord('device', 'устройство'),
    StarterWord('update', 'обновление'),
    StarterWord('password', 'пароль'),
    StarterWord('download', 'скачивать'),
  ],
  'sport': [
    StarterWord('match', 'матч'),
    StarterWord('training', 'тренировка'),
    StarterWord('injury', 'травма'),
    StarterWord('champion', 'чемпион'),
  ],
  'food': [
    StarterWord('recipe', 'рецепт'),
    StarterWord('ingredient', 'ингредиент'),
    StarterWord('delicious', 'вкусный'),
    StarterWord('bill', 'счёт'),
  ],
  'work': [
    StarterWord('meeting', 'встреча'),
    StarterWord('colleague', 'коллега'),
    StarterWord('salary', 'зарплата'),
    StarterWord('schedule', 'расписание'),
  ],
};

/// A level id that is safe to use for lookups: "не знаю" and unknown values
/// fall back to [fallbackLevel].
String effectiveLevel(String level) => _byLevel.containsKey(level) ? level : fallbackLevel;

/// The offline word set: the level's words first, then a few per chosen
/// interest, without repeats.
List<StarterWord> starterWords({required String level, required List<String> interestIds}) {
  final result = <StarterWord>[..._byLevel[effectiveLevel(level)]!];
  final seen = result.map((w) => w.term).toSet();
  for (final id in interestIds.take(maxInterests)) {
    for (final word in _byInterest[id] ?? const <StarterWord>[]) {
      if (seen.add(word.term)) result.add(word);
    }
  }
  return result;
}
