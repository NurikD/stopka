import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../logic/device_token.dart';

/// How stale `lastSeenAt` may get before a call refreshes it, so that a busy
/// device does not cause a database write on every request.
const Duration lastSeenRefresh = Duration(hours: 1);

/// Authenticates a call by its device token: the token is hashed, matched to a
/// registered, non-blocked device, and that device becomes the caller. There
/// is no user account behind it.
Future<AuthenticationInfo?> deviceAuthenticationHandler(Session session, String token) async {
  if (token.isEmpty) return null;
  final device = await Device.db.findFirstRow(
    session,
    where: (t) => t.tokenHash.equals(hashToken(token)) & t.blocked.equals(false),
  );
  if (device == null || device.id == null) return null;

  final now = DateTime.now().toUtc();
  if (now.difference(device.lastSeenAt) > lastSeenRefresh) {
    await Device.db.updateRow(session, device.copyWith(lastSeenAt: now));
  }
  final id = device.id!.toString();
  return AuthenticationInfo(id, const {}, authId: id);
}

/// The id of the calling device, or null for an anonymous call.
String? callingDeviceId(Session session) => session.authenticated?.userIdentifier;
