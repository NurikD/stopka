import 'dart:io';

import 'package:yaml/yaml.dart';

/// Kinds of AI requests, the keys of the per-device limits.
const List<String> aiKinds = [
  'checkWriting',
  'appeal',
  'weakSpotDrill',
  'enrichCards',
  'recognizeWords',
  'readUnitPage',
];

/// Limits and switches of the AI proxy. All of it is config, not code.
class AiSettings {
  /// Master switch. Off: every AI call answers "unavailable" without touching
  /// the provider.
  final bool enabled;

  /// Provider model name, from the provider's documentation.
  final String model;

  /// Requests all devices together may make per UTC day. The budget ceiling:
  /// when it is reached the proxy stops, whatever the individual limits say.
  final int globalDailyRequests;

  /// Requests one device may make per UTC day, by kind.
  final Map<String, int> dailyLimits;

  /// Longest text (characters) accepted in one request field.
  final int maxTextChars;

  /// Largest image (bytes) accepted.
  final int maxImageBytes;

  const AiSettings({
    this.enabled = true,
    this.model = 'gemini-3.8-flash',
    this.globalDailyRequests = 500,
    this.dailyLimits = const {
      'checkWriting': 20,
      'appeal': 40,
      'weakSpotDrill': 10,
      'enrichCards': 30,
      'recognizeWords': 10,
      'readUnitPage': 10,
    },
    this.maxTextChars = 4000,
    this.maxImageBytes = 4 * 1024 * 1024,
  });

  int limitFor(String kind) => dailyLimits[kind] ?? 0;
}

/// Non-secret server settings from `config/stopka.yaml`. Secrets stay in
/// passwords.yaml.
class ServerSettings {
  /// Oldest app version the API still supports.
  final String minAppVersion;

  /// Devices one address may register per day.
  final int maxRegistrationsPerIpPerDay;

  /// Read the client address from `X-Forwarded-For`. Only on when the server
  /// really sits behind a reverse proxy that sets it; otherwise it is spoofable.
  final bool trustForwardedFor;

  final AiSettings ai;

  const ServerSettings({
    this.minAppVersion = '1.0.0',
    this.maxRegistrationsPerIpPerDay = 10,
    this.trustForwardedFor = false,
    this.ai = const AiSettings(),
  });

  factory ServerSettings.parse(String yamlText) {
    final doc = loadYaml(yamlText);
    if (doc is! YamlMap) return const ServerSettings();
    const defaults = ServerSettings();
    final registration = doc['registration'];
    return ServerSettings(
      minAppVersion: (doc['minAppVersion'] as Object?)?.toString() ?? defaults.minAppVersion,
      maxRegistrationsPerIpPerDay: registration is YamlMap && registration['maxPerIpPerDay'] is int
          ? registration['maxPerIpPerDay'] as int
          : defaults.maxRegistrationsPerIpPerDay,
      trustForwardedFor: registration is YamlMap && registration['trustForwardedFor'] == true,
      ai: _parseAi(doc['ai']),
    );
  }

  static AiSettings _parseAi(Object? node) {
    const d = AiSettings();
    if (node is! YamlMap) return d;
    final limits = <String, int>{...d.dailyLimits};
    final rawLimits = node['dailyLimits'];
    if (rawLimits is YamlMap) {
      for (final entry in rawLimits.entries) {
        if (entry.key is String && entry.value is int && (entry.value as int) >= 0) {
          limits[entry.key as String] = entry.value as int;
        }
      }
    }
    return AiSettings(
      enabled: node['enabled'] is bool ? node['enabled'] as bool : d.enabled,
      model: (node['model'] as Object?)?.toString() ?? d.model,
      globalDailyRequests: node['globalDailyRequests'] is int ? node['globalDailyRequests'] as int : d.globalDailyRequests,
      dailyLimits: limits,
      maxTextChars: node['maxTextChars'] is int ? node['maxTextChars'] as int : d.maxTextChars,
      maxImageBytes: node['maxImageBytes'] is int ? node['maxImageBytes'] as int : d.maxImageBytes,
    );
  }

  /// Tests set this to run with specific limits; null reads the file.
  static ServerSettings? testOverride;

  /// Loads `config/stopka.yaml`, or the defaults when the file is missing.
  static ServerSettings load([String path = 'config/stopka.yaml']) {
    final override = testOverride;
    if (override != null) return override;
    final file = File(path);
    return file.existsSync() ? ServerSettings.parse(file.readAsStringSync()) : const ServerSettings();
  }
}
