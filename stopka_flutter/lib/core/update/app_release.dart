import '../server/app_version_check.dart';

/// A published release that can replace the running app.
class AppRelease {
  final String version;
  final String notes;
  final String apkName;
  final String apkUrl;
  final int apkSize;

  const AppRelease({
    required this.version,
    required this.notes,
    required this.apkName,
    required this.apkUrl,
    required this.apkSize,
  });
}

/// Words an APK's file name uses for each Android ABI, so both our
/// `stopka-0.2.0-arm64.apk` and Flutter's `app-arm64-v8a-release.apk` match.
const Map<String, List<String>> _abiNames = {
  'arm64-v8a': ['arm64'],
  'armeabi-v7a': ['armv7', 'armeabi'],
  'x86_64': ['x86_64'],
};

/// The newest published release (pre-releases count, drafts do not) that is
/// newer than [currentVersion] and has an APK for one of [abis] (the device's,
/// preferred first); an APK named for no ABI at all is a universal one and
/// fits any device. [releases] is the GitHub `/releases` JSON.
AppRelease? pickUpdate(List<dynamic> releases, {required String currentVersion, required List<String> abis}) {
  AppRelease? best;
  for (final r in releases) {
    if (r is! Map || r['draft'] == true) continue;
    final version = '${r['tag_name'] ?? ''}'.replaceFirst(RegExp('^v'), '');
    if (!_newer(version, than: currentVersion)) continue;
    if (best != null && !_newer(version, than: best.version)) continue;

    final apks = [
      for (final a in (r['assets'] as List? ?? const []))
        if (a is Map && '${a['name']}'.toLowerCase().endsWith('.apk')) a,
    ];
    final asset = _assetFor(apks, abis);
    if (asset == null) continue;
    best = AppRelease(
      version: version,
      notes: '${r['body'] ?? ''}',
      apkName: '${asset['name']}',
      apkUrl: '${asset['browser_download_url']}',
      apkSize: asset['size'] is int ? asset['size'] as int : 0,
    );
  }
  return best;
}

bool _newer(String version, {required String than}) =>
    RegExp(r'^\d+\.\d+\.\d+').hasMatch(version) && !isVersionSupported(than, version);

Map? _assetFor(List<Map> apks, List<String> abis) {
  bool named(Map a, List<String> words) => words.any('${a['name']}'.toLowerCase().contains);
  for (final abi in abis) {
    final words = _abiNames[abi];
    if (words == null) continue;
    final match = apks.where((a) => named(a, words)).firstOrNull;
    if (match != null) return match;
  }
  final allWords = _abiNames.values.expand((w) => w).toList();
  return apks.where((a) => !named(a, allWords)).firstOrNull;
}

/// Release notes are Markdown on GitHub; on the phone they are plain text.
String plainNotes(String markdown) {
  return markdown
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((l) => l.replaceFirst(RegExp(r'^#+\s*'), '').replaceAll('**', '').replaceAll('`', ''))
      .map((l) => l.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1]!))
      .join('\n')
      .trim();
}
