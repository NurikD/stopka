import 'package:stopka/core/llm/ai_availability.dart';

/// AI availability fixed for a test: either "the server is reachable" or not.
class FixedAiAvailability implements AiAvailability {
  final bool available;

  FixedAiAvailability(this.available);

  @override
  AiMode get mode => AiMode.server;

  @override
  Future<bool> isAvailable() async => available;
}
