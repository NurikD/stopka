import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:stopka_server/src/ai/ai_provider.dart';
import 'package:stopka_server/src/ai/ai_service.dart';
import 'package:stopka_server/src/generated/protocol.dart';
import 'package:stopka_server/src/logic/server_settings.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

class _FakeProvider implements LlmProvider {
  final List<Object> replies; // String = answer, LlmProviderException = failure
  final List<String> userMessages = [];
  int calls = 0;

  _FakeProvider(this.replies);

  @override
  Future<String> complete({required String systemPrompt, required String userMessage}) async {
    userMessages.add(userMessage);
    final reply = replies[calls < replies.length ? calls : replies.length - 1];
    calls++;
    if (reply is LlmProviderException) throw reply;
    return reply as String;
  }

  @override
  Future<String> completeWithImage({
    required String systemPrompt,
    required String userMessage,
    required Uint8List imageBytes,
    required String mimeType,
  }) =>
      complete(systemPrompt: systemPrompt, userMessage: userMessage);
}

void main() {
  final deviceId = const Uuid().v4();

  tearDown(() {
    AiRuntime.overrideProvider(null);
    ServerSettings.testOverride = null;
  });

  withServerpod('Given the AI endpoint', (sessionBuilder, endpoints) {
    final signedIn = sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(deviceId, {}),
    );

    Future<int> usedToday(String kind) async {
      final rows = await AiUsage.db.find(sessionBuilder.build(), where: (t) => t.kind.equals(kind));
      return rows.fold<int>(0, (sum, r) => sum + r.requests);
    }

    test('an answer comes back and is counted once for this device', () async {
      AiRuntime.overrideProvider(_FakeProvider(['{"accepted":true}']));

      final result = await endpoints.ai.appeal(signedIn, 'go', 'идти', 'пойти', 'EN -> RU', false);

      expect(result, '{"accepted":true}');
      expect(await usedToday('appeal'), 1);
    });

    test('a call without a device token is refused before anything is spent', () async {
      AiRuntime.overrideProvider(_FakeProvider(['x']));
      await expectLater(
        endpoints.ai.appeal(sessionBuilder, 'go', 'идти', 'пойти', 'EN -> RU', false),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
      expect(await usedToday('appeal'), 0);
    });

    test('past the device limit the answer is LimitExceeded with the reset time', () async {
      ServerSettings.testOverride = const ServerSettings(
        ai: AiSettings(dailyLimits: {'appeal': 2}),
      );
      final provider = _FakeProvider(['ok']);
      AiRuntime.overrideProvider(provider);

      await endpoints.ai.appeal(signedIn, 'a', 'b', 'c', 'EN -> RU', false);
      await endpoints.ai.appeal(signedIn, 'a', 'b', 'c', 'EN -> RU', false);
      await expectLater(
        endpoints.ai.appeal(signedIn, 'a', 'b', 'c', 'EN -> RU', false),
        throwsA(isA<LimitExceeded>()
            .having((e) => e.limit, 'limit', 2)
            .having((e) => e.resetAt.isAfter(DateTime.now().toUtc()), 'reset is in the future', isTrue)),
      );
      expect(provider.calls, 2, reason: 'the refused call never reached the provider');
    });

    test('the global budget stops everyone, whatever the device limit', () async {
      ServerSettings.testOverride = const ServerSettings(
        ai: AiSettings(globalDailyRequests: 1, dailyLimits: {'appeal': 50}),
      );
      final provider = _FakeProvider(['ok']);
      AiRuntime.overrideProvider(provider);

      await endpoints.ai.appeal(signedIn, 'a', 'b', 'c', 'EN -> RU', false);
      await expectLater(
        endpoints.ai.appeal(signedIn, 'a', 'b', 'c', 'EN -> RU', false),
        throwsA(isA<AiUnavailable>().having((e) => e.reason, 'reason', 'budget')),
      );
      expect(provider.calls, 1);
    });

    test('the master switch turns the proxy off', () async {
      ServerSettings.testOverride = const ServerSettings(ai: AiSettings(enabled: false));
      final provider = _FakeProvider(['ok']);
      AiRuntime.overrideProvider(provider);

      await expectLater(
        endpoints.ai.appeal(signedIn, 'a', 'b', 'c', 'EN -> RU', false),
        throwsA(isA<AiUnavailable>().having((e) => e.reason, 'reason', 'disabled')),
      );
      expect(provider.calls, 0);
    });

    test('a provider failure is not charged to the device and is reported as a typed error', () async {
      AiRuntime.overrideProvider(
        _FakeProvider([const LlmProviderException(ProviderFailure.overloaded, statusCode: 503)]),
      );

      await expectLater(
        endpoints.ai.appeal(signedIn, 'a', 'b', 'c', 'EN -> RU', false),
        throwsA(isA<AiUnavailable>()
            .having((e) => e.reason, 'reason', 'overloaded')
            .having((e) => e.retryAfterMinutes, 'retryAfterMinutes', 1)),
      );
      expect(await usedToday('appeal'), 0, reason: 'the failed call was refunded');
    });

    test('bad input is refused before the provider is asked', () async {
      final provider = _FakeProvider(['ok']);
      AiRuntime.overrideProvider(provider);

      await expectLater(
        endpoints.ai.checkWriting(signedIn, 'C2', 'task', 'text', false),
        throwsA(isA<InvalidAiRequest>()),
      );
      await expectLater(
        endpoints.ai.checkWriting(signedIn, 'A2', 'task', 'x' * 100000, false),
        throwsA(isA<InvalidAiRequest>()),
      );
      await expectLater(
        endpoints.ai.recognizeWords(signedIn, ByteData(0), 'image/png', false),
        throwsA(isA<InvalidAiRequest>()),
      );
      expect(provider.calls, 0);
      expect(await usedToday('checkWriting'), 0);
    });

    test('a photo request reaches the provider with the strict reminder when asked', () async {
      final provider = _FakeProvider(['{"words":[]}']);
      AiRuntime.overrideProvider(provider);

      await endpoints.ai.recognizeWords(
        signedIn,
        ByteData.sublistView(Uint8List.fromList([1, 2, 3])),
        'image/jpeg',
        true,
      );

      expect(provider.userMessages.single, contains('строго в формате JSON'));
      expect(await usedToday('recognizeWords'), 1);
    });
  });
}
