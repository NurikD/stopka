import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/llm/ai_availability.dart';
import 'package:stopka/core/llm/llm_client.dart';
import 'package:stopka/core/llm/server_llm_client.dart';

void main() {
  test('the limit message says when the allowance comes back', () {
    final now = DateTime(2026, 9, 25, 20, 0);
    final reset = DateTime(2026, 9, 26, 0, 0).toUtc();
    final message = limitMessage(reset, now);
    expect(message, contains('4 ч 0 мин'));
    expect(message, contains('исчерпан'));
  });

  test('a reset within the minute is shown as one minute, never zero or negative', () {
    final now = DateTime(2026, 9, 25, 23, 59, 40);
    expect(limitMessage(DateTime(2026, 9, 26).toUtc(), now), contains('1 мин'));
  });

  test('every server reason has its own plain Russian message', () {
    expect(unavailableMessage('overloaded', 1), contains('перегружен'));
    expect(unavailableMessage('budget', 90), contains('2 ч'));
    expect(unavailableMessage('budget', null), contains('завтра'));
    expect(unavailableMessage('disabled', null), contains('отключён'));
    expect(unavailableMessage('provider_limit', 1), contains('подождать'));
    expect(unavailableMessage('anything else', null), contains('не смог ответить'));
  });

  test('the AI mode: the developer flag wins, then the server, otherwise none', () {
    expect(chooseAiMode(directGemini: true, serverConfigured: true), AiMode.direct);
    expect(chooseAiMode(directGemini: false, serverConfigured: true), AiMode.server);
    expect(chooseAiMode(directGemini: false, serverConfigured: false), AiMode.none);
  });

  test('the level sent to the server is A1-B2 or empty', () {
    expect(aiLevel('b1'), 'B1');
    expect(aiLevel(' A2 '), 'A2');
    expect(aiLevel('Pre-Intermediate'), '');
    expect(aiLevel(''), '');
  });
}
