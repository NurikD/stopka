enum DictationVerdict { correct, typo, wrong, skipped }

/// Local, offline answer checking for the dictation mode — no AI call, so
/// it has to feel instant. See PLAN.md "Ключевой режим: диктант".
class AnswerChecker {
  static const _typoMinLength = 5;
  static const _typoMaxDistance = 2;

  static final _apostrophes = RegExp('[’‘`´ʼ]');
  static final _hyphens = RegExp('[–—−]');

  /// Trims, lowercases, collapses whitespace, folds every apostrophe/hyphen
  /// look-alike and ё onto one canonical form, and strips a leading verb
  /// infinitive marker ("to ") or article ("a "/"the ") — all so a mobile
  /// keyboard's typographic quotes or a missed ё don't cause a false
  /// mismatch.
  static String normalize(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll(_apostrophes, "'");
    s = s.replaceAll(_hyphens, '-');
    s = s.replaceAll('ё', 'е');
    if (s.startsWith('to ')) {
      s = s.substring(3);
    } else if (s.startsWith('the ')) {
      s = s.substring(4);
    } else if (s.startsWith('a ')) {
      s = s.substring(2);
    }
    return s.trim();
  }

  /// A stored answer field may hold several acceptable variants separated
  /// by "/", ",", or ";" (e.g. "достигать / добиваться").
  static List<String> variantsOf(String storedAnswer) {
    return storedAnswer
        .split(RegExp(r'[/,;]'))
        .map(normalize)
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// [userInput] must be non-empty — an explicit skip is a UI-level action,
  /// not something this checks for.
  static DictationVerdict check({required String userInput, required String correctAnswer}) {
    final normalizedInput = normalize(userInput);
    final variants = variantsOf(correctAnswer);

    if (variants.contains(normalizedInput)) return DictationVerdict.correct;

    for (final variant in variants) {
      if (variant.length >= _typoMinLength &&
          _levenshtein(normalizedInput, variant) <= _typoMaxDistance) {
        return DictationVerdict.typo;
      }
    }

    return DictationVerdict.wrong;
  }

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var previousRow = List<int>.generate(b.length + 1, (i) => i);
    var currentRow = List<int>.filled(b.length + 1, 0);

    for (var i = 0; i < a.length; i++) {
      currentRow[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        currentRow[j + 1] = [
          currentRow[j] + 1,
          previousRow[j + 1] + 1,
          previousRow[j] + cost,
        ].reduce((v, e) => v < e ? v : e);
      }
      final tmp = previousRow;
      previousRow = currentRow;
      currentRow = tmp;
    }

    return previousRow[b.length];
  }
}
