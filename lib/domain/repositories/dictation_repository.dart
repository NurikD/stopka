import '../models/dictation_answer.dart';
import '../models/dictation_session.dart';

abstract class DictationRepository {
  Stream<List<DictationSession>> watchSessions(String setId);

  Future<DictationSession> startSession({required String setId, required DictationDirection direction});

  Future<void> finishSession(String sessionId, {required int roundsCount, required int totalWords});

  Future<DictationAnswer> recordAnswer({
    required String sessionId,
    required String cardId,
    required int roundIndex,
    required String userInput,
    required DictationAnswerVerdict verdict,
    DictationCheckedBy checkedBy = DictationCheckedBy.local,
  });

  /// Overwrites a previously recorded answer's verdict — used when the AI
  /// appeal ("я считаю, мой вариант тоже верный") agrees with the user.
  Future<void> updateAnswerVerdict(String answerId, DictationAnswerVerdict verdict, DictationCheckedBy checkedBy);

  Future<List<DictationAnswer>> getAnswers(String sessionId);
}
