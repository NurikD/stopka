/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// An anonymous installation of the app. There is no user account: the app
/// registers once and keeps the returned token in secure storage.
abstract class Device
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Device._({
    this.id,
    required this.tokenHash,
    required this.appVersion,
    this.ipHash,
    required this.createdAt,
    required this.lastSeenAt,
    bool? blocked,
  }) : blocked = blocked ?? false;

  factory Device({
    _isc.UuidValue? id,
    required String tokenHash,
    required String appVersion,
    String? ipHash,
    required DateTime createdAt,
    required DateTime lastSeenAt,
    bool? blocked,
  }) = _DeviceImpl;

  factory Device.fromJson(Map<String, dynamic> jsonSerialization) {
    return Device(
      id: jsonSerialization['id'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tokenHash: jsonSerialization['tokenHash'] as String,
      appVersion: jsonSerialization['appVersion'] as String,
      ipHash: jsonSerialization['ipHash'] as String?,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastSeenAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSeenAt'],
      ),
      blocked: jsonSerialization['blocked'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['blocked']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _isc.UuidValue? id;

  /// SHA-256 of the device token. The token itself is never stored.
  String tokenHash;

  String appVersion;

  /// SHA-256 of the client IP and a server secret, only used to cap how many
  /// devices one address can register per day.
  String? ipHash;

  DateTime createdAt;

  DateTime lastSeenAt;

  bool blocked;

  /// Returns a shallow copy of this [Device]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Device copyWith({
    _isc.UuidValue? id,
    String? tokenHash,
    String? appVersion,
    String? ipHash,
    DateTime? createdAt,
    DateTime? lastSeenAt,
    bool? blocked,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Device',
      if (id != null) 'id': id?.toJson(),
      'tokenHash': tokenHash,
      'appVersion': appVersion,
      if (ipHash != null) 'ipHash': ipHash,
      'createdAt': createdAt.toJson(),
      'lastSeenAt': lastSeenAt.toJson(),
      'blocked': blocked,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Device',
      if (id != null) 'id': id?.toJson(),
      'tokenHash': tokenHash,
      'appVersion': appVersion,
      if (ipHash != null) 'ipHash': ipHash,
      'createdAt': createdAt.toJson(),
      'lastSeenAt': lastSeenAt.toJson(),
      'blocked': blocked,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeviceImpl extends Device {
  _DeviceImpl({
    _isc.UuidValue? id,
    required String tokenHash,
    required String appVersion,
    String? ipHash,
    required DateTime createdAt,
    required DateTime lastSeenAt,
    bool? blocked,
  }) : super._(
         id: id,
         tokenHash: tokenHash,
         appVersion: appVersion,
         ipHash: ipHash,
         createdAt: createdAt,
         lastSeenAt: lastSeenAt,
         blocked: blocked,
       );

  /// Returns a shallow copy of this [Device]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Device copyWith({
    Object? id = _Undefined,
    String? tokenHash,
    String? appVersion,
    Object? ipHash = _Undefined,
    DateTime? createdAt,
    DateTime? lastSeenAt,
    bool? blocked,
  }) {
    return Device(
      id: id is _isc.UuidValue? ? id : this.id,
      tokenHash: tokenHash ?? this.tokenHash,
      appVersion: appVersion ?? this.appVersion,
      ipHash: ipHash is String? ? ipHash : this.ipHash,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      blocked: blocked ?? this.blocked,
    );
  }
}
