import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// A new secret device token: 32 random bytes, URL-safe base64.
String generateDeviceToken([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// What is stored instead of the token.
String hashToken(String token) => sha256.convert(utf8.encode(token)).toString();

/// The address is stored only as a salted hash: enough to count registrations
/// per address, useless as a record of who connected from where.
String hashIp(String ip, String salt) => sha256.convert(utf8.encode('$salt|$ip')).toString();
