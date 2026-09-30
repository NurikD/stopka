import 'answer_checker.dart';

/// Checking and diffing answers that are whole sentences. A sentence is not a
/// long word: case, punctuation and contractions do not matter, a typo is
/// forgiven per word, and a missing, extra or swapped word is a mistake.
class SentenceAnswer {
  static final _sentenceEnd = RegExp(r'[.!?…]\s*$');
  static final _notWordChar = RegExp(r"[^\p{L}\p{N}' ]", unicode: true);

  /// A stored answer is checked as a sentence when it reads like one: it
  /// ends like a sentence, or is too long to be a dictionary phrase.
  static bool isSentence(String rawAnswer) {
    final text = rawAnswer.trim();
    return _sentenceEnd.hasMatch(text) || _words(text).length >= 5;
  }

  static List<String> _words(String text) => text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  /// Subjects whose `'s` / `'d` is a verb ("he's" = he is / he has). After a
  /// noun `'s` is possessive and the word stays as it is.
  static const _subjects = {
    'i', 'you', 'he', 'she', 'it', 'we', 'they', 'that', 'there', 'here', 'what', 'who', 'where', 'when', 'how',
  };

  static const _irregularNot = {'won\'t': 'will', 'can\'t': 'can', 'shan\'t': 'shall'};

  /// "~s" stands for is/has, "~d" for would/had: both readings are right.
  static const _ambiguous = {
    '~s': {'is', 'has'},
    '~d': {'would', 'had'},
  };

  /// Comparison units of a text: lower case, no punctuation, contractions
  /// spelled out.
  static List<String> tokens(String text) {
    final folded = AnswerChecker.foldTypography(text.toLowerCase()).replaceAll('-', ' ').replaceAll(_notWordChar, ' ');
    final result = <String>[];
    for (var word in _words(folded)) {
      word = word.replaceAll(RegExp(r"^'+|'+$"), '');
      if (word.isEmpty) continue;
      result.addAll(_expand(word));
    }
    return result;
  }

  static List<String> _expand(String word) {
    if (word == 'cannot') return const ['can', 'not'];
    if (word == 'let\'s') return const ['let', 'us'];
    final irregular = _irregularNot[word];
    if (irregular != null) return [irregular, 'not'];
    if (word.endsWith('n\'t') && word.length > 3) return [word.substring(0, word.length - 3), 'not'];

    final apostrophe = word.lastIndexOf('\'');
    if (apostrophe <= 0) return [word];
    final stem = word.substring(0, apostrophe);
    switch (word.substring(apostrophe + 1)) {
      case 'm':
        return [stem, 'am'];
      case 're':
        return [stem, 'are'];
      case 've':
        return [stem, 'have'];
      case 'll':
        return [stem, 'will'];
      case 's' when _subjects.contains(stem):
        return [stem, '~s'];
      case 'd' when _subjects.contains(stem):
        return [stem, '~d'];
      default:
        return [word];
    }
  }

  static bool _same(String a, String b) {
    if (a == b) return true;
    return (_ambiguous[a]?.contains(b) ?? false) || (_ambiguous[b]?.contains(a) ?? false);
  }

  /// The same words, with no typo tolerance: for grammar, where `have` and
  /// `has` are one letter apart and that letter is the whole point.
  static bool sameWords(String a, String b) {
    final x = tokens(a);
    final y = tokens(b);
    if (x.isEmpty || x.length != y.length) return false;
    for (var i = 0; i < x.length; i++) {
      if (!_same(x[i], y[i])) return false;
    }
    return true;
  }

  /// [answer] is one variant, as stored.
  static DictationVerdict check({required String userInput, required String answer}) {
    final given = tokens(userInput);
    final expected = tokens(answer);
    if (given.length != expected.length) return DictationVerdict.wrong;

    var typos = 0;
    for (var i = 0; i < expected.length; i++) {
      if (_same(given[i], expected[i])) continue;
      if (!AnswerChecker.isTypo(input: given[i], expected: expected[i])) return DictationVerdict.wrong;
      typos++;
    }
    if (typos == 0) return DictationVerdict.correct;
    // One slip per four words; more than that is not knowing the sentence.
    final allowed = expected.length < 8 ? 1 : expected.length ~/ 4;
    return typos <= allowed ? DictationVerdict.typo : DictationVerdict.wrong;
  }

  /// Which words of [user] and of [correct] (split on spaces, as typed) are
  /// part of their longest common run — the rest is what the diff marks.
  static ({List<(String, bool)> user, List<(String, bool)> correct}) diff({
    required String user,
    required String correct,
  }) {
    final u = _words(user);
    final c = _words(correct);
    String key(String w) => tokens(w).join(' ');
    final uk = u.map(key).toList();
    final ck = c.map(key).toList();

    // Longest common subsequence over the words.
    final lcs = List.generate(u.length + 1, (_) => List<int>.filled(c.length + 1, 0));
    for (var i = u.length - 1; i >= 0; i--) {
      for (var j = c.length - 1; j >= 0; j--) {
        lcs[i][j] = uk[i] == ck[j] ? lcs[i + 1][j + 1] + 1 : (lcs[i + 1][j] > lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1]);
      }
    }
    final uMatch = List<bool>.filled(u.length, false);
    final cMatch = List<bool>.filled(c.length, false);
    var i = 0, j = 0;
    while (i < u.length && j < c.length) {
      if (uk[i] == ck[j]) {
        uMatch[i++] = true;
        cMatch[j++] = true;
      } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
        i++;
      } else {
        j++;
      }
    }
    return (
      user: [for (var k = 0; k < u.length; k++) (u[k], uMatch[k])],
      correct: [for (var k = 0; k < c.length; k++) (c[k], cMatch[k])],
    );
  }
}
