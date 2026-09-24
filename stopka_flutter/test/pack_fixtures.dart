import 'dart:convert';

/// Valid part JSON for tests, sized to pass the level rules.
Map<String, dynamic> question([int answer = 1]) => {
      'prompt': 'What does the writer like?',
      'options': ['Cats', 'Games', 'Rain'],
      'answerIndex': answer,
      'why': 'Об этом сказано в начале текста.',
    };

String _sentences(int count) =>
    List.generate(count, (i) => 'I have played this game for ${i + 2} years.').join(' ');

Map<String, dynamic> readingJson({int sentences = 18, List<String>? phrases}) => {
      'title': 'My game',
      'text': _sentences(sentences),
      'targetPhrases': phrases ?? ['have played'],
      'glossary': [
        {'word': 'game', 'translation': 'игра'},
        {'word': 'years', 'translation': 'годы'},
      ],
      'questions': List.generate(5, (_) => question()),
    };

Map<String, dynamic> listeningJson() => {
      'title': 'Weekend plans',
      'lines': [
        for (var i = 0; i < 12; i++)
          {
            'speaker': i.isEven ? 'Anna' : 'Tom',
            'text': 'I want to play a game with you on Saturday, and then we can eat.',
          },
      ],
      'questions': List.generate(3, (_) => question()),
    };

Map<String, dynamic> grammarJson() => {
      'title': 'Present perfect',
      'explanation': 'Мы используем это время, когда говорим о том, что уже случилось и важно сейчас. '
          'Форма: have или has плюс третья форма глагола.',
      'examples': ['I have seen it.', 'She has played it.', 'We have finished.'],
      'exercises': [
        {'kind': 'gap', 'prompt': 'She ___ never played this.', 'answer': 'has', 'why': 'She: has.'},
        {
          'kind': 'choice',
          'prompt': 'I ___ this film twice.',
          'options': ['see', 'have seen', 'saw'],
          'answer': 'have seen',
          'why': 'Опыт до сейчас.',
        },
        {'kind': 'translate', 'prompt': 'Я уже поел.', 'answer': 'I have already eaten.', 'why': 'Результат важен.'},
        {'kind': 'gap', 'prompt': 'They ___ finished.', 'answer': 'have', 'why': 'They: have.'},
        {'kind': 'gap', 'prompt': 'He ___ arrived.', 'answer': 'has', 'why': 'He: has.'},
        {'kind': 'gap', 'prompt': 'We ___ eaten.', 'answer': 'have', 'why': 'We: have.'},
      ],
    };

Map<String, dynamic> writingJson() => {
      'task': 'Write 4-6 sentences about a game you have played. Use the present perfect.',
      'hints': ['I have played ... for ...', 'My favourite level is ...'],
    };

String asRaw(Map<String, dynamic> json) => jsonEncode(json);
