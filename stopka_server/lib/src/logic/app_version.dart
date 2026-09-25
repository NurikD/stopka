/// A version like `1.2.3` or `1.2.3+4` (the build number after `+`).
class AppVersion implements Comparable<AppVersion> {
  final int major;
  final int minor;
  final int patch;
  final int build;

  const AppVersion(this.major, this.minor, this.patch, [this.build = 0]);

  /// Returns null for anything that is not `N.N.N` with an optional `+N`.
  static AppVersion? tryParse(String input) {
    final match = RegExp(r'^\s*(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?\s*$').firstMatch(input);
    if (match == null) return null;
    return AppVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4) ?? '0'),
    );
  }

  @override
  int compareTo(AppVersion other) {
    for (final pair in [
      (major, other.major),
      (minor, other.minor),
      (patch, other.patch),
      (build, other.build),
    ]) {
      if (pair.$1 != pair.$2) return pair.$1.compareTo(pair.$2);
    }
    return 0;
  }

  @override
  String toString() => build == 0 ? '$major.$minor.$patch' : '$major.$minor.$patch+$build';
}

/// Whether an app reporting [appVersion] may talk to a server that requires at
/// least [minVersion]. An unreadable app version is treated as too old: a
/// client that cannot say what it is cannot be trusted with the current API.
bool isAppVersionSupported(String appVersion, String minVersion) {
  final app = AppVersion.tryParse(appVersion);
  final min = AppVersion.tryParse(minVersion);
  if (min == null) return true; // no usable requirement configured
  if (app == null) return false;
  return app.compareTo(min) >= 0;
}
