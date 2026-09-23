import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/llm/llm_client.dart';
import 'package:stopka/core/llm/llm_exception.dart';
import 'package:stopka/core/llm/llm_request_counter.dart';
import 'package:stopka/core/llm/throttled_llm_client.dart';

class _FakeLlmClient implements LlmClient {
  final List<DateTime> callTimestamps = [];
  bool shouldThrow = false;

  @override
  Future<String> complete({required String systemPrompt, required String userMessage}) async {
    callTimestamps.add(DateTime.now());
    if (shouldThrow) throw const LlmException('boom');
    return 'ok';
  }

  @override
  Future<String> completeWithImage({
    required String systemPrompt,
    required String userMessage,
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    callTimestamps.add(DateTime.now());
    return 'ok';
  }

  @override
  Future<bool> validateApiKey(String apiKey) async {
    callTimestamps.add(DateTime.now());
    return true;
  }
}

LlmRequestCounter _inMemoryCounter(Map<String, String> store) {
  return LlmRequestCounter(
    read: (key) async => store[key],
    write: (key, value) async => store[key] = value,
  );
}

void main() {
  test('a successful call increments the counter', () async {
    final store = <String, String>{};
    final counter = _inMemoryCounter(store);
    final client = ThrottledLlmClient(_FakeLlmClient(), counter, minInterval: Duration.zero);

    await client.complete(systemPrompt: 'sys', userMessage: 'hi');

    expect(await counter.getTodayCount(), 1);
  });

  test('a failed call does not increment the counter', () async {
    final store = <String, String>{};
    final counter = _inMemoryCounter(store);
    final inner = _FakeLlmClient()..shouldThrow = true;
    final client = ThrottledLlmClient(inner, counter, minInterval: Duration.zero);

    await expectLater(client.complete(systemPrompt: 'sys', userMessage: 'hi'), throwsA(isA<LlmException>()));

    expect(await counter.getTodayCount(), 0);
  });

  test('validateApiKey does not count toward the quota', () async {
    final store = <String, String>{};
    final counter = _inMemoryCounter(store);
    final client = ThrottledLlmClient(_FakeLlmClient(), counter, minInterval: Duration.zero);

    await client.validateApiKey('key');

    expect(await counter.getTodayCount(), 0);
  });

  test('two calls are spaced apart by at least minInterval', () async {
    final store = <String, String>{};
    final counter = _inMemoryCounter(store);
    final inner = _FakeLlmClient();
    final client = ThrottledLlmClient(inner, counter, minInterval: const Duration(milliseconds: 200));

    final first = client.complete(systemPrompt: 'sys', userMessage: 'a');
    final second = client.complete(systemPrompt: 'sys', userMessage: 'b');
    await Future.wait([first, second]);

    expect(inner.callTimestamps, hasLength(2));
    final gap = inner.callTimestamps[1].difference(inner.callTimestamps[0]);
    expect(gap.inMilliseconds, greaterThanOrEqualTo(190)); // small tolerance for scheduling jitter
  });

  test('calls never run concurrently — the second only starts after the first fully finishes', () async {
    final store = <String, String>{};
    final counter = _inMemoryCounter(store);

    var concurrentCalls = 0;
    var sawOverlap = false;

    Future<String> guardedComplete() async {
      concurrentCalls++;
      if (concurrentCalls > 1) sawOverlap = true;
      await Future.delayed(const Duration(milliseconds: 30));
      concurrentCalls--;
      return 'ok';
    }

    // Swap in a client whose action itself tracks overlap via a wrapper.
    final wrapped = ThrottledLlmClient(_OverlapTrackingClient(guardedComplete), counter, minInterval: const Duration(milliseconds: 10));
    await Future.wait([
      wrapped.complete(systemPrompt: 'a', userMessage: 'a'),
      wrapped.complete(systemPrompt: 'b', userMessage: 'b'),
      wrapped.complete(systemPrompt: 'c', userMessage: 'c'),
    ]);

    expect(sawOverlap, isFalse);
  });
}

class _OverlapTrackingClient implements LlmClient {
  final Future<String> Function() onComplete;
  _OverlapTrackingClient(this.onComplete);

  @override
  Future<String> complete({required String systemPrompt, required String userMessage}) => onComplete();

  @override
  Future<String> completeWithImage({
    required String systemPrompt,
    required String userMessage,
    required Uint8List imageBytes,
    required String mimeType,
  }) =>
      onComplete();

  @override
  Future<bool> validateApiKey(String apiKey) async => true;
}
