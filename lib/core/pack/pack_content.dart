import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Bumped when the JSON shape of any part changes; it is part of the cache
/// key, so old packs are simply not found instead of being misread.
const int packSchemaVersion = 1;

enum PackPart { reading, listening, grammar, writing }

enum PartStatus { pending, ready, failed, flagged }

/// A part came back from the model in a shape (or at a level) we refuse to
/// show. Never reaches the user as-is: the generator retries once and then
/// reports a plain Russian error.
class PackFormatException implements Exception {
  final String reason;

  const PackFormatException(this.reason);

  @override
  String toString() => 'PackFormatException: $reason';
}

/// The cache key of a pack: the same level, topics and interest always map
/// to the same hash, whoever asks.
class PackKey {
  final String level;
  final String grammarTopic;
  final String vocabTopic;
  final String interest;
  final int schemaVersion;

  const PackKey({
    required this.level,
    this.grammarTopic = '',
    this.vocabTopic = '',
    this.interest = '',
    this.schemaVersion = packSchemaVersion,
  });

  static String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String get hash {
    final joined = [level, grammarTopic, vocabTopic, interest, '$schemaVersion'].map(_norm).join('|');
    return sha256.convert(utf8.encode(joined)).toString();
  }
}

class Question {
  final String prompt;
  final List<String> options;
  final int answerIndex;
  final String why;

  const Question({required this.prompt, required this.options, required this.answerIndex, this.why = ''});

  factory Question.fromJson(Object? raw) {
    if (raw is! Map) throw const PackFormatException('question is not an object');
    final prompt = _string(raw['prompt']);
    final options = _stringList(raw['options']);
    final answer = raw['answerIndex'];
    if (prompt.isEmpty) throw const PackFormatException('question without a prompt');
    if (options.length < 2 || options.length > 4) throw const PackFormatException('question needs 2-4 options');
    if (answer is! int || answer < 0 || answer >= options.length) {
      throw const PackFormatException('answerIndex out of range');
    }
    if (options.toSet().length != options.length) throw const PackFormatException('duplicate options');
    return Question(prompt: prompt, options: options, answerIndex: answer, why: _string(raw['why']));
  }

  Map<String, dynamic> toJson() => {'prompt': prompt, 'options': options, 'answerIndex': answerIndex, 'why': why};
}

/// Sentence-length ceiling per CEFR level: average words per sentence.
const Map<String, double> _maxAvgSentence = {'A1': 9, 'A2': 12, 'B1': 16, 'B2': 20};

double _sentenceCeiling(String level) => _maxAvgSentence[level] ?? _maxAvgSentence['B1']!;

final RegExp _wordPattern = RegExp("[A-Za-z]+(?:['’-][A-Za-z]+)*");

int countWords(String text) => _wordPattern.allMatches(text).length;

double averageSentenceLength(String text) {
  final sentences = text.split(RegExp(r'[.!?]+')).where((s) => countWords(s) > 0).toList();
  if (sentences.isEmpty) return 0;
  return countWords(text) / sentences.length;
}

class GlossaryEntry {
  final String word;
  final String translation;

  const GlossaryEntry(this.word, this.translation);
}

class ReadingContent {
  final String title;
  final String text;

  /// Substrings of [text] that show the target grammar.
  final List<String> targetPhrases;
  final List<GlossaryEntry> glossary;
  final List<Question> questions;

  const ReadingContent({
    required this.title,
    required this.text,
    required this.targetPhrases,
    required this.glossary,
    required this.questions,
  });

  factory ReadingContent.fromJson(Object? raw, {required String level}) {
    if (raw is! Map) throw const PackFormatException('reading is not an object');
    final title = _string(raw['title']);
    final text = _string(raw['text']);
    final words = countWords(text);
    if (title.isEmpty) throw const PackFormatException('reading without a title');
    if (words < 120 || words > 300) throw PackFormatException('reading has $words words');
    final avg = averageSentenceLength(text);
    if (avg > _sentenceCeiling(level)) {
      throw PackFormatException('sentences too long for $level: ${avg.toStringAsFixed(1)}');
    }

    final phrases = _stringList(raw['targetPhrases']).where(text.contains).toList();
    if (phrases.isEmpty) throw const PackFormatException('target grammar never occurs in the text');

    final glossary = <GlossaryEntry>[];
    final rawGlossary = raw['glossary'];
    if (rawGlossary is List) {
      for (final g in rawGlossary) {
        if (g is! Map) continue;
        final word = _string(g['word']);
        final translation = _string(g['translation']);
        if (word.isNotEmpty && translation.isNotEmpty) glossary.add(GlossaryEntry(word, translation));
      }
    }

    final questions = _questions(raw['questions'], min: 3, max: 7);
    return ReadingContent(title: title, text: text, targetPhrases: phrases, glossary: glossary, questions: questions);
  }

  /// Character ranges of [targetPhrases] in [text], non-overlapping, in order.
  List<({int start, int end})> get marks {
    final found = <({int start, int end})>[];
    for (final phrase in targetPhrases) {
      var from = 0;
      while (true) {
        final i = text.indexOf(phrase, from);
        if (i < 0) break;
        found.add((start: i, end: i + phrase.length));
        from = i + phrase.length;
      }
    }
    found.sort((a, b) => a.start.compareTo(b.start));
    final merged = <({int start, int end})>[];
    for (final m in found) {
      if (merged.isNotEmpty && m.start < merged.last.end) continue;
      merged.add(m);
    }
    return merged;
  }

  /// Translation of a tapped word from the text's own glossary, if there is one.
  String? translate(String word) {
    final key = word.toLowerCase();
    for (final g in glossary) {
      if (g.word.toLowerCase() == key) return g.translation;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'text': text,
        'targetPhrases': targetPhrases,
        'glossary': [
          for (final g in glossary) {'word': g.word, 'translation': g.translation},
        ],
        'questions': [for (final q in questions) q.toJson()],
      };
}

class DialogueLine {
  /// 0 or 1: which of at most two voices reads it.
  final int speaker;
  final String name;
  final String text;

  const DialogueLine({required this.speaker, required this.name, required this.text});
}

class ListeningContent {
  final String title;
  final List<DialogueLine> lines;
  final List<Question> questions;

  const ListeningContent({required this.title, required this.lines, required this.questions});

  factory ListeningContent.fromJson(Object? raw, {required String level}) {
    if (raw is! Map) throw const PackFormatException('listening is not an object');
    final title = _string(raw['title']);
    final rawLines = raw['lines'];
    if (title.isEmpty) throw const PackFormatException('listening without a title');
    if (rawLines is! List) throw const PackFormatException('listening without lines');

    final speakers = <String>[];
    final lines = <DialogueLine>[];
    for (final l in rawLines) {
      if (l is! Map) throw const PackFormatException('line is not an object');
      final text = _string(l['text']);
      if (text.isEmpty) throw const PackFormatException('empty line');
      final name = _string(l['speaker']);
      var index = speakers.indexOf(name);
      if (index < 0) {
        speakers.add(name);
        index = speakers.length - 1;
      }
      if (index > 1) throw const PackFormatException('more than two speakers');
      lines.add(DialogueLine(speaker: index, name: name, text: text));
    }
    if (lines.isEmpty) throw const PackFormatException('no lines');

    final full = lines.map((l) => l.text).join(' ');
    final words = countWords(full);
    if (words < 50 || words > 200) throw PackFormatException('listening has $words words');
    final avg = averageSentenceLength(full);
    if (avg > _sentenceCeiling(level)) throw PackFormatException('sentences too long for $level');

    return ListeningContent(title: title, lines: lines, questions: _questions(raw['questions'], min: 3, max: 5));
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'lines': [
          for (final l in lines) {'speaker': l.name, 'text': l.text},
        ],
        'questions': [for (final q in questions) q.toJson()],
      };
}

enum ExerciseKind { gap, choice, translate }

class Exercise {
  final ExerciseKind kind;
  final String prompt;
  final List<String> options;
  final String answer;
  final String why;

  const Exercise({
    required this.kind,
    required this.prompt,
    this.options = const [],
    required this.answer,
    this.why = '',
  });

  factory Exercise.fromJson(Object? raw) {
    if (raw is! Map) throw const PackFormatException('exercise is not an object');
    final kind = ExerciseKind.values.where((k) => k.name == raw['kind']).firstOrNull;
    final prompt = _string(raw['prompt']);
    final answer = _string(raw['answer']);
    final options = _stringList(raw['options']);
    if (kind == null) throw const PackFormatException('unknown exercise kind');
    if (prompt.isEmpty || answer.isEmpty) throw const PackFormatException('exercise without prompt or answer');
    if (kind == ExerciseKind.gap && !prompt.contains('___')) throw const PackFormatException('gap without ___');
    if (kind == ExerciseKind.choice && (options.length < 2 || !options.contains(answer))) {
      throw const PackFormatException('choice answer not among options');
    }
    return Exercise(
      kind: kind,
      prompt: prompt,
      options: kind == ExerciseKind.choice ? options : const [],
      answer: answer,
      why: _string(raw['why']),
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'prompt': prompt,
        'options': options,
        'answer': answer,
        'why': why,
      };
}

class GrammarContent {
  final String title;
  final String explanation;
  final List<String> examples;
  final List<Exercise> exercises;

  const GrammarContent({
    required this.title,
    required this.explanation,
    required this.examples,
    required this.exercises,
  });

  factory GrammarContent.fromJson(Object? raw) {
    if (raw is! Map) throw const PackFormatException('grammar is not an object');
    final title = _string(raw['title']);
    final explanation = _string(raw['explanation']);
    final examples = _stringList(raw['examples']);
    if (title.isEmpty) throw const PackFormatException('grammar without a title');
    if (explanation.length < 60 || explanation.length > 1600) throw const PackFormatException('explanation length');
    if (examples.length < 2) throw const PackFormatException('too few examples');
    final rawExercises = raw['exercises'];
    if (rawExercises is! List) throw const PackFormatException('no exercises');
    final exercises = rawExercises.map(Exercise.fromJson).toList();
    if (exercises.length < 4 || exercises.length > 10) throw PackFormatException('${exercises.length} exercises');
    return GrammarContent(title: title, explanation: explanation, examples: examples, exercises: exercises);
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'explanation': explanation,
        'examples': examples,
        'exercises': [for (final e in exercises) e.toJson()],
      };
}

class WritingContent {
  final String task;
  final List<String> hints;

  const WritingContent({required this.task, required this.hints});

  factory WritingContent.fromJson(Object? raw) {
    if (raw is! Map) throw const PackFormatException('writing is not an object');
    final task = _string(raw['task']);
    final hints = _stringList(raw['hints']);
    if (task.length < 20) throw const PackFormatException('writing task too short');
    if (hints.isEmpty || hints.length > 5) throw const PackFormatException('writing hints');
    return WritingContent(task: task, hints: hints);
  }

  Map<String, dynamic> toJson() => {'task': task, 'hints': hints};
}

List<Question> _questions(Object? raw, {required int min, required int max}) {
  if (raw is! List) throw const PackFormatException('no questions');
  final questions = raw.map(Question.fromJson).toList();
  if (questions.length < min || questions.length > max) throw PackFormatException('${questions.length} questions');
  return questions;
}

String _string(Object? v) => v is String ? v.trim() : '';

List<String> _stringList(Object? v) {
  if (v is! List) return const [];
  return [
    for (final e in v)
      if (e is String && e.trim().isNotEmpty) e.trim(),
  ];
}
