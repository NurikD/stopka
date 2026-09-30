import '../dictation/sentence_answer.dart';
import 'pack_content.dart';

/// Whether [input] is the right answer to [exercise]. Unlike dictation this
/// has no typo tolerance: in a grammar exercise `have` and `has` are one
/// letter apart and that difference is the whole point. Case, punctuation and
/// contractions do not count; `/` separates alternative answers.
bool exerciseAnswerMatches(Exercise exercise, String input) {
  return exercise.answer.split('/').any((variant) => SentenceAnswer.sameWords(input, variant));
}
