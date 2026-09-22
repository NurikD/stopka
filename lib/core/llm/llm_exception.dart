/// All user-facing messages are in Russian per the app's UI language rule.
class LlmException implements Exception {
  final String messageRu;
  final bool isRateLimited;

  const LlmException(this.messageRu, {this.isRateLimited = false});

  @override
  String toString() => messageRu;
}
