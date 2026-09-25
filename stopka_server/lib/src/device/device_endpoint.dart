import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../logic/app_version.dart';
import '../logic/device_token.dart';
import '../logic/registration_guard.dart';
import '../logic/server_settings.dart';

class DeviceEndpoint extends Endpoint {
  /// Registers this installation and returns its secret token. Called once, at
  /// the first launch; the app keeps the token in secure storage. No account,
  /// no personal data.
  Future<DeviceRegistration> register(Session session, String appVersion) async {
    final settings = ServerSettings.load();

    if (!isAppVersionSupported(appVersion, settings.minAppVersion)) {
      throw AppUpdateRequired(minVersion: settings.minAppVersion);
    }

    final ip = _clientIp(session, trustForwardedFor: settings.trustForwardedFor);
    final salt = session.passwords['serviceSecret'] ?? '';
    final ipHash = ip == null ? null : hashIp(ip, salt);

    if (ipHash != null) {
      final since = DateTime.now().toUtc().subtract(const Duration(days: 1));
      final recent = await Device.db.count(
        session,
        where: (t) => t.ipHash.equals(ipHash) & (t.createdAt > since),
      );
      if (!registrationAllowed(recentRegistrations: recent, maxPerDay: settings.maxRegistrationsPerIpPerDay)) {
        throw RegistrationLimited(retryAfterHours: 24);
      }
    }

    final token = generateDeviceToken();
    final now = DateTime.now().toUtc();
    final device = await Device.db.insertRow(
      session,
      Device(
        tokenHash: hashToken(token),
        appVersion: appVersion,
        ipHash: ipHash,
        createdAt: now,
        lastSeenAt: now,
      ),
    );
    return DeviceRegistration(token: token, deviceId: device.id!);
  }

  String? _clientIp(Session session, {required bool trustForwardedFor}) {
    if (session is! MethodCallSession) return null;
    final request = session.request;
    if (trustForwardedFor) {
      final forwarded = request.headers['x-forwarded-for']?.join(',');
      final first = forwarded?.split(',').first.trim();
      if (first != null && first.isNotEmpty) return first;
    }
    return request.connectionInfo.remote.address.toString();
  }
}
