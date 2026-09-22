class ParsedWord {
  final String term;
  final String translation;

  const ParsedWord({required this.term, this.translation = ''});
}

/// Parses a pasted word list. The whole paste is either newline-separated
/// or comma-separated (not mixed); each entry may be a bare word or
/// `word - перевод` / `word — перевод`.
class WordPasteParser {
  static final _separatorPattern = RegExp(r'\s+[-—]\s+');

  static List<ParsedWord> parse(String input) {
    final hasNewline = input.contains('\n');
    final rawEntries = hasNewline ? input.split('\n') : input.split(',');

    final result = <ParsedWord>[];
    for (final raw in rawEntries) {
      final entry = raw.trim();
      if (entry.isEmpty) continue;

      final parts = entry.split(_separatorPattern);
      final term = parts.first.trim();
      if (term.isEmpty) continue;
      final translation = parts.length > 1 ? parts.sublist(1).join(' - ').trim() : '';

      result.add(ParsedWord(term: term, translation: translation));
    }
    return result;
  }
}
