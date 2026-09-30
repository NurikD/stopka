import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'app_release.dart';

/// Where releases are published. Every GitHub release with an APK attached is
/// an update for the app.
const String updatesRepo = 'NurikD/stopka';

/// The Android side of updating (MainActivity, channel `stopka/update`).
class UpdatePlatform {
  static const _channel = MethodChannel('stopka/update');

  Future<List<String>> supportedAbis() async =>
      (await _channel.invokeListMethod<String>('supportedAbis')) ?? const [];

  Future<bool> canInstall() async => await _channel.invokeMethod<bool>('canInstall') ?? false;

  Future<void> openInstallSettings() => _channel.invokeMethod('openInstallSettings');

  Future<void> install(String path) => _channel.invokeMethod('install', {'path': path});
}

enum InstallStart {
  /// The system installer is showing its confirmation.
  started,

  /// Android first needs "allow installs from Стопка"; its settings are open.
  needsPermission,
}

/// Finds a newer release on GitHub, downloads its APK for this device and
/// hands it to the system installer. Android only; elsewhere there is never
/// an update.
class UpdateService {
  final Dio _dio;
  final UpdatePlatform _platform;
  final Future<Directory> Function() _cacheDir;

  UpdateService({Dio? dio, UpdatePlatform? platform, Future<Directory> Function()? cacheDir})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 10))),
        _platform = platform ?? UpdatePlatform(),
        _cacheDir = cacheDir ?? getApplicationCacheDirectory;

  /// Updates are APKs, so only Android has them.
  bool get supported => Platform.isAndroid;

  /// The release to offer, or null when the app is up to date. Any network
  /// trouble also means null: an update check never gets in the way.
  Future<AppRelease?> check(String currentVersion) async {
    if (!supported) return null;
    try {
      final response = await _dio.get<List<dynamic>>(
        'https://api.github.com/repos/$updatesRepo/releases',
        queryParameters: {'per_page': 10},
        options: Options(headers: {'Accept': 'application/vnd.github+json'}),
      );
      final abis = await _platform.supportedAbis();
      return pickUpdate(response.data ?? const [], currentVersion: currentVersion, abis: abis);
    } on Exception {
      return null;
    }
  }

  Future<Directory> _updatesDir() async => Directory('${(await _cacheDir()).path}/updates');

  /// Downloads the APK into the app cache, replacing older downloads.
  /// [onProgress] gets 0..1. Returns the file path.
  Future<String> download(AppRelease release, void Function(double progress) onProgress) async {
    final dir = await _updatesDir();
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    final path = '${dir.path}/stopka-${release.version}.apk';
    await _dio.download(
      release.apkUrl,
      path,
      onReceiveProgress: (received, total) {
        final size = total > 0 ? total : release.apkSize;
        if (size > 0) onProgress((received / size).clamp(0, 1).toDouble());
      },
    );
    return path;
  }

  Future<InstallStart> install(String path) async {
    if (!await _platform.canInstall()) {
      await _platform.openInstallSettings();
      return InstallStart.needsPermission;
    }
    await _platform.install(path);
    return InstallStart.started;
  }

  /// Drops a downloaded APK once it is no longer needed (the app runs the new
  /// version, or the download was for a version we already have).
  Future<void> clearDownloads() async {
    try {
      final dir = await _updatesDir();
      if (await dir.exists()) await dir.delete(recursive: true);
    } on Exception {
      // Only cache; the OS clears it eventually anyway.
    }
  }
}
