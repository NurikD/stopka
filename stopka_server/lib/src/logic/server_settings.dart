import 'dart:io';

import 'package:yaml/yaml.dart';

/// Non-secret server settings from `config/stopka.yaml`. Limits live here, not
/// in code, so they change with a config edit. Secrets stay in passwords.yaml.
class ServerSettings {
  /// Oldest app version the API still supports.
  final String minAppVersion;

  /// Devices one address may register per day.
  final int maxRegistrationsPerIpPerDay;

  /// Read the client address from `X-Forwarded-For`. Only on when the server
  /// really sits behind a reverse proxy that sets it; otherwise it is spoofable.
  final bool trustForwardedFor;

  const ServerSettings({
    this.minAppVersion = '1.0.0',
    this.maxRegistrationsPerIpPerDay = 10,
    this.trustForwardedFor = false,
  });

  factory ServerSettings.parse(String yamlText) {
    final doc = loadYaml(yamlText);
    if (doc is! YamlMap) return const ServerSettings();
    const defaults = ServerSettings();
    final registration = doc['registration'];
    return ServerSettings(
      minAppVersion: (doc['minAppVersion'] as Object?)?.toString() ?? defaults.minAppVersion,
      maxRegistrationsPerIpPerDay:
          registration is YamlMap && registration['maxPerIpPerDay'] is int
              ? registration['maxPerIpPerDay'] as int
              : defaults.maxRegistrationsPerIpPerDay,
      trustForwardedFor: registration is YamlMap && registration['trustForwardedFor'] == true,
    );
  }

  /// Loads `config/stopka.yaml`, or the defaults when the file is missing.
  static ServerSettings load([String path = 'config/stopka.yaml']) {
    final file = File(path);
    return file.existsSync() ? ServerSettings.parse(file.readAsStringSync()) : const ServerSettings();
  }
}
