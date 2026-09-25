import 'dart:async';
import 'dart:typed_data';

import 'llm_client.dart';
import 'llm_request_counter.dart';

/// Wraps any [LlmClient] to serialize its calls (never two in flight at
/// once) with a minimum spacing between them, and counts successful
/// requests via [LlmRequestCounter] — a decorator so GeminiLlmClient stays
/// untouched and any future provider gets this for free.
class ThrottledLlmClient implements LlmClient {
  final LlmClient _inner;
  final LlmRequestCounter _counter;
  final Duration _minInterval;

  Future<void> _queue = Future.value();

  // Not an initializing formal (`this._minInterval`): the field is private,
  // and this constructor's minInterval parameter needs to stay a public
  // name so tests in other files can override it.
  ThrottledLlmClient(
    this._inner,
    this._counter, {
    Duration minInterval = const Duration(seconds: 1),
    // ignore: prefer_initializing_formals
  }) : _minInterval = minInterval;

  Future<T> _throttled<T>(
    Future<T> Function() action, {
    required bool countsTowardQuota,
  }) {
    final previous = _queue;
    final gate = Completer<void>();
    _queue = gate.future;

    return previous.then((_) async {
      try {
        final result = await action();
        if (countsTowardQuota) {
          await _counter.increment();
        }
        return result;
      } finally {
        unawaited(Future.delayed(_minInterval).then((_) => gate.complete()));
      }
    });
  }

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userMessage,
    AiRequest? request,
  }) {
    return _throttled(
      () => _inner.complete(
        systemPrompt: systemPrompt,
        userMessage: userMessage,
        request: request,
      ),
      countsTowardQuota: true,
    );
  }

  @override
  Future<String> completeWithImage({
    required String systemPrompt,
    required String userMessage,
    required Uint8List imageBytes,
    required String mimeType,
    AiRequest? request,
  }) {
    return _throttled(
      () => _inner.completeWithImage(
        systemPrompt: systemPrompt,
        userMessage: userMessage,
        imageBytes: imageBytes,
        mimeType: mimeType,
        request: request,
      ),
      countsTowardQuota: true,
    );
  }

  @override
  Future<bool> validateApiKey(String apiKey) {
    // Throttled like everything else so a user mashing "Проверить ключ"
    // can't fire a burst of calls, but not counted — it's a cheap models
    // list call, not a generation request.
    return _throttled(
      () => _inner.validateApiKey(apiKey),
      countsTowardQuota: false,
    );
  }
}
