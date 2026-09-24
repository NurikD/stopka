import 'pack_content.dart';

final RegExp _apostrophes = RegExp('[’‘`´ʼ]');
final RegExp _edgePunctuation = RegExp(r'^[\s.,;:!?"]+|[\s.,;:!?"]+$');

String _normalize(String s) {
  return s
      .toLowerCase()
      .replaceAll(_apostrophes, "'")
      .replaceAll(_edgePunctuation, '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

/// Whether [input] is the right answer to [exercise]. Unlike dictation this
/// has no typo tolerance: in a grammar exercise `have` and `has` are one
/// letter apart and that difference is the whole point. Case, spaces and
/// punctuation at the edges do not count; `/` separates alternative answers.
bool exerciseAnswerMatches(Exercise exercise, String input) {
  final given = _normalize(input);
  if (given.isEmpty) return false;
  return exercise.answer.split('/').any((variant) => _normalize(variant) == given);
}
