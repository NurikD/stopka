enum DictationVerdict { correct, typo, wrong, skipped }

/// Local, offline answer checking for the dictation mode — no AI call, so
/// it has to feel instant. See PLAN.md "Ключевой режим: диктант".
class AnswerChecker {
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
  /// by "/", ",", or ";" (e.g. "достигать / добиваться"). "/" and ";"
  /// always separate variants, but "," is ambiguous — textbook phrases use
  /// commas too ("несмотря на то, что"), so a comma only splits when every
  /// resulting piece is at most two words; otherwise it's kept as one
  /// phrase.
  static List<String> variantsOf(String storedAnswer) {
    final result = <String>[];
    for (final chunk in storedAnswer.split(RegExp(r'[/;]'))) {
      final trimmed = chunk.trim();
      if (trimmed.isEmpty) continue;

      final commaParts = trimmed.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      final isSynonymList = commaParts.length > 1 && commaParts.every((p) => _wordCount(p) <= 2);

      if (isSynonymList) {
        result.addAll(commaParts.map(normalize));
      } else {
        result.add(normalize(trimmed));
      }
    }
    return result.where((s) => s.isNotEmpty).toList();
  }

  static int _wordCount(String s) => s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  /// [userInput] must be non-empty — an explicit skip is a UI-level action,
  /// not something this checks for.
  static DictationVerdict check({required String userInput, required String correctAnswer}) {
    final normalizedInput = normalize(userInput);
    final variants = variantsOf(correctAnswer);

    if (variants.contains(normalizedInput)) return DictationVerdict.correct;

    for (final variant in variants) {
      final maxDistance = _typoMaxDistanceFor(variant.length);
      if (maxDistance > 0 && _levenshtein(normalizedInput, variant) <= maxDistance) {
        return DictationVerdict.typo;
      }
    }

    return DictationVerdict.wrong;
  }

  /// Word-trap pairs like quite/quiet (distance 2) or desert/dessert
  /// (distance 1) are genuinely different words, not typos — so the
  /// tolerance scales with length instead of using one flat distance.
  /// Under 5 letters: no forgiveness, only an exact match counts.
  static int _typoMaxDistanceFor(int length) {
    if (length < 5) return 0;
    if (length <= 7) return 1;
    return 2;
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
