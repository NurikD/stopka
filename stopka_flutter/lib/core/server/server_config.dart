/// Address of the Stopka server, given at build time:
/// `flutter run --dart-define=STOPKA_SERVER=http://192.168.1.10:8080/`.
/// Empty means the app runs on its own, without any server features — which
/// is also what happens before a server exists.
const String serverUrl = String.fromEnvironment('STOPKA_SERVER');

bool get serverConfigured => serverUrl.isNotEmpty;
