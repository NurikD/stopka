import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../auth/device_auth.dart';
import '../generated/protocol.dart';
import '../logic/server_settings.dart';
import 'ai_limits.dart';
import 'ai_prompts.dart';
import 'ai_provider.dart';

/// Swappable pieces of the proxy: tests put a fake provider here, production
/// builds Gemini from the password file on first use.
class AiRuntime {
  static LlmProvider? _provider;
  static AiPrompts prompts = AiPrompts();

  /// Replaces the provider (tests). Null goes back to Gemini.
  static void overrideProvider(LlmProvider? provider) => _provider = provider;

  static LlmProvider providerFor(Session session, AiSettings settings) {
    final existing = _provider;
    if (existing != null) return existing;
    final key = session.passwords['geminiApiKey'];
    if (key == null || key.isEmpty) {
      throw AiUnavailable(reason: 'disabled');
    }
    return _provider = GeminiProvider(apiKey: key, model: settings.model);
  }
}

/// The one path every AI request takes: identify the device, check the switch,
/// the global budget and the device's own limit, spend one unit, call the
/// provider, and turn provider trouble into typed errors. Nothing of the
/// request or the answer is logged, only the kind and the outcome.
class AiService {
  static Future<String> run(
    Session session,
    String kind,
    PromptPair prompt, {
    Uint8List? image,
    String? mimeType,
    DateTime? now,
  }) async {
    final settings = ServerSettings.load().ai;
    final clock = now ?? DateTime.now();
    final deviceId = callingDeviceId(session);
    if (deviceId == null) throw AiUnavailable(reason: 'error');
    final device = UuidValue.fromString(deviceId);
    final day = dayKey(clock);

    final today = await AiUsage.db.find(session, where: (t) => t.day.equals(day));
    final usedAll = today.fold<int>(0, (sum, r) => sum + r.requests);
    final mine = today.where((r) => r.deviceId == device && r.kind == kind).firstOrNull;

    final verdict = decideRequest(
      enabled: settings.enabled,
      usedByDeviceForKind: mine?.requests ?? 0,
      deviceLimitForKind: settings.limitFor(kind),
      usedByAllToday: usedAll,
      globalDailyRequests: settings.globalDailyRequests,
    );
    final reset = nextResetUtc(clock);
    switch (verdict) {
      case LimitVerdict.disabled:
        throw AiUnavailable(reason: 'disabled');
      case LimitVerdict.budgetExhausted:
        session.log('AI budget exhausted for $day', level: LogLevel.warning);
        throw AiUnavailable(reason: 'budget', retryAfterMinutes: reset.difference(clock).inMinutes);
      case LimitVerdict.deviceLimit:
        throw LimitExceeded(kind: kind, limit: settings.limitFor(kind), resetAt: reset);
      case LimitVerdict.allowed:
        break;
    }

    final usageRow = await _spend(session, mine, device, day, kind);
    final provider = AiRuntime.providerFor(session, settings);
    final started = DateTime.now();
    try {
      final text = image == null
          ? await provider.complete(systemPrompt: prompt.system, userMessage: prompt.user)
          : await provider.completeWithImage(
              systemPrompt: prompt.system,
              userMessage: prompt.user,
              imageBytes: image,
              mimeType: mimeType ?? 'image/jpeg',
            );
      session.log(
        'ai $kind ok in ${DateTime.now().difference(started).inMilliseconds} ms',
        level: LogLevel.info,
      );
      return text;
    } on LlmProviderException catch (e) {
      // A failed call is not the learner's request to pay for.
      await _refund(session, usageRow);
      session.log('ai $kind failed: ${e.failure} ${e.statusCode ?? ''}', level: LogLevel.error);
      switch (e.failure) {
        case ProviderFailure.overloaded:
          throw AiUnavailable(reason: 'overloaded', retryAfterMinutes: 1);
        case ProviderFailure.rateLimited:
          throw AiUnavailable(reason: 'provider_limit', retryAfterMinutes: 1);
        case ProviderFailure.rejected:
        case ProviderFailure.other:
          throw AiUnavailable(reason: 'error');
      }
    }
  }

  static Future<AiUsage> _spend(Session session, AiUsage? existing, UuidValue device, String day, String kind) {
    if (existing == null) {
      return AiUsage.db.insertRow(session, AiUsage(deviceId: device, day: day, kind: kind, requests: 1));
    }
    return AiUsage.db.updateRow(session, existing.copyWith(requests: existing.requests + 1));
  }

  static Future<void> _refund(Session session, AiUsage row) async {
    final fresh = await AiUsage.db.findById(session, row.id!);
    if (fresh != null && fresh.requests > 0) {
      await AiUsage.db.updateRow(session, fresh.copyWith(requests: fresh.requests - 1));
    }
  }
}
