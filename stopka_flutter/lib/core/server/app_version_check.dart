/// Compares `major.minor.patch[+build]` versions the way the server does.
/// An unreadable app version counts as too old; an unreadable requirement
/// lets everything through.
bool isVersionSupported(String appVersion, String minVersion) {
  final app = _parse(appVersion);
  final min = _parse(minVersion);
  if (min == null) return true;
  if (app == null) return false;
  for (var i = 0; i < 4; i++) {
    if (app[i] != min[i]) return app[i] > min[i];
  }
  return true;
}

List<int>? _parse(String input) {
  final match = RegExp(r'^\s*(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?\s*$').firstMatch(input);
  if (match == null) return null;
  return [for (var i = 1; i <= 4; i++) int.parse(match.group(i) ?? '0')];
}
