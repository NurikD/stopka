import 'pack_content.dart';

final RegExp _apostrophes = RegExp('[’‘`´ʼ]');
final RegExp _edgePunctuation = RegExp(r'^[\s.,;:!?"]+|[\s.,;:!?"]+$');

/// Contractions and their full forms are the same answer: "didn't hear" and
/// "did not hear". Only unambiguous ones ('s and 'd can be several things).
String _expandContractions(String s) {
  return s
      .replaceAll("won't", 'will not')
      .replaceAll("can't", 'can not')
      .replaceAll("cannot", 'can not')
      .replaceAll("shan't", 'shall not')
      .replaceAll("n't", ' not')
      .replaceAll("'m", ' am')
      .replaceAll("'re", ' are')
      .replaceAll("'ve", ' have')
      .replaceAll("'ll", ' will');
}

String _normalize(String s) {
  final folded = s.toLowerCase().replaceAll(_apostrophes, "'").replaceAll(_edgePunctuation, '');
  return _expandContractions(folded).replaceAll(RegExp(r'\s+'), ' ').trim();
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
