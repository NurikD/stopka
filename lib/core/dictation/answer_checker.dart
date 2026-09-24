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
    return rawVariantsOf(storedAnswer).map(normalize).where((s) => s.isNotEmpty).toList();
  }

  /// The same split as [variantsOf] but with the original spelling kept, for
  /// showing an answer to the user rather than comparing.
  static List<String> rawVariantsOf(String storedAnswer) {
    final result = <String>[];
    for (final chunk in storedAnswer.split(RegExp(r'[/;]'))) {
      final trimmed = chunk.trim();
      if (trimmed.isEmpty) continue;

      final commaParts = trimmed.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      final isSynonymList = commaParts.length > 1 && commaParts.every((p) => _wordCount(p) <= 2);

      if (isSynonymList) {
        result.addAll(commaParts);
      } else {
        result.add(trimmed);
      }
    }
    return result;
  }

  /// Of the stored variants, the one (in its original spelling) closest to
  /// what the user typed — so a review compares against the variant they
  /// were actually aiming for, not blindly the first.
  static String closestVariant({required String userInput, required String storedAnswer}) {
    final variants = rawVariantsOf(storedAnswer);
    if (variants.isEmpty) return storedAnswer.trim();
    if (variants.length == 1) return variants.first;

    final input = normalize(userInput);
    var best = variants.first;
    var bestDistance = _editDistance(input, normalize(best), countSwapAsOneEdit: false);
    for (final variant in variants.skip(1)) {
      final distance = _editDistance(input, normalize(variant), countSwapAsOneEdit: false);
      if (distance < bestDistance) {
        best = variant;
        bestDistance = distance;
      }
    }
    return best;
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
      if (maxDistance == 0) continue;
      final distance = _editDistance(
        normalizedInput,
        variant,
        countSwapAsOneEdit: variant.length >= _swapFriendlyLength,
      );
      if (distance <= maxDistance) return DictationVerdict.typo;
    }

    return DictationVerdict.wrong;
  }

  /// From this length on, swapping two neighbouring letters (recieve ->
  /// receive) is one slip of the fingers. Below it, a swap is more likely a
  /// different word (quite/quiet, angel/angle, trail/trial), so it stays a
  /// plain two-edit difference and falls outside the typo threshold.
  /// A heuristic: no edit distance can tell such pairs apart in general.
  static const _swapFriendlyLength = 6;

  /// Word-trap pairs like quite/quiet (distance 2) or desert/dessert
  /// (distance 1) are genuinely different words, not typos — so the
  /// tolerance scales with length instead of using one flat distance.
  /// Under 5 letters: no forgiveness, only an exact match counts.
  static int _typoMaxDistanceFor(int length) {
    if (length < 5) return 0;
    if (length <= 7) return 1;
    return 2;
  }

  /// Edit distance between [a] and [b]. With [countSwapAsOneEdit] a swap of
  /// two adjacent letters costs 1 instead of 2 (optimal string alignment).
  static int _editDistance(String a, String b, {required bool countSwapAsOneEdit}) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final d = List.generate(a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
    for (var i = 0; i <= a.length; i++) {
      d[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      d[0][j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        var best = [d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost].reduce((x, y) => x < y ? x : y);
        if (countSwapAsOneEdit && i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]) {
          final swap = d[i - 2][j - 2] + 1;
          if (swap < best) best = swap;
        }
        d[i][j] = best;
      }
    }
    return d[a.length][b.length];
  }
}
