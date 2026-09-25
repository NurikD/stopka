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
import 'package:serverpod/serverpod.dart' as _is;

/// What the app gets back after registering.
abstract class DeviceRegistration
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DeviceRegistration._({
    required this.token,
    required this.deviceId,
  });

  factory DeviceRegistration({
    required String token,
    required _is.UuidValue deviceId,
  }) = _DeviceRegistrationImpl;

  factory DeviceRegistration.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeviceRegistration(
      token: jsonSerialization['token'] as String,
      deviceId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['deviceId'],
      ),
    );
  }

  /// Secret token; shown once, the app stores it.
  String token;

  _is.UuidValue deviceId;

  /// Returns a shallow copy of this [DeviceRegistration]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DeviceRegistration copyWith({
    String? token,
    _is.UuidValue? deviceId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeviceRegistration',
      'token': token,
      'deviceId': deviceId.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DeviceRegistration',
      'token': token,
      'deviceId': deviceId.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _DeviceRegistrationImpl extends DeviceRegistration {
  _DeviceRegistrationImpl({
    required String token,
    required _is.UuidValue deviceId,
  }) : super._(
         token: token,
         deviceId: deviceId,
       );

  /// Returns a shallow copy of this [DeviceRegistration]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DeviceRegistration copyWith({
    String? token,
    _is.UuidValue? deviceId,
  }) {
    return DeviceRegistration(
      token: token ?? this.token,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}
