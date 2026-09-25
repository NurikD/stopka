import 'package:serverpod/serverpod.dart';

import '../logic/server_settings.dart';

class CatalogEndpoint extends Endpoint {
  /// The oldest app version this server supports. The app checks it at start
  /// and shows an "update the app" screen when it is older.
  Future<String> getMinAppVersion(Session session) async {
    return ServerSettings.load().minAppVersion;
  }
}
